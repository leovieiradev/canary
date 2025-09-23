function safePlayerEvent(uid, delay, callback)
	addEvent(function()
		local player = Player(uid)
		if not player or player:isRemoved() then return end
		callback(player)
	end, delay)
end