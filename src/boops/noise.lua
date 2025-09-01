-- src/boops/noise.lua
-- Simple white noise blip (for percussion) with fast decay.

local M = {}
local ADSR = { attack=0.001, decay=0.06, sustain=0.0, release=0.02 }

-- simple LCG for deterministic noise per note event
local function makeRNG(seed)
  local x = seed or 1234567
  return function()
    x = (1103515245 * x + 12345) % 2147483648
    return (x / 2147483648) * 2 - 1  -- [-1,1)
  end
end

function M.sampleAt(freq, tFromOnset, dur, sr, ev)
  local a, d, s, r = ADSR.attack, ADSR.decay, ADSR.sustain, ADSR.release
  local function env(t)
    if t < 0 then return 0 end
    if t < a then return t / a end
    t = t - a
    if t < d then
      local x = 1 - (t / d)
      return x -- drop to 0 (sustain=0)
    end
    local after = t - d
    if after < (dur - (a + d)) then return 0 end
    local rel = after - (dur - (a + d))
    if rel >= r then return 0 end
    return (1 - rel / r) * 0.2
  end

  -- Seed per event so it’s stable for that note
  if not ev.__rng then
    local seed = math.floor((ev.t or 0) * 1000) + (ev.dur or 0)*100 + (ev.vel or 0)*10
    ev.__rng = makeRNG(seed)
  end
  local e = env(tFromOnset)
  if e <= 0 then return 0 end
  return ev.__rng() * e
end

return M
