
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
local paramSelectionRounded = 1
local oldParamSelection = paramSelectionRounded

local adjustingNumber = false
local prevAdjustingNumber = false
local menuFill = true

local oldValue = 0
local newValue = 0
local newValueRounded = 0

local oldText = ""

local function keyboardClosing(confirmed)
	if confirmed then
		editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelectionRounded]] = kb.text
		readSongData()
	else
		editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelectionRounded]] = oldText
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
			if type(songData[songDataOrder[paramSelectionRounded]]) == "string" then
				oldText = songData[songDataOrder[paramSelectionRounded]]
				kb.show(oldText)
				kb.keyboardWillHideCallback = keyboardClosing
				sfx.tap:play()
			elseif type(songData[songDataOrder[paramSelectionRounded]]) == "number" then
				oldValue = songData[songDataOrder[paramSelectionRounded]]
				newValue = oldValue
				newValueRounded = oldValue
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
		
		paramSelection += crankChange/90
	end
	
	-- round param selection
	paramSelection = math.min(#songDataText, math.max(paramSelection, 1))
	paramSelectionRounded = round(paramSelection)
	if oldParamSelection ~= paramSelectionRounded then
		sfx.click:play()
		oldParamSelection = paramSelectionRounded
	end
	
	-- update the selected parameter to match what the keyboard has typed
	if kb.isVisible() then
		if type(songData[songDataOrder[paramSelectionRounded]]) == "string" then
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelectionRounded]] = kb.text
			readSongData()
		end
	end
	
	if prevAdjustingNumber then
		if aPressed then
			sfx.switch:play()
			adjustingNumber = false
		end
		if downPressed then
			newValue -= 1
			sfx.click:play()
		end
		if upPressed then
			newValue += 1
			sfx.click:play()
		end
		newValue += crankChange/90
		newValueRounded = round(newValue)
		editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelectionRounded]] = newValueRounded
		
		if bPressed then
			editorData[songList[songSelectionRounded]].songData[songDataOrder[paramSelectionRounded]] = oldValue
			sfx.switch:play()
			adjustingNumber = false
		end
		
		readSongData()
	end
	
	prevAdjustingNumber = adjustingNumber
	
	return "songDataEditor"
end

function drawSongDataEditor()
	gfx.clear()
	
	-- draw the list of song data parameters
	drawList(songDataText, paramSelectionRounded, 3, 3, 394, 234, 3, fonts.orbeatsSans, menuFill, false)
end