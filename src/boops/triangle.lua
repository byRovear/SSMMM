-- src/boops/triangle.lua
-- Soft triangle wave with the same ADSR as square for consistency.

local M = {}
local ADSR = { attack=0.006, decay=0.050, sustain=0.85, release=0.030 }

local function env(t, dur)
  if t < 0 then return 0 end
  local a, d, s, r = ADSR.attack, ADSR.decay, ADSR.sustain, ADSR.release
  local srStart = a + d
  local srEnd   = dur
  if t < a then
    return t / a
  elseif t < srStart then
    local x = (t - a) / d
    return 1.0 + (s - 1.0) * x
  elseif t < srEnd then
    return s
  else
    local tr = t - srEnd
    if tr >= r then return 0 end
    return s * (1.0 - tr / r)
  end
end

local function tri(phase)
  -- Map [0,1) to triangle in [-1,1]
  if phase < 0.25 then
    return phase * 4
  elseif phase < 0.75 then
    return 2 - phase * 4
  else
    return phase * 4 - 4
  end
end

function M.sampleAt(freq, tFromOnset, dur, sr, ev)
  if freq <= 0 then return 0 end
  local e = env(tFromOnset, dur)
  if e <= 0 then return 0 end
  local phase = (tFromOnset * freq) % 1.0
  local s = tri(phase)
  return s * e * 0.8
end

return M
