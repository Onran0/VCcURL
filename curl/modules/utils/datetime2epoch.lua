-- The MIT License (MIT)
-- Copyright (c) 2018,2020 Thomas Mohaupt <thomas.mohaupt@gmail.com>

-- year: 2-digit (means 20xx) or 4-digit (>= 2000)
local function datetime2epoch(second, minute, hour, day, month, year)
  local mi2sec = 60
  local h2sec = 60 * mi2sec
  local d2sec = 24 * h2sec
  -- month to second, without leap year 
  local m2sec = {
        0, 
        31 * d2sec, 
        59 * d2sec, 
        90 * d2sec, 
        120 * d2sec, 
        151 * d2sec, 
        181 * d2sec, 
        212 * d2sec, 
        243 * d2sec, 
        273 * d2sec, 
        304 * d2sec, 
        334 * d2sec }  
        
  local y2sec = 365 * d2sec
  local offsetSince1970 = 946684800

  local yy = year < 100 and year or year - 2000

  local leapCorrection = math.floor(yy/4) + 1  
  if (yy % 4) == 0 and month < 3 then
    leapCorrection = leapCorrection - 1
  end
  
  return offsetSince1970 + 
        second + 
        minute * mi2sec + 
        hour * h2sec + 
        (day - 1) * d2sec + 
        m2sec[month] + 
        yy * y2sec +
        leapCorrection * d2sec 
end

-- datetime2epoch(11,12,13,7,9,20) 
-- 1599484331
-- datetime2epoch(11,12,13,7,9,2020)
-- 1599484331

return datetime2epoch