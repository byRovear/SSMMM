-- src/tracklist.lua
-- Default tracklist showing the required schema.
-- Swap in example.lua for Mary Had a Little Lamb.

local TL = {
  length = 6.0, -- seconds
  tracks = {
    {
      name = "Lead",
      priority = 1,
      instrument = "square",
      notes = {
        -- t (sec), note name, duration (sec), velocity
        { t=0.00, note="C5", dur=0.30, vel=0.9 },
        { t=0.40, note="E5", dur=0.30, vel=0.9 },
        { t=0.80, note="G5", dur=0.40, vel=0.9 },
      }
    },
    {
      name = "Hat",
      priority = 0,
      instrument = "noise",
      notes = {
        { t=0.00, note="NOISE", dur=0.06, vel=0.7 },
        { t=0.50, note="NOISE", dur=0.06, vel=0.7 },
        { t=1.00, note="NOISE", dur=0.06, vel=0.7 },
        -- ...etc
      }
    }
  }
}

return TL
