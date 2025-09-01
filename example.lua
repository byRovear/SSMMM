local BPM = 120
local BEAT = 60 / BPM

local function t(b) return b * BEAT end

local notes = {
  -- b, note, dur(beats), vel
  {0.0, "E4", 1, 0.95},
  {1.0, "D4", 1, 0.95},
  {2.0, "C4", 1, 0.95},
  {3.0, "D4", 1, 0.95},
  {4.0, "E4", 1, 0.95},
  {5.0, "E4", 1, 0.95},
  {6.0, "E4", 2, 0.95},

  {8.0, "D4", 1, 0.95},
  {9.0, "D4", 1, 0.95},
  {10.0,"D4", 2, 0.95},

  {12.0,"E4", 1, 0.95},
  {13.0,"G4", 1, 0.95},
  {14.0,"G4", 2, 0.95},

  {16.0,"E4", 1, 0.95},
  {17.0,"D4", 1, 0.95},
  {18.0,"C4", 1, 0.95},
  {19.0,"D4", 1, 0.95},
  {20.0,"E4", 1, 0.95},
  {21.0,"E4", 1, 0.95},
  {22.0,"E4", 1, 0.95},
  {23.0,"E4", 1, 0.95},

  {24.0,"D4", 1, 0.95},
  {25.0,"D4", 1, 0.95},
  {26.0,"E4", 1, 0.95},
  {27.0,"D4", 1, 0.95},
  {28.0,"C4", 2, 0.95},
}

local lead = {
  name = "Lead",
  priority = 10,
  instrument = "square",
  notes = {}
}

for _, n in ipairs(notes) do
  table.insert(lead.notes, {
    t   = t(n[1]),
    note= n[2],
    dur = n[3] * BEAT,
    vel = n[4],
    duty= 0.25, 
  })
end

local hats = {
  name = "Hat",
  priority = 1,
  instrument = "noise",
  notes = {}
}

for b=0, math.ceil((notes[#notes][1] + notes[#notes][3]) + 4) do
  -- eighth-note hats
  table.insert(hats.notes, { t = t(0.5 * b), note="NOISE", dur=0.05, vel=0.35 })
end

local last = lead.notes[#lead.notes]
local length = last.t + last.dur + 1.0

return {
  length = length,
  tracks = {
    lead,
    hats
  }
}



