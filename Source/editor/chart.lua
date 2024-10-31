-- chart editor :blobfoxfingerguns:
--
-- Crank determines where to place notes, with the option to turn on snapping to set angles
-- Press A to add a note if not already present
-- Press A to edit a selected note’s attributes
-- Press B to switch between editing notes and effects
-- D-pad to scrub through the song by the beat, left and right for by a full beat, up and down for smaller increments of a beat
-- Edit the bpm changes in the map editing screen, but it saves it for all maps of a single song
-- Map editor will show the orbit in the middle, with panels on the left and right to show information and editing windows
-- After exporting a song, prompt the player to restart their game so it loads their exported song into their song list

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound
local menu <const> = pd.getSystemMenu()

local screenWidth <const> = 400
local screenHeight <const> = 240
local screenCenterX <const> = screenWidth / 2
local screenCenterY <const> = screenHeight / 2


local chartEditorBeat = 1
local chartEditorSongData
local chartEditorAudio, chartEditorMeta, chartEditorCurrentDifficulty
local chartEditorNotes = {}

local musicTime, currentBeat = 0, 0

local orbitRadius = 110
local orbitCenterX = screenCenterX
local orbitCenterY = screenCenterY

local pulse = 0
local pulseDepth = 3

local playerX = orbitCenterX + orbitRadius
local playerY = orbitCenterY
local playerPos = crankPos
local playerRadius = 8
local playerFlipped = false


local missedNoteRadius <const> = 300 -- the radius where notes get deleted

local function setAudioOffset()
  if chartEditorBeat >= 0 then
    local offset = chartEditorBeat * ((chartEditorMeta["songData"]["bpm"] / 60) - chartEditorMeta["songData"]["beatOffset"])

    chartEditorAudio:setOffset(offset)
  end
end

local function addChartEditorMenuItems()
  local playStopMenuItem

  if chartEditorAudio:isPlaying() then
    playStopMenuItem = menu:addMenuItem("stop song")
  else
    playStopMenuItem = menu:addMenuItem("play song")
  end

  playStopMenuItem:setCallback(function()
    if chartEditorAudio:isPlaying() then
      chartEditorAudio:stop()

      chartEditorAudio:setOffset(chartEditorBeat * ((chartEditorMeta["songData"]["bpm"] / 60) - chartEditorMeta["songData"]["beatOffset"]))
    else
      chartEditorAudio:play()
    end
  end)
end

local function updateChartEditorSong(data)
  chartEditorNotes = {}
  for i, note in ipairs(data["notes"]) do
    table.insert(chartEditorNotes, Note(note["spawnBeat"], note["hitBeat"], note["speed"], note["width"], note["position"], note["spin"], note["duration"]))
  end
end

-- initialize chart editor with needed data, such as the song's audio and metadata
function initializeChartEditor(audioFilename, metadata, difficultyName)
	chartEditorAudio = snd.fileplayer.new("/editor songs/" .. audioFilename)
	chartEditorMeta = metadata
	chartEditorCurrentDifficulty = difficultyName
	
	chartEditorSongData = table.deepcopy(metadata["mapData"])
  updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
end

function updateChartEditor()
  addChartEditorMenuItems()

  -- update the audio timer variable
  musicTime = chartEditorAudio:getOffset()
  -- update the current beat
  currentBeat = ((musicTime) / (60 / chartEditorMeta["songData"]["bpm"])) - chartEditorMeta["songData"]["beatOffset"]

  crankPos = pd.getCrankPosition()

	if playerFlipped then
		playerPos = crankPos + 180
		if playerPos > 360 then playerPos -= 360 end
	else
		playerPos = crankPos
	end

	playerX = orbitCenterX + orbitRadius * math.cos(math.rad(playerPos - 90))
	playerY = orbitCenterY + orbitRadius * math.sin(math.rad(playerPos - 90))

  if leftPressed then
    chartEditorBeat -= 1
    setAudioOffset()
  elseif rightPressed then
    chartEditorBeat += 1
    setAudioOffset()
  end

  if downPressed then
    chartEditorBeat -= 0.25
    setAudioOffset()
  elseif upPressed then
    chartEditorBeat += 0.25
    setAudioOffset()
  end

  if bPressed then
    
		-- return "songMaps"
	elseif aPressed then
    local thisNoteIndex
    for i, note in ipairs(chartEditorNotes) do
      if note["hitBeat"] == chartEditorBeat and (playerPos >= note["hitPos"] - (note["width"] / 2) and playerPos <= note["hitPos"] + (note["width"] / 2)) then
        thisNoteIndex = i
        break
      end
    end

    if thisNoteIndex == nil then
      table.insert(chartEditorSongData[chartEditorCurrentDifficulty]["notes"], {
        ["type"]="Note",
        ["spawnBeat"]=chartEditorBeat - 5, -- ? dunno HOW you're gonna specify this..
        ["hitBeat"]=chartEditorBeat,
        ["speed"]=1,
        ["width"]=60,
        ["position"]=playerPos,
        ["spin"]=0
      })
    else
      table.remove(chartEditorSongData[chartEditorCurrentDifficulty]["notes"], thisNoteIndex)
    end
    updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
	end

	return "chart"
end

function drawChartEditor()
	gfx.clear()

	-- draw orbit
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius - pulse)
	gfx.setColor(gfx.kColorBlack)
	gfx.setDitherPattern(0.75)
	gfx.setLineWidth(5)
	gfx.drawCircleAtPoint(orbitCenterX, orbitCenterY, orbitRadius - pulse)

	-- draw player
	gfx.setColor(gfx.kColorWhite)
	gfx.fillCircleAtPoint(playerX, playerY, playerRadius)
	gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(2)
	gfx.drawCircleAtPoint(playerX, playerY, playerRadius)

	-- draw notes
	for i, v in ipairs(chartEditorNotes) do
    local thisBeat, data

    if chartEditorAudio:isPlaying() then
      thisBeat = currentBeat
    else
      thisBeat = chartEditorBeat
    end

    data = v:update(thisBeat, orbitRadius)

    if v["spawnBeat"] <= thisBeat and data.endRadius < missedNoteRadius then
      v:draw(orbitCenterX, orbitCenterY, orbitRadius)
    end
	end

  local leftSidebarText = {
    "audio offset: " .. tostring(musicTime) .. "s",
    "audio beat: " .. tostring(currentBeat),
    "editor beat: " .. tostring(chartEditorBeat)
  }

  local rightSidebarText = {
    "song: " .. tostring(chartEditorMeta["songData"]["name"]),
    "difficulty: " .. tostring(chartEditorCurrentDifficulty)
  }

  for i, v in ipairs(leftSidebarText) do
    gfx.drawText(v, 2, (i - 1) * 12 + 2, fonts.orbeatsSmall)
  end

  for i, v in ipairs(rightSidebarText) do
    gfx.drawText(v, 398 - fonts.orbeatsSmall[gfx.font.kVariantNormal]:getTextWidth(v), (i - 1) * 12 + 2, fonts.orbeatsSmall)
  end
end
