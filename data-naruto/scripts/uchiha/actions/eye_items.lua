-- Eye Items Action Script
-- Handles clicking on Eye slot items to activate/deactivate Sharingan

local eyeItemIds = {
    36311, -- Normal Eye
    36312, -- Sharingan Level 1
    36313, -- Sharingan Level 2
    36314 -- Sharingan Level 3
--[[     50303, -- Mangekyou Sharingan
    50304  -- Eternal Mangekyou Sharingan ]]
}

-- Map Sharingan levels to item IDs
local sharinganLevelToItemId = {
    [1] = 36312, -- Sharingan Level 1
    [2] = 36313, -- Sharingan Level 2
    [3] = 36314  -- Sharingan Level 3
}

local function onUseEyeItem(player, item, fromPosition, target, toPosition, isHotkey)
    local itemId = item:getId()
    
    -- Check if it's a normal eye (ID 36311)
    if itemId == 36311 then
        -- Normal eye - try to activate Sharingan if unlocked
        if not player:isSharinganUnlocked() then
            player:sendTextMessage(MESSAGE_STATUS, "You haven't unlocked the Sharingan yet.")
            return false
        end
        
        -- Activate Sharingan
        if player:activateSharingan() then
            -- Get current Sharingan level and update eye item accordingly
            local sharinganLevel = player:getSharinganLevel()
            local newItemId = sharinganLevelToItemId[sharinganLevel]
            
            if newItemId then
                -- Transform the eye item to match the Sharingan level
                item:transform(newItemId)
                player:sendTextMessage(MESSAGE_STATUS, "You activate your Sharingan! (Level " .. sharinganLevel .. ")")
            else
                player:sendTextMessage(MESSAGE_STATUS, "You activate your Sharingan!")
            end
            return true
        else
            player:sendTextMessage(MESSAGE_STATUS, "You cannot activate Sharingan right now.")
            return false
        end
    else
        -- Sharingan eye item - deactivate and return to normal eye
        if player:isSharinganActive() then
            player:deactivateSharingan()
            -- Transform back to normal eye
            item:transform(36311)
            player:sendTextMessage(MESSAGE_STATUS, "You deactivate your Sharingan.")
            return true
        else
            player:sendTextMessage(MESSAGE_STATUS, "Your Sharingan is not active.")
            return false
        end
    end
    
    return false
end

-- Register action for all eye item IDs
for _, itemId in ipairs(eyeItemIds) do
    local action = Action()
    action:id(itemId)
    action.onUse = onUseEyeItem
    action:register()
end