
-- Define constants

local pd <const> = playdate
local gfx <const> = pd.graphics
local kb <const> = pd.keyboard

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

-- Define variables

local songData = {}

songDataOrder = {
	"name",
	"artist",
	"bpm",
	"bpmChanges",
	"beatOffset",
	"preview"
}

songDataLabels = {
	name = "Song Name: ",
	artist = "Song Artist(s): ",
	bpm = "BPM: ",
	bpmChanges = "Set changes to BPM",
	beatOffset = "Beats until first note: ",
	preview = "Preview starts at second: "
}

songDataText = {}

local function readSongData()
	
	songDataText = {}
	
	songData = editorData[songList[songSelectionRounded]].songData
	
	for i=1,#songDataOrder do
		if type(songData[songDataOrder[i]]) == "number" or type(songData[songDataOrder[i]]) == "string" then
			table.insert(songDataText, songDataLabels[songDataOrder[i]]..songData[songDataOrder[i]])
		else
			table.insert(songDataText, songDataLabels[songDataOrder[i]])
		end
	end
	
end

local init = true

local paramSelection = 1
local oldParamSelection = paramSelection

local adjustingNumber = false
local prevAdjustingNumber = false
local menuFill = true

local oldValue = 0
local newValue = 0

local oldText = ""

local function keyboardClosing(confirmed)
	if confirmed then
		editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = kb.text
		readSongData()
	else
		editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = oldText
		readSongData()
	end
	
	sfx.switch:play()
end

function updateSongDataEditor()
	
	if init then
		readSongData()
		init = false
	end
	
	menuFill = not prevAdjustingNumber and not kb.isVisible()
	if menuFill then
		if bPressed then
			sfx.switch:play()
			init = false
			pd.datastore.write(editorData, "editorData")
			return "songSelect"
		end
		if aPressed then
			if type(songData[songDataOrder[paramSelection]]) == "string" then
				oldText = songData[songDataOrder[paramSelection]]
				kb.show(oldText)
				kb.keyboardWillHideCallback = keyboardClosing
				sfx.tap:play()
			elseif type(songData[songDataOrder[paramSelection]]) == "number" then
				oldValue = songData[songDataOrder[paramSelection]]
				newValue = oldValue
				adjustingNumber = true
				sfx.tap:play()
			end
		end
		if downPressed then
			paramSelection += 1
		end
		if upPressed then
			paramSelection -= 1
		end
	end
	
	-- round param selection
	paramSelection = math.min(#songDataText, math.max(paramSelection, 1))
	if oldParamSelection ~= paramSelection then
		sfx.click:play()
		oldParamSelection = paramSelection
	end
	
	-- update the selected parameter to match what the keyboard has typed
	if kb.isVisible() then
		if type(songData[songDataOrder[paramSelection]]) == "string" then
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = kb.text
			readSongData()
		end
	end
	
	if prevAdjustingNumber then
		if bPressed then
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = oldValue
			sfx.switch:play()
			adjustingNumber = false
		end
		if aPressed then
			sfx.switch:play()
			adjustingNumber = false
		end
		if downPressed then
			newValue -= 1
			sfx.click:play()
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = newValue
		end
		if upPressed then
			newValue += 1
			sfx.click:play()
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelection]] = newValue
		end
		
		readSongData()
	end
	
	prevAdjustingNumber = adjustingNumber
	
	return "songDataEditor"
end

function drawSongDataEditor()
	gfx.clear()
	
	-- draw the list of song data parameters
	drawList(songDataText, paramSelection, 3, 3, 394, 234, 3, fonts.orbeatsSans, menuFill, false)
end