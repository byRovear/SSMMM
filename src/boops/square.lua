-- src/boops/square.lua
-- Game Boy–ish pulse wave with selectable duty cycle + simple ADSR.

local M = {}

-- Simple ADSR in seconds
local ADSR = { attack=0.005, decay=0.040, sustain=0.75, release=0.020 }

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

local function pulse(phase, duty)
  -- phase in [0,1)
  return (phase < duty) and 1.0 or -1.0
end

function M.sampleAt(freq, tFromOnset, dur, sr, ev)
  if freq <= 0 then return 0 end
  local duty = (ev and ev.duty) or 0.5  -- 12.5, 25, 50, 75% etc.
  if duty <= 0 then duty = 0.01 elseif duty >= 1 then duty = 0.99 end
  local e = env(tFromOnset, dur)
  if e <= 0 then return 0 end
  local phase = (tFromOnset * freq) % 1.0
  local s = pulse(phase, duty)
  -- Very light lowpass for harshness control
  local brightness = (ev and ev.bright) or 0.15
  return s * e * (1.0 - brightness) + s * e * brightness * 0.6
end

return M
