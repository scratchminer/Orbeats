-- map selection menu

local pd <const> = playdate
local gfx <const> = pd.graphics
local kb <const> = pd.keyboard

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

local oldText = ""

local mapHeaderX, mapHeaderY = 3, 3

local currentSongFilename = ""
local currentSongData = {}

local function getListOfMaps()
	local maps = {}
	
	for name, _ in pairs(currentSongData.mapData) do
		maps[#maps + 1] = name
	end
	
	return maps
end

local function keyboardClosing(confirmed)
	if confirmed then
		if selecting == "map" then
			currentSongData.mapData[kb.text] = {notes = {}, effects = {}, songEnd = 0}
		elseif selecting == "options" then
			currentSongData.mapData[kb.text] = currentSongData.mapData[oldText]
			currentSongData.mapData[oldText] = nil
		end
		setMapOptionsData(currentSongData)
	else
		songMaps[mapSelectionRounded] = oldText
		setMapOptionsData(currentSongData)
	end
	
	sfx.switch:play()
end

local function keyboardChanged()
	if selecting == "map" then
		songMaps[mapSelectionRounded] = kb.text
	end
end

-- this function sets the song that the draw and update functions will pull from when getting maps.
-- this takes in the song's editor data
function setMapOptionsData(data, audioFile)
	currentSongData = data

	if audioFile then currentSongFilename = audioFile end
	
	songMaps = getListOfMaps()
	songMaps[#songMaps + 1] = "Create..."
end

function updateMapSongsSelect()
	if not kb.isVisible() then
		if selecting == "option" then
			if aPressed or rightPressed then
				sfx.switch:play()
				
				if mapOptions[optionSelectionRounded] == "Edit" then
					initializeChartEditor(currentSongFilename, currentSongData, songMaps[mapSelectionRounded])
					return "chart"
				end
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
				if mapSelectionRounded == #songMaps then
					-- pull up keyboard to create map
					kb.show()
					kb.keyboardWillHideCallback = keyboardClosing
					kb.textChangedCallback = keyboardChanged
					oldText = songMaps[mapSelectionRounded]
					songMaps[mapSelectionRounded] = ""
				else
					selecting = "option"
				end
				sfx.tap:play()
			elseif bPressed or leftPressed then
				sfx.low:play()
				return "songSelect"
			elseif upPressed then
				mapSelection -= 1
			elseif downPressed then
				mapSelection += 1
			end
			
			mapSelection += crankChange/90
		end
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
	
	drawScrollingList(songMaps, mapSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, selecting == "map" and not kb.isVisible(), true)
	
	gfx.setColor(gfx.kColorWhite)
	gfx.setLineWidth(2)
	gfx.drawLine(267, 0, 267, screenHeight)
	
	drawList(mapOptions, optionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, selecting == "option" and not kb.isVisible(), true)
end
