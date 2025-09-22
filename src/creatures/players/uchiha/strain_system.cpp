#include "strain_system.hpp"
#include "creatures/players/player.hpp"
#include "game/game.hpp"
#include "lib/logging/logger.hpp"
#include "utils/utils_definitions.hpp"

namespace Uchiha {

StrainSystem::StrainSystem(Player* player) : player_() {
    // Não usar shared_from_this() no construtor
}

void StrainSystem::initialize(std::shared_ptr<Player> player) {
    player_ = std::weak_ptr<Player>(player);
    strainValue_ = 0;
    totalAccumulated_ = 0;
    isActive_ = false;
    lastActivationTime_ = 0;
    lastDeactivationTime_ = 0;
    lastRecoveryTime_ = getCurrentTime();
}

std::shared_ptr<Player> StrainSystem::getPlayer() const {
    return player_.lock();
}

bool StrainSystem::activate() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (isActive_) {
        sendStrainMessage("Sistema já está ativo!");
        return false;
    }

    if (!canActivate()) {
        sendStrainMessage("Você não pode ativar o sistema agora!");
        return false;
    }

    isActive_ = true;
    lastActivationTime_ = getCurrentTime();
    
    sendStrainMessage("Sistema ativado! Strain começará a crescer progressivamente.");
    g_logger().info("[StrainSystem] Player {} activated strain system", player->getName());
    
    return true;
}

bool StrainSystem::deactivate() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (!isActive_) {
        sendStrainMessage("Sistema já está desativado!");
        return false;
    }

    if (!canDeactivate()) {
        sendStrainMessage("Você não pode desativar o sistema agora!");
        return false;
    }

    isActive_ = false;
    lastDeactivationTime_ = getCurrentTime();
    
    sendStrainMessage("Sistema desativado! Strain começará a diminuir lentamente.");
    g_logger().info("[StrainSystem] Player {} deactivated strain system", player->getName());
    
    return true;
}

bool StrainSystem::addStrain(uint8_t amount) {
    if (amount == 0) {
        return false;
    }
    
    // Não pode adicionar strain se o sistema não estiver ativo
    if (!isActive_) {
        return false;
    }

    uint8_t oldLevel = getStrainLevelNumber();
    uint16_t newValue = static_cast<uint16_t>(strainValue_) + amount;
    
    // Limitar a 100
    if (newValue > 100) {
        newValue = 100;
    }
    
    strainValue_ = static_cast<uint8_t>(newValue);
    totalAccumulated_ += amount;
    
    uint8_t newLevel = getStrainLevelNumber();
    
    // Verificar se mudou de nível
    if (newLevel != oldLevel) {
        auto player = getPlayer();
        if (player) {
            std::string message = "Strain Level: " + getStrainLevelName() + " (" + std::to_string(strainValue_) + "/100)";
            sendStrainMessage(message);
            g_logger().info("[StrainSystem] Player {} strain level changed to {} (value: {})", 
                          player->getName(), static_cast<int>(newLevel), strainValue_);
        }
    }
    
    updateStrainEffects();
    return true;
}

bool StrainSystem::reduceStrain(uint8_t amount) {
    if (amount == 0 || strainValue_ == 0) {
        return false;
    }

    uint8_t oldLevel = getStrainLevelNumber();
    
    if (amount >= strainValue_) {
        strainValue_ = 0;
    } else {
        strainValue_ -= amount;
    }
    
    uint8_t newLevel = getStrainLevelNumber();
    
    // Verificar se mudou de nível
    if (newLevel != oldLevel) {
        auto player = getPlayer();
        if (player) {
            std::string message = "Strain Level: " + getStrainLevelName() + " (" + std::to_string(strainValue_) + "/100)";
            sendStrainMessage(message);
            g_logger().info("[StrainSystem] Player {} strain level decreased to {} (value: {})", 
                          player->getName(), static_cast<int>(newLevel), strainValue_);
        }
    }
    
    updateStrainEffects();
    return true;
}

bool StrainSystem::removeStrain(uint8_t amount) {
    // Alias para reduceStrain
    return reduceStrain(amount);
}

void StrainSystem::resetStrain() {
    strainValue_ = 0;
    sendStrainMessage("Strain resetado para 0!");
    updateStrainEffects();
}

StrainLevel StrainSystem::getStrainLevel() const {
    if (strainValue_ <= 25) {
        return StrainLevel::BAIXO;
    } else if (strainValue_ <= 50) {
        return StrainLevel::MEDIO;
    } else if (strainValue_ <= 75) {
        return StrainLevel::ALTO;
    } else {
        return StrainLevel::CRITICO;
    }
}

uint8_t StrainSystem::getStrainLevelNumber() const {
    return static_cast<uint8_t>(getStrainLevel());
}

