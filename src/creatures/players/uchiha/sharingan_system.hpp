/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019-2024 OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.com/
 */

#pragma once

#include <memory>

class Player;

namespace Uchiha {
    enum class SharinganLevel : uint8_t {
        LOCKED = 0,     // Sharingan não desbloqueado
        TOMOE_1 = 1,    // 1 Tomoe
        TOMOE_2 = 2,    // 2 Tomoe  
        TOMOE_3 = 3     // 3 Tomoe (Sharingan completo)
    };

    class SharinganSystem {
    private:
        std::weak_ptr<Player> player_;
        SharinganLevel level_ = SharinganLevel::LOCKED;
        uint32_t experience_ = 0;
        uint32_t usageCount_ = 0;
        bool isActive_ = false;
        uint32_t lastActivationTime_ = 0;

    public:
        SharinganSystem() = default;
        explicit SharinganSystem(Player* player);
        void initialize(std::shared_ptr<Player> player);
        
        // Métodos principais de controle
        bool unlock();
        bool activate();
        bool deactivate();
        bool isActive() const { return isActive_; }
        bool isUnlocked() const { return level_ != SharinganLevel::LOCKED; }
        
        // Métodos de progressão
        bool increaseLevel();
        bool addExperience(uint32_t amount);
        bool canEvolve() const;
        
        // Getters
        SharinganLevel getLevel() const { return level_; }
        uint8_t getLevelNumber() const { return static_cast<uint8_t>(level_); }
        std::string getLevelName() const;
        uint32_t getExperience() const { return experience_; }
        uint32_t getUsageCount() const { return usageCount_; }
        uint32_t getRequiredExperienceForLevel(uint8_t targetLevel) const;
        
        // Setters para persistência
        void setLevel(SharinganLevel level) { level_ = level; }
        void setLevel(uint8_t level);
        void setExperience(uint32_t experience) { experience_ = experience; }
        void setUsageCount(uint32_t count) { usageCount_ = count; }
        
        // Métodos de utilidade
        bool canActivate() const;
        uint32_t getTimeSinceLastActivation() const;
        void incrementUsage();
        
        // Métodos de informação
        std::string getSharinganInfo() const;
        
    private:
        std::shared_ptr<Player> getPlayer() const;
        void sendSharinganMessage(const std::string& message) const;
        void updateSharinganEffects();
        uint32_t getCurrentTime() const;
        bool validateLevel() const;
    };
}