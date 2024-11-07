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

local chartEditorState = 0 -- 0: main screen, 1: note edit

local noteEditorLabels <const> = {
  "Note type: ",
  "Spawn beat: ",
  "Hit beat: ",
  "Speed: ",
  "Width: ",
  "Position: ",
  "Spin: ",
  "Duration: ",
  "Delete note"
}

local noteEditorAttributes <const> = {
  "type",
  "spawnBeat",
  "hitBeat",
  "speed",
  "width",
  "position",
  "spin",
  "duration"
}

local noteEditorLabelsLen = 0

for k, v in pairs(noteEditorLabels) do
  noteEditorLabelsLen = noteEditorLabelsLen + 1
end

local noteEditorNoteIndex = 0
local noteEditorAttributeIndex = 1

local noteEditorSelectedAttribute = nil


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


local function clamp(n, min, max)
  return n < min and min or (n > max and max or n)
end

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
    if note["type"] == "FlipNote" then
      table.insert(chartEditorNotes, FlipNote(note["spawnBeat"], note["hitBeat"], note["speed"], note["width"], note["position"], note["spin"], note["duration"]))
    elseif note["type"] == "SlideNote" then
      table.insert(chartEditorNotes, SlideNote(note["spawnBeat"], note["hitBeat"], note["speed"], note["width"], note["position"], note["spin"], note["duration"]))
    else
      table.insert(chartEditorNotes, Note(note["spawnBeat"], note["hitBeat"], note["speed"], note["width"], note["position"], note["spin"], note["duration"]))
    end
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
  if chartEditorState == 0 then
    addChartEditorMenuItems()

    -- update the audio timer variable
    musicTime = chartEditorAudio:getOffset()
    -- update the current beat
    currentBeat = ((musicTime) / (60 / chartEditorMeta["songData"]["bpm"])) - chartEditorMeta["songData"]["beatOffset"]

    crankPos = pd.getCrankPosition()

    if playerFlipped then
      playerPos = crankPos + 180
      if playerPos > 360 then playerPos = playerPos - 360 end
    else
      playerPos = crankPos
    end

    playerX = orbitCenterX + orbitRadius * math.cos(math.rad(playerPos - 90))
    playerY = orbitCenterY + orbitRadius * math.sin(math.rad(playerPos - 90))

    if leftPressed then
      chartEditorBeat = chartEditorBeat - 1
      setAudioOffset()
    elseif rightPressed then
      chartEditorBeat = chartEditorBeat + 1
      setAudioOffset()
    end

    if downPressed then
      chartEditorBeat = chartEditorBeat - 0.25
      setAudioOffset()
    elseif upPressed then
      chartEditorBeat = chartEditorBeat + 0.25
      setAudioOffset()
    end

    if bPressed then
      
      -- return "songMaps"
    elseif aPressed then
      local thisNoteIndex
      for i, note in ipairs(chartEditorNotes) do -- fix for positions near 0
        local low = note["hitPos"] - note["width"] / 2
        local high = note["hitPos"] + note["width"] / 2

        -- if low < 0 then low = low + 360 end
        -- if high > 360 then high = high - 360 end

        if low > high then
          high, low = low, high
        end

        print(playerPos, note["hitPos"], low, high)
        print(playerPos >= low, playerPos <= high)

        if note["hitBeat"] == chartEditorBeat and (playerPos >= low and playerPos <= high) then
          thisNoteIndex = i
          break
        end
      end

      if thisNoteIndex == nil then
        table.insert(chartEditorSongData[chartEditorCurrentDifficulty]["notes"], { -- TODO: specify these values with the attribute editor after pressing A over note
          ["type"]="Note",
          ["spawnBeat"]=chartEditorBeat - 5,
          ["hitBeat"]=chartEditorBeat,
          ["speed"]=1,
          ["width"]=60,
          ["position"]=round(playerPos),
          ["spin"]=0,
          ["duration"]=0
        })
      else
        noteEditorNoteIndex = thisNoteIndex
        chartEditorState = 1
        -- table.remove(chartEditorSongData[chartEditorCurrentDifficulty]["notes"], thisNoteIndex)
      end
      updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
    end
  else
    if aPressed then
      noteEditorSelectedAttribute = noteEditorAttributes[noteEditorAttributeIndex]

      if noteEditorSelectedAttribute == nil then
        if noteEditorLabels[noteEditorAttributeIndex] == "Delete note" then
          table.remove(chartEditorSongData[chartEditorCurrentDifficulty]["notes"], noteEditorNoteIndex)
          noteEditorNoteIndex = nil
          noteEditorSelectedAttribute = nil
          chartEditorState = 0
          updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
        end
      end
    end

    if not noteEditorSelectedAttribute then
      if bPressed then
        chartEditorState = 0
      elseif upPressed then
        noteEditorAttributeIndex = clamp(noteEditorAttributeIndex - 1, 1, noteEditorLabelsLen)
      elseif downPressed then
        noteEditorAttributeIndex = clamp(noteEditorAttributeIndex + 1, 1, noteEditorLabelsLen)
      end
    else
      if bPressed then
        noteEditorSelectedAttribute = nil
      end

      if rightPressed then
        if noteEditorSelectedAttribute == "type" then
          local type = chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex]["type"]

          if type == "Note" then
            type = "SlideNote"
          elseif type == "SlideNote" then
            type = "FlipNote"
          elseif type == "FlipNote" then
            type = "Note"
          end

          chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex]["type"] = type
          updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
        else
          local val = chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorSelectedAttribute]

          chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorSelectedAttribute] = val + 1
          updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
        end
      elseif leftPressed then
        if noteEditorSelectedAttribute == "type" then
          local type = chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex]["type"]

          if type == "Note" then
            type = "FlipNote"
          elseif type == "FlipNote" then
            type = "SlideNote"
          elseif type == "SlideNote" then
            type = "Note"
          end

          chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex]["type"] = type
          updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
        else
          local val = chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorSelectedAttribute]

          chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorSelectedAttribute] = val - 1
          updateChartEditorSong(chartEditorSongData[chartEditorCurrentDifficulty])
        end

      end
    end
  end

	return "chartEditor"
end

function drawChartEditor()
  if chartEditorState == 0 then
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
  else
    gfx.clear()

    local genList = {}
    local fillList = false

    for i, v in ipairs(noteEditorLabels) do
      if chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorAttributes[i]] ~= nil then
        table.insert(genList, v .. chartEditorSongData[chartEditorCurrentDifficulty]["notes"][noteEditorNoteIndex][noteEditorAttributes[i]])
      else
        table.insert(genList, v)
      end
    end

    if noteEditorSelectedAttribute then
      fillList = true
    end

    drawScrollingList(genList, noteEditorAttributeIndex, 0, 0, 400, 240, 6, fonts.orbeatsSmall, fillList)
  end
end
