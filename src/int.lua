-- src/int.lua
-- Simple software mixer + instrument host using love.audio.newQueueableSource.
-- Converts note events to PCM and queues audio buffers just-in-time.

local boops = {
  square   = require("src.boops.square"),
  triangle = require("src.boops.triangle"),
  noise    = require("src.boops.noise"),
}

local Int = {}

local cfg = {
  sampleRate = 44100,
  bitDepth   = 16,
  channels   = 1,
  bufferSec  = 0.04,
  prefillSec = 0.24,
}

local qsrc           -- queueable source
local bufferSamples
local prefillSamples

local tracklist
local playhead = 0.0        -- seconds rendered
local playing  = false

-- note -> frequency
local function noteToFreq(note)
  -- Accepts "A4", "C#5", "Db3", etc. Special case for "NOISE"
  if note == "NOISE" then return 0 end
  local nn, acc, oct = note:match("^([A-Ga-g])([#b]?)(%-?%d+)$")
  if not nn then return nil end
  nn = nn:upper()
  oct = tonumber(oct)

  local semitab = {C=0, D=2, E=4, F=5, G=7, A=9, B=11}
  local n = semitab[nn]
  if not n then return nil end
  if acc == "#" then n = n + 1
  elseif acc == "b" then n = n - 1 end

  local midi = (oct + 1) * 12 + n  -- C-1 -> 0
  local a4 = 69
  return 440.0 * (2 ^ ((midi - a4) / 12))
end

-- Prepare queueable source and sizes
function Int.init(options)
  for k,v in pairs(options or {}) do cfg[k] = v end
  bufferSamples  = math.floor(cfg.bufferSec  * cfg.sampleRate + 0.5)
  prefillSamples = math.floor(cfg.prefillSec * cfg.sampleRate + 0.5)
  qsrc = love.audio.newQueueableSource(cfg.sampleRate, cfg.bitDepth, cfg.channels, 8)
end

function Int.setTracklist(tl)
  tracklist = tl
  playhead = 0
end

function Int.getTracklist()
  return tracklist
end

function Int.isPlaying() return playing end

function Int.play()
  if not qsrc then return end
  if not qsrc:isPlaying() then qsrc:play() end
  playing = true
end

function Int.pause()
  if qsrc then qsrc:pause() end
  playing = false
end

function Int.stop()
  if qsrc then
    qsrc:stop()
    -- Flush queued buffers by recreating the source
    qsrc = love.audio.newQueueableSource(cfg.sampleRate, cfg.bitDepth, cfg.channels, 8)
  end
  playing = false
end

function Int.rewind()
  playhead = 0
end

-- Mix a time slice [t0, t1) into a mono float buffer
local function mixSlice(t0, t1, sr, out)
  local nsamp = #out
  for i=1,nsamp do out[i] = 0.0 end

  if not tracklist or not tracklist.tracks then return end

  local function addSample(i, v)
    -- gentle limiter
    local s = out[i] + v
    if s >  1.0 then s =  1.0 end
    if s < -1.0 then s = -1.0 end
    out[i] = s
  end

  for _, tr in ipairs(tracklist.tracks) do
    local instName = tr.instrument or "square"
    local inst = boops[instName]
    if inst then
      for __, ev in ipairs(tr.notes or {}) do
        local nt = ev.t or 0.0
        local nd = ev.dur or 0.2
        local vel = ev.vel or 1.0
        local ntEnd = nt + nd

        -- any overlap with slice?
        if ntEnd > t0 and nt < t1 then
          local startInSlice = math.max(nt, t0)
          local endInSlice   = math.min(ntEnd, t1)

          local f = noteToFreq(ev.note)
          -- Render just the overlapped portion on-the-fly
          for i=0,(math.floor((endInSlice - startInSlice) * sr + 0.5)-1) do
            local t = startInSlice + i / sr
            -- instrument returns sample value at absolute time t
            local s = inst.sampleAt(f, t - nt, nd, sr, ev) * vel
            local idx = math.floor((t - t0) * sr + 0.5) + 1
            if idx >= 1 and idx <= nsamp then
              addSample(idx, s)
            end
          end
        end
      end
    end
  end
end

-- Convert float [-1,1] to SoundData (int16)
local function floatsToSoundData(floatBuf, sr, bitDepth, channels)
  local sd = love.sound.newSoundData(#floatBuf, sr, bitDepth, channels)
  for i=0,#floatBuf-1 do
    sd:setSample(i, floatBuf[i+1])
  end
  return sd
end

function Int.update(dt)
  if not playing or not tracklist or not qsrc then return end

  -- If song ended, just stop feeding
  if tracklist.length and playhead >= tracklist.length then
    return
  end

  -- How many samples are currently queued approximately?
  -- We can't read queued duration directly, so keep filling until prefill target.
  while qsrc:getFreeBufferCount() > 0 do
    local remaining = (tracklist.length or math.huge) - playhead
    if remaining <= 0 then break end

    local sliceSec = math.min(cfg.bufferSec, remaining)
    local nsamp = math.floor(sliceSec * cfg.sampleRate + 0.5)
    local floatBuf = {}
    for i=1,nsamp do floatBuf[i] = 0 end

    mixSlice(playhead, playhead + sliceSec, cfg.sampleRate, floatBuf)

    local sd = floatsToSoundData(floatBuf, cfg.sampleRate, cfg.bitDepth, cfg.channels)
    qsrc:queue(sd)
    playhead = playhead + sliceSec

    if not qsrc:isPlaying() then qsrc:play() end

    -- If we filled enough ahead, bail this frame
    -- (Coarse control: we trust BUFFER count to throttle)
  end
end

return Int
