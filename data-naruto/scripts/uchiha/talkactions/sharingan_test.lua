-- Sharingan System Test Script
-- Este script permite testar todas as funcionalidades do SharinganSystem

-- TalkAction para desbloquear o Sharingan
local unlockSharingan = TalkAction("!unlock-sharingan")

function unlockSharingan.onSay(player, words, param)
    if not player:isSharinganUnlocked() then
        if player:unlockSharingan() then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan desbloqueado com sucesso!")
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nível atual: " .. player:getSharinganLevel())
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Falha ao desbloquear o Sharingan.")
        end
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan já está desbloqueado!")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nível atual: " .. player:getSharinganLevel())
    end
    return false
end

unlockSharingan:separator(" ")
unlockSharingan:groupType("normal")
unlockSharingan:register()

-- TalkAction para aumentar o nível do Sharingan
local increaseSharinganLevel = TalkAction("!sharingan-level-up")

function increaseSharinganLevel.onSay(player, words, param)
    if not player:isSharinganUnlocked() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você precisa desbloquear o Sharingan primeiro!")
        return false
    end

    local currentLevel = player:getSharinganLevel()
    if player:increaseSharinganLevel() then
        local newLevel = player:getSharinganLevel()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan evoluiu! Nível " .. currentLevel .. " -> " .. newLevel)
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Não foi possível aumentar o nível do Sharingan.")
    end
    return false
end

increaseSharinganLevel:separator(" ")
increaseSharinganLevel:groupType("normal")
increaseSharinganLevel:register()

-- TalkAction para ativar o Sharingan
local activateSharingan = TalkAction("!sharingan-on")

function activateSharingan.onSay(player, words, param)
    if not player:isSharinganUnlocked() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você precisa desbloquear o Sharingan primeiro!")
        return false
    end

    if player:isSharinganActive() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan já está ativo!")
        return false
    end

    if player:activateSharingan() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan ativado! Nível: " .. player:getSharinganLevel())
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Falha ao ativar o Sharingan.")
    end
    return false
end

activateSharingan:separator(" ")
activateSharingan:groupType("normal")
activateSharingan:register()

-- TalkAction para desativar o Sharingan
local deactivateSharingan = TalkAction("!sharingan-off")

function deactivateSharingan.onSay(player, words, param)
    if not player:isSharinganUnlocked() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você precisa desbloquear o Sharingan primeiro!")
        return false
    end

    if not player:isSharinganActive() then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan já está desativado!")
        return false
    end

    player:deactivateSharingan()
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sharingan desativado.")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    return false
end

deactivateSharingan:separator(" ")
deactivateSharingan:groupType("normal")
deactivateSharingan:register()

-- TalkAction para verificar status do Sharingan
local sharinganStatus = TalkAction("!sharingan-status")

function sharinganStatus.onSay(player, words, param)
    local isUnlocked = player:isSharinganUnlocked()
    local level = player:getSharinganLevel()
    local isActive = player:isSharinganActive()

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "=== Status do Sharingan ===")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Desbloqueado: " .. (isUnlocked and "Sim" or "Não"))
    
    if isUnlocked then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nível: " .. level)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Ativo: " .. (isActive and "Sim" or "Não"))
    end
    
    return false
end

sharinganStatus:separator(" ")
sharinganStatus:groupType("normal")
sharinganStatus:register()

-- TalkAction para ajuda com comandos
local sharinganHelp = TalkAction("!sharingan-help")

function sharinganHelp.onSay(player, words, param)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "=== Comandos do Sharingan ===")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!unlock-sharingan - Desbloqueia o Sharingan")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!sharingan-level-up - Aumenta o nível do Sharingan")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!sharingan-on - Ativa o Sharingan")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!sharingan-off - Desativa o Sharingan")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!sharingan-status - Mostra status atual")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "!sharingan-help - Mostra esta ajuda")
    return false
end

sharinganHelp:separator(" ")
sharinganHelp:groupType("normal")
sharinganHelp:register()