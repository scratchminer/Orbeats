-- map selection menu

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240

local mapOptions <const> = {
  "New Map",
  "Edit Chart",
  "Move Up",
  "Move Down",
  "Rename",
  "Duplicate",
  "Delete"
}

local songMaps = {}

local selecting = "option"

local optionSelection = 1
optionSelectionRounded = optionSelection
local oldOptionSelection = optionSelection

local mapSelection = 1
local mapSelectionRounded = mapSelection
local oldMapSelection = mapSelection

local songHeaderX, songHeaderY = 3, 3

local currentSongData = {}

function makeValidFilename(filename)
	return string.gsub(filename, "[%*<>/\\%?:|]", "_")
end

local function getListOfMaps()
  local songFiles = pd.file.listFiles("/songs/" .. makeValidFilename(currentSongData["name"]) .. "." .. makeValidFilename(currentSongData["artist"]))
  if songFiles == nil then songFiles = {} end

  for i = #songFiles, 1, -1 do
    if songFiles[i]:sub(-5) ~= '.json' or songFiles[i] == "songData.json" then
      table.remove(songFiles, i)
    else
      songFiles[i] = songFiles[i]:sub(1, -6)
    end
  end

  return songFiles
end

-- this function sets the song that the draw and update functions will pull from when getting maps.
-- this takes in the songData.json data
function setMapOptionsData(data)
  currentSongData = data

  songMaps = getListOfMaps()
end

function updateMapSongsSelect()
  if selecting == "option" then
    if aPressed or rightPressed then
      sfx.switch:play()
      if mapOptions[optionSelectionRounded] == "New Map" then
        -- open keyboard to create new map?
      else
        selecting = "map"
      end
    elseif bPressed or leftPressed then
      sfx.switch:play()
      return "songSelect"
    elseif upPressed then
      optionSelection -= 1
    elseif downPressed then
      optionSelection += 1
    end
  elseif selecting == "map" then
    if aPressed or rightPressed then
      sfx.switch:play()
      -- do stuff here
    elseif bPressed or leftPressed then
      sfx.switch:play()
      selecting = "option"
    elseif upPressed then
      mapSelection -= 1
    elseif downPressed then
      mapSelection += 1
    end
  end

  optionSelection = math.min(#mapOptions, math.max(optionSelection, 1))
  optionSelectionRounded = round(optionSelection)
  if oldOptionSelection ~= optionSelectionRounded then
    oldSongSelection = optionSelectionRounded
  end

  mapSelection = math.min(#songMaps, math.max(mapSelection, 1))
  mapSelectionRounded = round(mapSelection)
  if oldMapSelection ~= mapSelectionRounded then
    oldSongOptionSelection = mapSelectionRounded
  end

  return "songMaps"
end

function drawMapSongsSelect()
  gfx.clear(gfx.kColorBlack)

  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
  gfx.drawText("Map Options", songHeaderX, songHeaderY, fonts.orbeatsSans)
  gfx.setImageDrawMode(gfx.kDrawModeCopy)

  gfx.setColor(gfx.kColorWhite)
  gfx.setLineWidth(2)
  gfx.drawLine(133, 0, 133, screenHeight)

  if selecting == "option" then
    drawScrollingList(mapOptions, optionSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, true, true)
  else
    drawScrollingList(mapOptions, optionSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, false, true)
  end

  gfx.setColor(gfx.kColorWhite)
  gfx.setLineWidth(2)
  gfx.drawLine(267, 0, 267, screenHeight)

  if selecting == "option" or selecting == "map" then
    if selecting == "map" then
      drawScrollingList(songMaps, mapSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, true, true)
    else
      drawScrollingList(songMaps, mapSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, false, true)
    end
  else

  end
end
