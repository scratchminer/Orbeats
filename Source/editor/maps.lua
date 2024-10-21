-- map selection menu

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240

local mapOptions <const> = {
	"Edit",
	"Move Up",
	"Move Down",
	"Rename",
	"Duplicate",
	"Delete"
}

local songMaps = {}

local selecting = "map"

local optionSelection = 1
local optionSelectionRounded = optionSelection
local oldOptionSelection = optionSelection

local mapSelection = 1
local mapSelectionRounded = mapSelection
local oldMapSelection = mapSelection

local mapHeaderX, mapHeaderY = 3, 3

local currentSongData = {}

local function getListOfMaps()
	local songFiles = pd.file.listFiles("/editor songs/" .. makeValidFilename(currentSongData.name) .. "." .. makeValidFilename(currentSongData.artist))
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
	songMaps[#songMaps + 1] = "Create..."
end

function updateMapSongsSelect()
	if selecting == "option" then
		if aPressed or rightPressed then
			sfx.switch:play()
			-- do stuff here
		elseif bPressed or leftPressed then
			sfx.switch:play()
			selecting = "map"
		elseif upPressed then
			optionSelection -= 1
		elseif downPressed then
			optionSelection += 1
		end
		
		optionSelection += crankChange/90
	elseif selecting == "map" then
		if aPressed or rightPressed then
			sfx.switch:play()
			if mapSelectionRounded == #songMaps then
				-- pull up keyboard to create map
			else
				selecting = "option"
			end
		elseif bPressed or leftPressed then
			sfx.switch:play()
			return "songSelect"
		elseif upPressed then
			mapSelection -= 1
		elseif downPressed then
			mapSelection += 1
		end
		
		mapSelection += crankChange/90
	end
	
	optionSelection = math.min(#mapOptions, math.max(optionSelection, 1))
	optionSelectionRounded = round(optionSelection)
	if oldOptionSelection ~= optionSelectionRounded then
		sfx.click:play()
		oldOptionSelection = optionSelectionRounded
	end
	
	mapSelection = math.min(#songMaps, math.max(mapSelection, 1))
	mapSelectionRounded = round(mapSelection)
	if oldMapSelection ~= mapSelectionRounded then
		sfx.click:play()
		oldMapSelection = mapSelectionRounded
	end
	
	return "songMaps"
end

function drawMapSongsSelect()
	gfx.clear(gfx.kColorBlack)
	
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawText("Maps", mapHeaderX, mapHeaderY, fonts.orbeatsSans)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	
	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(2)
	gfx.drawLine(133, 0, 133, screenHeight)
	
	drawScrollingList(songMaps, mapSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, selecting == "map", true)
	
	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(2)
	gfx.drawLine(267, 0, 267, screenHeight)
	
	drawList(mapOptions, optionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, selecting == "option", true)
end
