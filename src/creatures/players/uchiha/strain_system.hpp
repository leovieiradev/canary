#pragma once

#include "creatures/players/player.hpp"
#include <memory>

class Player;

namespace Uchiha {
    enum class StrainLevel : uint8_t {
        BAIXO = 1,    // 0-25
        MEDIO = 2,    // 26-50
        ALTO = 3,     // 51-75
        CRITICO = 4   // 76-100
    };

    class StrainSystem {
    private:
        std::weak_ptr<Player> player_;
        uint8_t strainValue_ = 0;
        uint32_t totalAccumulated_ = 0;
        bool isActive_ = false;
        uint32_t lastActivationTime_ = 0;
        uint32_t lastDeactivationTime_ = 0;
        uint32_t lastRecoveryTime_ = 0;

    public:
        StrainSystem() = default;
        explicit StrainSystem(Player* player);
        void initialize(std::shared_ptr<Player> player);
        
        // Métodos principais de controle
        bool activate();
        bool deactivate();
        bool isActive() const { return isActive_; }
        
        // Métodos de manipulação do strain
        bool addStrain(uint8_t amount);
        bool reduceStrain(uint8_t amount);
        bool removeStrain(uint8_t amount); // Alias para reduceStrain
        void resetStrain();
        
        // Getters
        uint8_t getStrainValue() const { return strainValue_; }
        StrainLevel getStrainLevel() const;
        uint8_t getStrainLevelNumber() const;
        uint8_t getCurrentLevel() const; // Alias para getStrainLevelNumber
        
        // Setters para persistência
        void setStrainValue(uint8_t value) { strainValue_ = value; }
        
        // Métodos de utilidade
        bool canActivate() const;
        bool canDeactivate() const;
        uint32_t getTimeSinceLastActivation() const;
        uint32_t getTimeSinceLastDeactivation() const;
        
        // Métodos de progressão automática
        void processStrainGrowth();
        void processStrainDecay();
        void onThink();
        
        // Métodos de informação
        std::string getStrainLevelName() const;
        std::string getStrainLevelColor() const;
        
    private:
        std::shared_ptr<Player> getPlayer() const;
        void sendStrainMessage(const std::string& message) const;
        void updateStrainEffects();
        uint32_t getCurrentTime() const;
    };
}