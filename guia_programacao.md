# Guia de Programação - Sistemas Canary

## Baseado na Implementação do Sistema Sharingan

Este guia documenta as melhores práticas de programação utilizadas na implementação do sistema Sharingan, servindo como referência para o desenvolvimento de sistemas futuros no servidor Canary.

---

## 1. Arquitetura de Sistema

### 1.1 Estrutura de Arquivos

```
src/creatures/players/uchiha/
├── sharingan_system.hpp    # Declarações da classe
└── sharingan_system.cpp    # Implementações

src/lua/functions/creatures/player/
└── player_functions.cpp    # Exportação para Lua

data-canary/scripts/
└── sharingan/             # Scripts Lua do sistema
```

### 1.2 Namespace Organization

```cpp
namespace Uchiha {
    enum class SharinganLevel : uint8_t {
        LOCKED = 0,
        TOMOE_1 = 1,
        TOMOE_2 = 2,
        TOMOE_3 = 3
    };

    class SharinganSystem {
        // Implementação
    };
}
```

**Princípios:**
- Use namespaces para organizar sistemas relacionados
- Enums fortemente tipados (`enum class`) para maior segurança
- Tipos específicos (`uint8_t`) para otimização de memória

---

## 2. Gerenciamento de Ponteiros

### 2.1 Smart Pointers

```cpp
class SharinganSystem {
private:
    std::weak_ptr<Player> player_;  // Evita referência circular
    
public:
    void initialize(std::shared_ptr<Player> player);
    std::shared_ptr<Player> getPlayer() const;
};
```

**Regras:**
- **`std::weak_ptr`**: Para referências que não devem manter o objeto vivo
- **`std::shared_ptr`**: Para propriedade compartilhada
- **`std::unique_ptr`**: Para propriedade exclusiva

### 2.2 Validação de Ponteiros

```cpp
std::shared_ptr<Player> SharinganSystem::getPlayer() const {
    auto player = player_.lock();
    if (!player) {
        g_logger().warn("[SharinganSystem::getPlayer] - Player pointer is null");
        return nullptr;
    }
    return player;
}
```

**Sempre validar:**
1. Ponteiros antes de usar
2. Retorno de `weak_ptr.lock()`
3. Parâmetros de entrada em funções públicas

---

## 3. Tratamento de Erros e Validações

### 3.1 Validações Robustas

```cpp
bool SharinganSystem::increaseLevel() {
    auto player = getPlayer();
    if (!player) {
        g_logger().warn("[SharinganSystem::increaseLevel] - Player is null");
        return false;
    }

    if (!isUnlocked()) {
        g_logger().debug("[SharinganSystem::increaseLevel] - Sharingan not unlocked for player: {}", 
                        player->getName());
        return false;
    }

    if (!canEvolve()) {
        if (getRequiredExperienceForLevel(static_cast<uint8_t>(level_) + 1) > experience_) {
            player->sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                                  "You need more experience to evolve your Sharingan.");
        }
        return false;
    }

    // Lógica principal...
    return true;
}
```

### 3.2 Logging Estratégico

```cpp
// Diferentes níveis de log
g_logger().error("Erro crítico que afeta funcionalidade");
g_logger().warn("Situação anômala que deve ser investigada");
g_logger().info("Informação importante para auditoria");
g_logger().debug("Informação detalhada para desenvolvimento");
```

**Quando usar cada nível:**
- **Error**: Falhas que impedem funcionamento
- **Warn**: Situações inesperadas mas recuperáveis
- **Info**: Eventos importantes do sistema
- **Debug**: Informações detalhadas para desenvolvimento

---

## 4. Otimizações de Performance

### 4.1 Especificadores `noexcept`

```cpp
// Métodos que nunca lançam exceções
void setLevel(uint8_t level) noexcept;
uint32_t getCurrentTime() const noexcept;
bool validateLevel() const noexcept;
void incrementUsage() noexcept;
```

**Benefícios:**
- Otimizações do compilador
- Melhor performance em containers STL
- Documentação clara de comportamento

### 4.2 Prevenção de Overflow

```cpp
void SharinganSystem::incrementUsage() noexcept {
    if (usageCount_ < UINT32_MAX) {
        usageCount_++;
    }
}

bool SharinganSystem::addExperience(uint32_t amount) {
    // Verificação de overflow
    if (experience_ > UINT32_MAX - amount) {
        g_logger().warn("[SharinganSystem::addExperience] - Experience overflow prevented");
        experience_ = UINT32_MAX;
    } else {
        experience_ += amount;
    }
    
    return checkForEvolution();
}
```

### 4.3 Const Correctness

```cpp
class SharinganSystem {
public:
    // Métodos que não modificam estado
    bool isUnlocked() const { return level_ != SharinganLevel::LOCKED; }
    bool isActive() const { return isActive_; }
    std::string getLevelName() const;
    bool canEvolve() const;
    
    // Métodos que modificam estado (sem const)
    bool unlock();
    bool activate();
    void addExperience(uint32_t amount);
};
```

