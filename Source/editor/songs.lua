
-- Define constants

local pd <const> = playdate
local gfx <const> = pd.graphics

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2

local songOptions <const> = {
	"Set Data",
	"Edit Maps",
	"Export",
	"Delete"
}

local guideText <const> = "Read the online level editor manual\nto get started making your own levels!"

-- define variables
local function getListOfSongs()
	local songFiles = pd.file.listFiles("/editor songs/")
	if songFiles == nil then songFiles = {} end
	
	for i=#songFiles,1,-1 do
		if songFiles[i]:sub(-4) ~= '.pda' then
			table.remove(songFiles, i)
		else
			songFiles[i] = songFiles[i]:sub(1, -5)
			print(songFiles[i])
		end
	end
	
	return songFiles
end

-- turn characters that can't be put in a filename into underscores
function makeValidFilename(filename)
	return string.gsub(filename, "[%*<>/\\%?:|]", "_")
end

songList = getListOfSongs()

editorData = pd.datastore.read("editorData")
if editorData == nil then editorData = {} end

for i=1,#songList do
	if editorData[songList[i]] == nil then
		editorData[songList[i]] = {
			songData = {
				name = songList[i],
				artist = "N/A",
				bpm = 180,
				bpmChanges = {},
				beatOffset = 0,
				preview = 0,
				difficulties = {}
			},
			mapData = {}
		}
	end
end

pd.datastore.write(editorData, "editorData")

qrCode = gfx.image.new("sprites/manualCode")

local selecting = "song"

local songSelection = 1
songSelectionRounded = songSelection
local oldSongSelection = songSelection

local songOptionSelection = 1
local songOptionSelectionRounded = songOptionSelection
local oldSongOptionSelection = songOptionSelection

local deleting = false


