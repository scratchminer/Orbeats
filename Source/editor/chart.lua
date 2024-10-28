-- chart editor :blobfoxfingerguns:

local pd <const> = playdate
local gfx <const> = pd.graphics
local snd <const> = pd.sound

local audio, meta

-- initialize chart editor with needed data, such as the song's audio and metadata
function initializeChartEditor(audioFilename, metadata)
	audio = snd.fileplayer.new("/editor songs/" .. audioFilename)
	meta = metadata
end

function updateChartEditor()
	if bPressed then
		return "songMaps"
	end

	return "chart"
end

function drawChartEditor()
	gfx.clear()
	gfx.drawText("in chart editor!", 5, 5, fonts.orbeatsSans)
end
