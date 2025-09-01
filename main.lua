-- main.lua
-- Entry point: loads a tracklist (example.lua if present), starts the synth, and keeps feeding audio.

local Int = require("src.int")

local function tryRequire(name)
  local ok, mod = pcall(require, name)
  if ok then return mod end
  return nil
end

local TRACKLIST = tryRequire("example") or require("src.tracklist")

local SAMPLE_RATE = 44100
local BIT_DEPTH   = 16
local CHANNELS    = 1
local BUFFER_S    = 0.040    -- 40ms chunks for low latency but stable
local PREFILL_S   = 0.240    -- keep ~240ms queued ahead

function love.load()
  love.window.setTitle("Lua GB-like Synth")
  love.graphics.setBackgroundColor(0.07, 0.08, 0.11)

  Int.init{
    sampleRate = SAMPLE_RATE,
    bitDepth   = BIT_DEPTH,
    channels   = CHANNELS,
    bufferSec  = BUFFER_S,
    prefillSec = PREFILL_S
  }

  Int.setTracklist(TRACKLIST)
  Int.play()
end

function love.update(dt)
  -- keep the queue full
  Int.update(dt)
end

function love.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local margin = 24
  love.graphics.setColor(1,1,1)
  love.graphics.print("Lua GB-like Synth", margin, margin)

  local tl = Int.getTracklist()
  if tl then
    love.graphics.print(("Song length: %.2fs | tracks: %d"):format(tl.length, #tl.tracks), margin, margin + 22)
  end

  love.graphics.print("[SPACE] pause/resume   [R] restart   [ESC] quit", margin, h - margin - 18)
end

function love.keypressed(k)
  if k == "escape" then love.event.quit() end
  if k == "space"  then
    if Int.isPlaying() then Int.pause() else Int.play() end
  elseif k == "r" then
    Int.stop()
    Int.rewind()
    Int.play()
  end
end