function updateEditorSongsSelect()
	
	if not deleting and #songList > 0 then
		if selecting == "song" then
			if bPressed or leftPressed then
				sfx.low:play()
				return "exitEditor"
			end
			if aPressed or rightPressed then
				sfx.switch:play()
				selecting = "songOption"
			end
			if downPressed then
				songSelection = songSelectionRounded+1
			end
			if upPressed then
				songSelection = songSelectionRounded-1
			end
			songSelection += crankChange/90
		elseif selecting == "songOption" then
			if bPressed or leftPressed then
				sfx.switch:play()
				selecting = "song"
			end
			if aPressed or rightPressed then
				if songOptions[songOptionSelectionRounded] == "Delete" then
					deleting = true
					sfx.switch:play()
				elseif songOptions[songOptionSelectionRounded] == "Set Data" then
					sfx.mid:play()
					return "songDataEditor"
				elseif songOptions[songOptionSelectionRounded] == "Edit Maps" then
					sfx.mid:play()
					setMapOptionsData(editorData[songList[songSelectionRounded]])
					return "songMaps"
				elseif songOptions[songOptionSelectionRounded] == "Export" then
					sfx.switch:play()
					
					local songDirName = "/songs/"..makeValidFilename(editorData[songList[songSelectionRounded]].songData.name).."."..makeValidFilename(editorData[songList[songSelectionRounded]].songData.artist)
					local audioName = makeValidFilename(songList[songSelectionRounded])..".pda"
					
					pd.file.mkdir(songDirName)
					pd.datastore.write(editorData[songList[songSelectionRounded]].songData, songDirName.."/songData")
					
					local song = pd.file.open("/editor songs/"..audioName, pd.file.kFileRead)
					local outSong = pd.file.open(songDirName.."/"..audioName, pd.file.kFileWrite)
					
					for k = 0, pd.file.getSize("/editor songs/"..audioName)-1, 1024 do
						outSong:write(song:read(k))
					end
					outSong:close()
					song:close()
					
					for mapName, mapData in pairs(editorData[songList[songSelectionRounded]].mapData) do
						pd.datastore.write(mapData, songDirName.."/"..makeValidFilename(mapName))
					end
					
					return "reload"
				end
			end
			if downPressed then
				songOptionSelection = songOptionSelectionRounded+1
			end
			if upPressed then
				songOptionSelection = songOptionSelectionRounded-1
			end
			songOptionSelection += crankChange/90
		else
			
		end
	elseif deleting then
		if aHeld and upHeld then
			pd.file.delete("/editor songs/"..songList[songSelectionRounded]..".pda")
			songList = getListOfSongs()
			deleting = false
			sfx.play:play()
		end
		if bPressed or downPressed or leftPressed or rightPressed then
			deleting = false
			sfx.switch:play()
		end
	else
		if bPressed or leftPressed then
			sfx.low:play()
			return "exitEditor"
		end
	end
	-- round song selection
	songSelection = math.min(#songList, math.max(songSelection, 1))
	songSelectionRounded = round(songSelection)
	if oldSongSelection ~= songSelectionRounded then
		sfx.click:play()
		oldSongSelection = songSelectionRounded
	end
	-- round song option selection
	songOptionSelection = math.min(#songOptions, math.max(songOptionSelection, 1))
	songOptionSelectionRounded = round(songOptionSelection)
	if oldSongOptionSelection ~= songOptionSelectionRounded then
		sfx.click:play()
		oldSongOptionSelection = songOptionSelectionRounded
	end
	
	return "songSelect"
end

function drawEditorSongSelect()
	gfx.clear(gfx.kColorBlack)
	
	-- draw the manual code if no songs are detected
	if #songList == 0 then
		local codeX, codeY = screenCenterX-70, screenCenterY-100
		
		qrCode:draw(codeX, codeY)
		local textWidth, textHeight = gfx.getTextSize(guideText, fonts.orbeatsSans)
		local textX, textY = screenCenterX, screenCenterY+70
		local padding = 3
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(textX-textWidth/2-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 2)
		gfx.setFont(fonts.orbeatsSans)
		gfx.drawTextAligned(guideText, textX, textY, kTextAlignment.center)
	else
		-- draw the songs drawer
		local songHeaderX, songHeaderY = 3, 3
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		gfx.drawText("Songs", songHeaderX, songHeaderY, fonts.orbeatsSans)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)

		gfx.setColor(gfx.kColorWhite)
		gfx.setLineWidth(2)
		gfx.drawLine(133, 0, 133, screenHeight)
		
		-- draw the list of songs
		if selecting == "song" then
			drawScrollingList(songList, songSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, true, true)
		else
			drawScrollingList(songList, songSelectionRounded, 12, 22, 110, 216, 3, fonts.orbeatsSans, false, true)
		end
		
		-- draw the second drawer
		gfx.setColor(gfx.kColorWhite)
		gfx.setLineWidth(2)
		gfx.drawLine(267, 0, 267, screenHeight)
		
		if selecting == "song" or selecting == "songOption" then
			if selecting == "songOption" then
				drawScrollingList(songOptions, songOptionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, true, true)
			else
				drawScrollingList(songOptions, songOptionSelectionRounded, 136, 3, 110, 216, 3, fonts.orbeatsSans, false, true)
			end
		else
			
		end
	end
	
	if deleting then
		gfx.setColor(gfx.kColorBlack)
		gfx.setDitherPattern(0.5)
		gfx.fillRect(0, 0, screenWidth, screenHeight)
		
		local deletingWhat = "song"
		if selecting == "mapOption" then
			deletingWhat = "map"
		end
		local warningText = "Are you sure you want to\ndelete this "..deletingWhat.."?\nPress "..char.A.." and "..char.up.." to confirm,\nanything else to cancel."
		local textWidth, textHeight = gfx.getTextSize(warningText, fonts.orbeatsSans)
		local textX, textY = screenCenterX-textWidth/2, screenCenterY-textHeight/2
		local padding = 5
		gfx.setColor(gfx.kColorWhite)
		gfx.fillRoundRect(textX-padding, textY-padding, textWidth+padding*2, textHeight+padding*2, 3)
		gfx.setFont(fonts.orbeatsSans)
		gfx.drawTextAligned(warningText, screenCenterX, textY, kTextAlignment.center)
	end

end
