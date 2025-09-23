local spell = Spell("instant")

local AREA_GOUKAKYU = {
	{0, 0, 1, 0, 0},
	{0, 1, 1, 1, 0},
	{0, 1, 1, 1, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 3, 0, 0},
	{0, 0, 0, 0, 0},
	{0, 0, 0, 0, 0},
	{0, 0, 0, 0, 0},
	{0, 0, 0, 0, 0},
}

local function getSequencedAreaPositions(player, area)
	local dir = player:getDirection()
	local origin = player:getPosition()
	local centerY = math.floor(#area / 2) + 1
	local centerX = math.floor(#area[1] / 2) + 1

	local lines = {}
	for y = 1, #area do
		for x = 1, #area[y] do
			if area[y][x] == 1 then
				local relX = x - centerX
				local relY = y - centerY
				local fx, fy

				 if dir == NORTH then
          fx, fy =  relX,  relY
        elseif dir == SOUTH then
          fx, fy = -relX, -relY
        elseif dir == EAST then                 -- <<< FIX
          fx, fy = -relY,  relX
        elseif dir == WEST then                 -- <<< FIX
          fx, fy =  relY, -relX
        end

				local worldPos = Position(origin.x + fx, origin.y + fy, origin.z)

				local distKey
				if dir == NORTH then distKey = -fy
				elseif dir == SOUTH then distKey =  fy
				elseif dir == EAST  then distKey =  fx
				elseif dir == WEST  then distKey = -fx end

				lines[distKey] = lines[distKey] or {}
				table.insert(lines[distKey], worldPos)
			end
		end
	end

	local sorted = {}
	local keys = {}
	for k in pairs(lines) do table.insert(keys, k) end
	table.sort(keys)
	for _, k in ipairs(keys) do table.insert(sorted, lines[k]) end
	return sorted
end

function spell.onCastSpell(player, variant)
	local level, ninjutsu = player:getLevel(), player:getMagicLevel()
	local min = (level / 5) + (ninjutsu * 1.5) + 18
	local max = (level / 5) + (ninjutsu * 2.4) + 30

	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
	combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
	combat:setFormula(COMBAT_FORMULA_LEVELMAGIC, 0, -min, 0, -max)

	local uid = player:getId()

	-- >>> Só a animação mudou para ABSOLUTA (delays = timestamps a partir do t=0)
	local animate = createSpellAnimation({
		frames = {
			-- t=100..700 → PREPARE
			{ delay = 100, say = "Katon...", outfit = UCHIHA.goukakyu.prepare, duration = 600 },

			-- t=700..1300 → CAST (sem overlap com o frame anterior)
			{ delay = 700, say = "Goukakyuu no Jutsu!", outfit = UCHIHA.goukakyu.cast, duration = 600 },

			-- t=900 → dano (acontece dentro da janela do CAST)
			{
				delay = 900,
				cast = function(p)
					-- mantém sua lógica original de FX frontal e ondas
					local dir = p:getDirection()
					local origin = p:getPosition()

					local fx = {
						[DIRECTION_NORTH] = {effectId = 116, x = 1, y = -1},
						[DIRECTION_EAST]  = {effectId = 115, x = 5, y = 1},
						[DIRECTION_SOUTH] = {effectId = 117, x = 1, y = 5},
						[DIRECTION_WEST]  = {effectId = 114, x = -1, y = 1},
					}

					local offset = fx[dir]
					if offset then
						Position(origin.x + offset.x, origin.y + offset.y, origin.z):sendMagicEffect(offset.effectId)
					end

					local lineGroups = getSequencedAreaPositions(p, AREA_GOUKAKYU)
					for lineIndex, positions in ipairs(lineGroups) do
						for _, pos in ipairs(positions) do
							local d = lineIndex * 100
							safePlayerEvent(uid, d, function(pl)
								combat:execute(pl, Variant(pos))
							end)
						end
					end
				end
			}
		}
	})

	
	return animate(player, variant)
end

spell:name("Katon: Goukakyuu no Jutsu")
spell:words("katon goukakyuu no jutsu")
spell:group("attack")
spell:id(1004)
spell:needDirection(true)
--[[ spell:level(18)
spell:mana(80)
spell:magicLevel(8)
spell:needLearn(true)
spell:vocation("uchihaclan")
spell:cooldown(14 * 1000)
spell:groupCooldown(2000) ]]
spell:register()