uint8_t StrainSystem::getCurrentLevel() const {
    // Alias para getStrainLevelNumber
    return getStrainLevelNumber();
}

std::string StrainSystem::getStrainLevelName() const {
    switch (getStrainLevel()) {
        case StrainLevel::BAIXO:
            return "Baixo";
        case StrainLevel::MEDIO:
            return "Médio";
        case StrainLevel::ALTO:
            return "Alto";
        case StrainLevel::CRITICO:
            return "Crítico";
        default:
            return "Desconhecido";
    }
}

std::string StrainSystem::getStrainLevelColor() const {
    switch (getStrainLevel()) {
        case StrainLevel::BAIXO:
            return "green";
        case StrainLevel::MEDIO:
            return "yellow";
        case StrainLevel::ALTO:
            return "orange";
        case StrainLevel::CRITICO:
            return "red";
        default:
            return "white";
    }
}

bool StrainSystem::canActivate() const {
    // Por enquanto, sempre pode ativar
    return true;
}

bool StrainSystem::canDeactivate() const {
    // Por enquanto, sempre pode desativar
    return true;
}

uint32_t StrainSystem::getTimeSinceLastActivation() const {
    if (lastActivationTime_ == 0) {
        return 0;
    }
    return getCurrentTime() - lastActivationTime_;
}

uint32_t StrainSystem::getTimeSinceLastDeactivation() const {
    if (lastDeactivationTime_ == 0) {
        return 0;
    }
    return getCurrentTime() - lastDeactivationTime_;
}

void StrainSystem::processStrainGrowth() {
    if (!isActive_) {
        return;
    }
    
    // Crescimento progressivo quando ativo (1 ponto a cada processamento)
    addStrain(1);
}

void StrainSystem::processStrainDecay() {
    if (isActive_ || strainValue_ == 0) {
        return;
    }
    
    // Decaimento lento quando inativo (1 ponto a cada 2 processamentos)
    static uint32_t decayCounter = 0;
    decayCounter++;
    
    if (decayCounter >= 2) {
        reduceStrain(1);
        decayCounter = 0;
    }
}

void StrainSystem::sendStrainMessage(const std::string& message) const {
    auto player = getPlayer();
    if (player) {
        player->sendTextMessage(MESSAGE_STATUS, message);
    }
}

void StrainSystem::updateStrainEffects() {
    // Por enquanto, apenas log dos efeitos
    // Aqui implementaremos os buffs/penalidades no futuro
    auto player = getPlayer();
    if (player) {
        g_logger().debug("[StrainSystem] Player {} strain effects updated (level: {}, value: {})", 
                        player->getName(), static_cast<int>(getStrainLevelNumber()), strainValue_);
    }
}

void StrainSystem::onThink() {
    uint32_t currentTime = getCurrentTime();
    
    if (isActive_) {
        // Sistema ativo: progressão automática baseada no nível do Sharingan
        // Por enquanto, usando uma variável local para simular o nível do Sharingan
        uint8_t sharinganLevel = 1; // TODO: Implementar sistema de Sharingan real
        
        // Progressão baseada no nível (exemplo: nível 1 = +1 strain/10s, nível 2 = +1 strain/8s, etc.)
        uint32_t progressionInterval = 10 - (sharinganLevel - 1) * 2; // 10s, 8s, 6s, 4s...
        if (progressionInterval < 2) progressionInterval = 2; // Mínimo de 2 segundos
        
        if (currentTime - lastActivationTime_ >= progressionInterval) {
            if (strainValue_ < 100) {
                uint8_t oldLevel = getStrainLevelNumber();
                strainValue_++;
                totalAccumulated_++;
                
                uint8_t newLevel = getStrainLevelNumber();
                if (newLevel != oldLevel) {
                    auto player = getPlayer();
                    if (player) {
                        std::string message = "Strain Level: " + getStrainLevelName() + " (" + std::to_string(strainValue_) + "/100)";
                        sendStrainMessage(message);
                        g_logger().info("[StrainSystem] Player {} strain level changed to {} (value: {})", 
                                      player->getName(), static_cast<int>(newLevel), strainValue_);
                    }
                }
                
                updateStrainEffects();
                lastActivationTime_ = currentTime;
            }
        }
    } else {
        // Sistema desativado: recuperação lenta (-1 strain/5 segundos)
        if (strainValue_ > 0 && currentTime - lastRecoveryTime_ >= 5) {
            strainValue_--;
            lastRecoveryTime_ = currentTime;
            
            auto player = getPlayer();
            if (player) {
                g_logger().debug("[StrainSystem] Player {} strain recovered: {} (-1)", 
                               player->getName(), strainValue_);
            }
            
            updateStrainEffects();
        }
    }
}

uint32_t StrainSystem::getCurrentTime() const {
    return static_cast<uint32_t>(OTSYS_TIME() / 1000);
}

} // namespace Uchiha