---

## 5. Exportação para Lua

### 5.1 Funções Lua Wrapper

```cpp
static int luaPlayerUnlockSharingan(lua_State* L) {
    // lua_pushuserdata(L, player)
    const auto &player = getUserdataShared<Player>(L, 1);
    if (!player) {
        lua_pushnil(L);
        return 1;
    }

    auto sharinganSystem = player->getSharinganSystem();
    if (!sharinganSystem) {
        lua_pushnil(L);
        return 1;
    }

    lua_pushboolean(L, sharinganSystem->unlock());
    return 1;
}
```

### 5.2 Registro de Funções

```cpp
void PlayerFunctions::init(lua_State* L) {
    // Registro das funções Sharingan
    registerMethod(L, "Player", "unlockSharingan", luaPlayerUnlockSharingan);
    registerMethod(L, "Player", "getSharinganLevel", luaPlayerGetSharinganLevel);
    registerMethod(L, "Player", "increaseSharinganLevel", luaPlayerIncreaseSharinganLevel);
    registerMethod(L, "Player", "isSharinganUnlocked", luaPlayerIsSharinganUnlocked);
    registerMethod(L, "Player", "activateSharingan", luaPlayerActivateSharingan);
    registerMethod(L, "Player", "deactivateSharingan", luaPlayerDeactivateSharingan);
    registerMethod(L, "Player", "isSharinganActive", luaPlayerIsSharinganActive);
}
```

### 5.3 Tratamento de Retornos

```cpp
static int luaPlayerGetSharinganLevel(lua_State* L) {
    const auto &player = getUserdataShared<Player>(L, 1);
    if (!player) {
        lua_pushnumber(L, 0);  // Retorno consistente
        return 1;
    }

    auto sharinganSystem = player->getSharinganSystem();
    if (!sharinganSystem) {
        lua_pushnumber(L, 0);  // Retorno consistente
        return 1;
    }

    lua_pushnumber(L, sharinganSystem->getLevelNumber());
    return 1;
}
```

**Princípios:**
- Sempre retornar valores consistentes
- Nunca retornar `nil` quando um número é esperado
- Validar todos os parâmetros de entrada

---

## 6. Padrões de Design

### 6.1 RAII (Resource Acquisition Is Initialization)

```cpp
class SharinganSystem {
private:
    std::weak_ptr<Player> player_;
    SharinganLevel level_ = SharinganLevel::LOCKED;
    uint32_t experience_ = 0;
    uint32_t usageCount_ = 0;
    bool isActive_ = false;
    uint32_t lastActivationTime_ = 0;

public:
    SharinganSystem() = default;  // Inicialização automática
    explicit SharinganSystem(Player* player);
    
    // Destructor automático gerencia recursos
    ~SharinganSystem() = default;
};
```

### 6.2 Single Responsibility Principle

```cpp
class SharinganSystem {
public:
    // Responsabilidade: Gerenciamento de estado
    bool unlock();
    bool activate();
    bool deactivate();
    
    // Responsabilidade: Progressão
    bool addExperience(uint32_t amount);
    bool increaseLevel();
    bool canEvolve() const;
    
    // Responsabilidade: Informações
    std::string getLevelName() const;
    std::string getSharinganInfo() const;
    
    // Responsabilidade: Utilidades
    bool canActivate() const;
    uint32_t getTimeSinceLastActivation() const noexcept;
};
```

### 6.3 Dependency Injection

```cpp
// No player.hpp
class Player {
private:
    std::unique_ptr<Uchiha::SharinganSystem> sharinganSystem_;
    
public:
    Uchiha::SharinganSystem* getSharinganSystem() const {
        return sharinganSystem_.get();
    }
    
    void initializeSharinganSystem() {
        if (!sharinganSystem_) {
            sharinganSystem_ = std::make_unique<Uchiha::SharinganSystem>();
            sharinganSystem_->initialize(shared_from_this());
        }
    }
};
```

---

## 7. Testes e Validação

### 7.1 Validação de Compilação

```bash
# Sempre compilar após mudanças
cmake --build build --config RelWithDebInfo

# Verificar warnings
cmake --build build --config RelWithDebInfo 2>&1 | grep -i warning
```

### 7.2 Testes de Funcionalidade

```lua
-- Script de teste Lua
local function testSharinganSystem()
    local player = Player("TestPlayer")
    
    -- Teste 1: Estado inicial
    assert(player:getSharinganLevel() == 0, "Initial level should be 0")
    assert(not player:isSharinganUnlocked(), "Should not be unlocked initially")
    
    -- Teste 2: Desbloqueio
    assert(player:unlockSharingan(), "Should unlock successfully")
    assert(player:isSharinganUnlocked(), "Should be unlocked after unlock")
    
    -- Teste 3: Ativação
    assert(player:activateSharingan(), "Should activate successfully")
    assert(player:isSharinganActive(), "Should be active after activation")
end
```

