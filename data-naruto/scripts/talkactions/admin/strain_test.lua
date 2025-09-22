-- Strain System Test TalkActions
-- Commands for testing the Uchiha Strain System

-- Command: /strain activate
local strainActivate = TalkAction("/strain")

function strainActivate.onSay(player, words, param)
    if not player then
        return false
    end

    if param == "" then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Strain System Commands:")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain activate - Activate strain")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain deactivate - Deactivate strain")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain status - Check strain status")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain add <amount> - Add strain value")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain remove <amount> - Remove strain value")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "/strain level - Check current strain level")
        return true
    end

    local split = param:split(" ")
    local command = split[1]:lower()

    if command == "activate" then
        if player:activateStrain() then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Strain activated successfully!")
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Failed to activate strain. Check requirements.")
        end
        return true

    elseif command == "deactivate" then
        player:deactivateStrain()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Strain deactivated.")
        return true

    elseif command == "status" then
        local isActive = player:isStrainActive()
        local strainValue = player:getStrainValue()
        local strainLevel = player:getStrainLevel()
        
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "=== Strain Status ===")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Active: " .. (isActive and "Yes" or "No"))
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Strain Value: " .. string.format("%.2f", strainValue))
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Current Level: " .. strainLevel)
        return true

    elseif command == "add" then
        local amount = tonumber(split[2])
        if not amount or amount <= 0 then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Invalid amount. Use: /strain add <positive_number>")
            return true
        end

        if player:addStrain(amount) then
            local newValue = player:getStrainValue()
            local newLevel = player:getStrainLevel()
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                string.format("Added %.2f strain. New value: %.2f (Level %d)", amount, newValue, newLevel))
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Failed to add strain.")
        end
        return true

    elseif command == "remove" then
        local amount = tonumber(split[2])
        if not amount or amount <= 0 then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Invalid amount. Use: /strain remove <positive_number>")
            return true
        end

        if player:removeStrain(amount) then
            local newValue = player:getStrainValue()
            local newLevel = player:getStrainLevel()
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                string.format("Removed %.2f strain. New value: %.2f (Level %d)", amount, newValue, newLevel))
        else
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Failed to remove strain.")
        end
        return true

    elseif command == "level" then
        local strainLevel = player:getStrainLevel()
        local strainValue = player:getStrainValue()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
            string.format("Current Strain Level: %d (Value: %.2f)", strainLevel, strainValue))
        return true

    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Unknown command. Use '/strain' for help.")
        return true
    end
end

strainActivate:separator(" ")
strainActivate:groupType("god")
strainActivate:register()

-- Quick test command for strain growth simulation
local strainGrowth = TalkAction("/straingrowth")

function strainGrowth.onSay(player, words, param)
    if not player then
        return false
    end

    local amount = tonumber(param) or 10.0
    
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "=== Strain Growth Test ===")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Initial Status:")
    
    local initialValue = player:getStrainValue()
    local initialLevel = player:getStrainLevel()
    local isActive = player:isStrainActive()
    
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
        string.format("Value: %.2f, Level: %d, Active: %s", initialValue, initialLevel, isActive and "Yes" or "No"))
    
    -- Add strain and show progression
    if player:addStrain(amount) then
        local newValue = player:getStrainValue()
        local newLevel = player:getStrainLevel()
        
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "After adding " .. amount .. " strain:")
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
            string.format("Value: %.2f, Level: %d", newValue, newLevel))
        
        if newLevel > initialLevel then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                string.format("LEVEL UP! %d -> %d", initialLevel, newLevel))
        end
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Failed to add strain.")
    end
    
    return true
end

strainGrowth:separator(" ")
strainGrowth:groupType("god")
strainGrowth:register()