-- spell_animation.lua (ABSOLUTE ONLY)
-- Timeline ABSOLUTA: cada frame.delay é um timestamp a partir do t=0 do cast.

local ACTIVE      = {}      -- [uid] = { token=#, subId=# }
local SUB_BASE    = 77000   -- base do SUBID p/ CONDITION_OUTFIT (use um range exclusivo)

-- sanidade
local MAX_FRAMES   = 32
local MIN_DUR_MS   = 30
local MAX_DUR_MS   = 4000
local MAX_TOTAL_MS = 12000

-- Executa callback apenas se Player(uid) ainda existir
local function safePlayerEvent(uid, delay, callback)
  addEvent(function()
    local p = Player(uid)
    if not p or p:isRemoved() then return end
    callback(p)
  end, delay)
end

local function clamp(n, lo, hi)
  n = tonumber(n) or 0
  if n < lo then return lo end
  if n > hi then return hi end
  return n
end

local function applyOutfitFor(caster, outfit, ms, subId, baseColors)
  if not caster or caster:isRemoved() then return end
  local cond = Condition(CONDITION_OUTFIT)
  cond:setParameter(CONDITION_PARAM_SUBID, subId)
  cond:setTicks(ms)
  local lt = type(outfit) == "number" and outfit or outfit.lookType
  cond:setOutfit({
    lookType   = lt,
    lookHead   = (outfit.lookHead   or baseColors.lookHead),
    lookBody   = (outfit.lookBody   or baseColors.lookBody),
    lookLegs   = (outfit.lookLegs   or baseColors.lookLegs),
    lookFeet   = (outfit.lookFeet   or baseColors.lookFeet),
    lookAddons = (outfit.lookAddons or baseColors.lookAddons),
    lookMount  = (outfit.lookMount  or baseColors.lookMount),
  })
  caster:addCondition(cond)
end

local function applyFreezeFor(caster, ms, penalty)
  if not caster or caster:isRemoved() or ms <= 0 then return end
  local cond = Condition(CONDITION_PARALYZE)
  cond:setTicks(ms)
  cond:setParameter(CONDITION_PARAM_TICKS, ms)
  cond:setParameter(CONDITION_PARAM_SPEED, -(penalty or 1000))
  caster:addCondition(cond)
end

-- API ABSOLUTA:
-- createSpellAnimation({
--   frames = {
--     { delay=ms, duration=ms, say="...", outfit=number|table|function(player)->table,
--       effect=CONST_ME_*, cast=function(player, variant), restore=true? },
--     ...
--   },
--   freeze=true/false,
--   freezePenalty=number
-- })
function createSpellAnimation(config)
  assert(type(config) == "table" and type(config.frames) == "table" and #config.frames > 0,
    "[createSpellAnimation] config.frames inválido")

  local frames = config.frames

  return function(player, variant)
    if not player then return false end
    local uid = player:getId()

    -- encerra anima anterior (se houver) e remove só a nossa condition
    if ACTIVE[uid] then
      local prev = ACTIVE[uid]
      local p = Player(uid)
      if p then p:removeCondition(CONDITION_OUTFIT, prev.subId) end
    end

    -- novo token/subId
    local token = (ACTIVE[uid] and ACTIVE[uid].token or 0) + 1
    local subId = SUB_BASE + token
    ACTIVE[uid] = { token = token, subId = subId }

    -- snapshot de cores uma vez
    local base = player:getOutfit()
    local baseColors = {
      lookHead   = base.lookHead,
      lookBody   = base.lookBody,
      lookLegs   = base.lookLegs,
      lookFeet   = base.lookFeet,
      lookAddons = base.lookAddons,
      lookMount  = base.lookMount,
    }

    -- agenda frames (ABSOLUTO)
    local total, count = 0, 0
    for i = 1, math.min(#frames, MAX_FRAMES) do
      local f = frames[i]
      local startAt = clamp(tonumber(f.delay) or 0, 0, MAX_TOTAL_MS)

      local dur = f.duration and clamp(f.duration, MIN_DUR_MS, MAX_DUR_MS) or 0
      if startAt + dur > total then total = startAt + dur end

      safePlayerEvent(uid, startAt, function(caster)
        -- valida token (anti-overlap)
        local state = ACTIVE[uid]
        if not state or state.token ~= token then return end

        if f.say then caster:say(f.say, TALKTYPE_MONSTER_SAY) end

        if f.outfit then
          local o = f.outfit
          if type(o) == "function" then o = o(caster) end
          if type(o) == "number" then o = { lookType = o } end
          if o and o.lookType then
            applyOutfitFor(caster, o, (dur > 0 and dur or 500) + 40, subId, baseColors)
          end
        elseif f.restore then
          caster:removeCondition(CONDITION_OUTFIT, subId)
        end

        if f.effect then
          caster:getPosition():sendMagicEffect(f.effect)
        end

        if type(f.cast) == "function" then
          local ok, err = pcall(f.cast, caster, variant)
          if not ok then print("[SpellAnim] cast error:", err) end
        end
      end)

      count = count + 1
    end

    total = clamp(total, 0, MAX_TOTAL_MS)

    if config.freeze then
      applyFreezeFor(player, total, config.freezePenalty or 1000)
    end

    -- remove nossa condition no final
    safePlayerEvent(uid, total + 10, function(caster)
      local state = ACTIVE[uid]
      if not state or state.token ~= token then return end
      caster:removeCondition(CONDITION_OUTFIT, subId)
    end)

    -- cleanup do estado (mesmo se o player sumir)
    addEvent(function()
      local state = ACTIVE[uid]
      if not state or state.token ~= token then return end
      ACTIVE[uid] = nil
    end, total + 20)

    return count > 0
  end
end

-- Cancelamento manual (se quiser cortar imediatamente)
function cancelSpellAnimation(player)
  if not player then return end
  local uid = player:getId()
  local state = ACTIVE[uid]
  if state then
    local p = Player(uid)
    if p then p:removeCondition(CONDITION_OUTFIT, state.subId) end
    ACTIVE[uid] = nil
  end
end
