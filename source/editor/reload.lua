
-- Define constants
local pd = playdate
local gfx = pd.graphics

local title = "Song added!"
local desc = "You'll need to reload the song list.\n\nPress "..char.up.."/"..char.A.." to do it now, or\npress any other button to dismiss\nwithout reloading."

function updateReloadMenu()
	
	if downPressed or leftPressed or rightPressed or bPressed then
		return "songSelect"
	end
	
	if aPressed or upPressed then
		reloadSongs()
		return "title"
	end
	
	return "reload"
end

function drawReloadMenu()
	gfx.setColor(gfx.kColorBlack)
	gfx.setLineWidth(9)
	gfx.drawRoundRect(50, 20, 300, 200, 9)
	gfx.setLineWidth(5)
	drawTextCentered(title, 200, 50, fonts.odinRounded)
	gfx.setFont(fonts.orbeatsSans)
	gfx.drawTextAligned(desc, 200, 100, kTextAlignment.center)
end