---

## 8. Documentação de Código

### 8.1 Comentários Explicativos

```cpp
/**
 * @brief Adiciona experiência ao Sharingan e verifica evolução automática
 * @param amount Quantidade de experiência a ser adicionada
 * @return true se a experiência foi adicionada com sucesso, false caso contrário
 * 
 * Este método:
 * 1. Valida se o Sharingan está desbloqueado
 * 2. Previne overflow de experiência
 * 3. Verifica automaticamente se pode evoluir
 * 4. Registra logs apropriados para auditoria
 */
bool SharinganSystem::addExperience(uint32_t amount) {
    // Implementação...
}
```

### 8.2 Documentação de Enums

```cpp
namespace Uchiha {
    /**
     * @brief Níveis do Sharingan baseados no anime Naruto
     * 
     * LOCKED: Sharingan não foi desbloqueado ainda
     * TOMOE_1: Primeiro nível - 1 tomoe, habilidades básicas
     * TOMOE_2: Segundo nível - 2 tomoe, habilidades intermediárias  
     * TOMOE_3: Terceiro nível - 3 tomoe, Sharingan completo
     */
    enum class SharinganLevel : uint8_t {
        LOCKED = 0,
        TOMOE_1 = 1,
        TOMOE_2 = 2,
        TOMOE_3 = 3
    };
}
```

---

## 9. Checklist de Implementação

### 9.1 Antes de Implementar

- [ ] Definir namespace apropriado
- [ ] Planejar estrutura de arquivos
- [ ] Identificar dependências
- [ ] Definir interface pública

### 9.2 Durante Implementação

- [ ] Usar smart pointers adequados
- [ ] Implementar validações robustas
- [ ] Adicionar logging estratégico
- [ ] Aplicar const correctness
- [ ] Usar noexcept quando apropriado
- [ ] Prevenir overflows
- [ ] Documentar código complexo

### 9.3 Exportação Lua

- [ ] Criar funções wrapper
- [ ] Validar parâmetros de entrada
- [ ] Retornar valores consistentes
- [ ] Registrar funções no sistema
- [ ] Testar integração Lua-C++

### 9.4 Finalização

- [ ] Compilar sem warnings
- [ ] Testar funcionalidades básicas
- [ ] Verificar logs de erro
- [ ] Documentar API pública
- [ ] Criar exemplos de uso

---

## 10. Exemplos de Uso

### 10.1 Uso em C++

```cpp
// Em algum evento do jogo
void onPlayerKillMonster(std::shared_ptr<Player> player, std::shared_ptr<Monster> monster) {
    if (!player) return;
    
    auto sharinganSystem = player->getSharinganSystem();
    if (sharinganSystem && sharinganSystem->isUnlocked()) {
        uint32_t expGain = monster->getExperienceReward() / 10;
        sharinganSystem->addExperience(expGain);
        sharinganSystem->incrementUsage();
    }
}
```

### 10.2 Uso em Lua

```lua
local creatureEvent = CreatureEvent("SharinganOnKill")

function creatureEvent.onKill(player, target)
    if not player:isSharinganUnlocked() then
        return true
    end
    
    if target:isMonster() then
        local expGain = target:getExperience() / 10
        player:addSharinganExperience(expGain)
        
        if player:getSharinganLevel() < 3 and math.random(100) <= 5 then
            player:increaseSharinganLevel()
        end
    end
    
    return true
end

creatureEvent:register()
```

---

## 11. Troubleshooting Comum

### 11.1 Erros de Compilação

**Problema**: `error C2382: redefinição; especificações de exceção diferentes`
**Solução**: Verificar consistência de `noexcept` entre header e implementação

**Problema**: `undefined reference to function`
**Solução**: Verificar se função está registrada no CMakeLists.txt

### 11.2 Problemas de Runtime

**Problema**: Crash ao acessar player
**Solução**: Sempre validar ponteiros com `getPlayer()` antes de usar

**Problema**: Funções Lua retornando nil
**Solução**: Verificar validações e retornar valores padrão consistentes

---

## 12. Conclusão

Este guia estabelece as melhores práticas para desenvolvimento de sistemas no servidor Canary, baseado na implementação bem-sucedida do sistema Sharingan. Seguindo estes padrões, você garantirá:

- **Código robusto e confiável**
- **Performance otimizada**
- **Facilidade de manutenção**
- **Integração perfeita com Lua**
- **Debugging eficiente**

Sempre consulte este guia ao implementar novos sistemas e mantenha-o atualizado com novas descobertas e melhorias.

---

**Autor**: Sistema baseado na implementação do Sharingan System  
**Data**: 2024  
**Versão**: 1.0