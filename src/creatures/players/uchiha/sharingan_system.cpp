/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019-2024 OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.com/
 */

#include "sharingan_system.hpp"
#include "creatures/players/player.hpp"
#include "game/game.hpp"
#include "lib/logging/logger.hpp"
#include "utils/utils_definitions.hpp"
#include <string>

namespace Uchiha {

SharinganSystem::SharinganSystem(Player* player) : player_() {
    // Não usar shared_from_this() no construtor
}

void SharinganSystem::initialize(std::shared_ptr<Player> player) {
    player_ = std::weak_ptr<Player>(player);
    level_ = SharinganLevel::LOCKED;
    experience_ = 0;
    usageCount_ = 0;
    isActive_ = false;
    lastActivationTime_ = 0;
}

std::shared_ptr<Player> SharinganSystem::getPlayer() const {
    return player_.lock();
}

bool SharinganSystem::unlock() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (isUnlocked()) {
        sendSharinganMessage("Seu Sharingan já está desbloqueado!");
        return false;
    }

    level_ = SharinganLevel::TOMOE_1;
    experience_ = 0;
    
    sendSharinganMessage("Parabéns! Você desbloqueou o Sharingan com 1 Tomoe!");
    g_logger().info("[SharinganSystem] Player {} unlocked Sharingan", player->getName());
    
    return true;
}

bool SharinganSystem::activate() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (!canActivate()) {
        sendSharinganMessage("Você não pode ativar o Sharingan agora!");
        return false;
    }

    if (isActive_) {
        sendSharinganMessage("Seu Sharingan já está ativo!");
        return false;
    }

    isActive_ = true;
    lastActivationTime_ = getCurrentTime();
    incrementUsage();
    
    sendSharinganMessage("Sharingan ativado! Seus olhos brilham com poder.");
    updateSharinganEffects();
    g_logger().info("[SharinganSystem] Player {} activated Sharingan level {}", 
                   player->getName(), static_cast<int>(level_));
    
    return true;
}

bool SharinganSystem::deactivate() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (!isActive_) {
        sendSharinganMessage("Seu Sharingan já está desativado!");
        return false;
    }

    isActive_ = false;
    
    sendSharinganMessage("Sharingan desativado.");
    g_logger().info("[SharinganSystem] Player {} deactivated Sharingan", player->getName());
    
    return true;
}

bool SharinganSystem::increaseLevel() {
    auto player = getPlayer();
    if (!player) {
        return false;
    }

    if (!isUnlocked()) {
        sendSharinganMessage("Você precisa desbloquear o Sharingan primeiro!");
        return false;
    }

    if (level_ >= SharinganLevel::TOMOE_3) {
        sendSharinganMessage("Seu Sharingan já está no nível máximo!");
        return false;
    }

    if (!canEvolve()) {
        uint32_t requiredExp = getRequiredExperienceForLevel(getLevelNumber() + 1);
        sendSharinganMessage("Você precisa de " + std::to_string(requiredExp - experience_) + 
                           " pontos de experiência para evoluir!");
        return false;
    }

    SharinganLevel oldLevel = level_;
    std::string oldLevelName = getLevelName();
    level_ = static_cast<SharinganLevel>(static_cast<uint8_t>(level_) + 1);
    std::string newLevelName = getLevelName();
    std::string message = "Seu Sharingan evoluiu de " + oldLevelName + " para " + newLevelName + "!";
    sendSharinganMessage(message);
    
    g_logger().info("[SharinganSystem] Player {} evolved Sharingan from level {} to {}", 
                   player->getName(), static_cast<int>(oldLevel), static_cast<int>(level_));
    
    return true;
}

bool SharinganSystem::addExperience(uint32_t amount) {
    if (amount == 0 || !isUnlocked()) {
        return false;
    }

    experience_ += amount;
    
    auto player = getPlayer();
    if (player) {
        sendSharinganMessage("Você ganhou " + std::to_string(amount) + " pontos de experiência Sharingan!");
        
        // Verificar se pode evoluir automaticamente
        if (canEvolve() && level_ < SharinganLevel::TOMOE_3) {
            sendSharinganMessage("Seu Sharingan está pronto para evoluir! Use o comando para evoluir.");
        }
    }
    
    return true;
}

bool SharinganSystem::canEvolve() const {
    if (!isUnlocked() || level_ >= SharinganLevel::TOMOE_3) {
        return false;
    }
    
    uint32_t requiredExp = getRequiredExperienceForLevel(getLevelNumber() + 1);
    return experience_ >= requiredExp;
}

std::string SharinganSystem::getLevelName() const {
    switch (level_) {
        case SharinganLevel::LOCKED:
            return "Bloqueado";
        case SharinganLevel::TOMOE_1:
            return "1 Tomoe";
        case SharinganLevel::TOMOE_2:
            return "2 Tomoe";
        case SharinganLevel::TOMOE_3:
            return "3 Tomoe";
        default:
            return "Desconhecido";
    }
}

uint32_t SharinganSystem::getRequiredExperienceForLevel(uint8_t targetLevel) const {
    switch (targetLevel) {
        case 1: // TOMOE_1
            return 0;
        case 2: // TOMOE_2
            return 1000;
        case 3: // TOMOE_3
            return 3000;
        default:
            return 0;
    }
}

void SharinganSystem::setLevel(uint8_t level) {
    if (level > 3) {
        level = 3;
    }
    level_ = static_cast<SharinganLevel>(level);
}

bool SharinganSystem::canActivate() const {
    return isUnlocked() && !isActive_;
}

uint32_t SharinganSystem::getTimeSinceLastActivation() const {
    if (lastActivationTime_ == 0) {
        return 0;
    }
    return getCurrentTime() - lastActivationTime_;
}

void SharinganSystem::incrementUsage() {
    usageCount_++;
    
    // Ganhar experiência por uso (pequena quantidade)
    if (isUnlocked()) {
        addExperience(10);
    }
}

std::string SharinganSystem::getSharinganInfo() const {
    if (!isUnlocked()) {
        return "Sharingan: Bloqueado";
    }
    
    std::string info = "Sharingan: " + getLevelName();
    info += " | Experiência: " + std::to_string(experience_);
    info += " | Usos: " + std::to_string(usageCount_);
    info += " | Status: " + std::string(isActive_ ? "Ativo" : "Inativo");
    
    if (canEvolve() && level_ < SharinganLevel::TOMOE_3) {
        info += " | PRONTO PARA EVOLUIR!";
    }
    
    return info;
}

void SharinganSystem::sendSharinganMessage(const std::string& message) const {
    auto player = getPlayer();
    if (player) {
        player->sendTextMessage(MESSAGE_STATUS, "[Sharingan] " + message);
    }
}

void SharinganSystem::updateSharinganEffects() {
    auto player = getPlayer();
    if (!player || !isActive_) {
        return;
    }
    
    // Aqui podem ser adicionados efeitos visuais ou de gameplay
    // Por exemplo: mudança de outfit, efeitos mágicos, etc.
    // Por enquanto, apenas log
    g_logger().debug("[SharinganSystem] Updated effects for player {} with level {}", 
                    player->getName(), static_cast<int>(level_));
}

uint32_t SharinganSystem::getCurrentTime() const {
    return static_cast<uint32_t>(OTSYS_TIME() / 1000);
}

bool SharinganSystem::validateLevel() const {
    return level_ >= SharinganLevel::LOCKED && level_ <= SharinganLevel::TOMOE_3;
}

}