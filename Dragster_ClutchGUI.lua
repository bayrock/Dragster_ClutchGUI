--[[
Dragster 5.57 Clutch GUI Script
Version 1.1
Date 2017-09-12
Written by Elipsis
Modified by Bayrock

This script was written and tested for BizHawk.  Basically, it will track and display how the clutch is used throughout a run.

The format is as follows:
InputNumber: TimeOfButtonRelease (EstimatedLeeway, clutchFrames)

Elipsis Note: I had to account for the fact that this game only processes inputs for player 1 on every other frame.  This means that it is possible to do a 1/60th second button press on an odd frame and not get a clutch.
A 3/60th of a frame button press may clutch for 1 or 2 increments of time for player 1.
--]]

-- Variable/function declaration
local lastinput
local disposition = 0
local shifts = 0
local clutchFrames = 0
local shiftDisplay = {}

local goldsplits = { -- The golden 5.57 shifts
	0.00, 0.30, 1.00, 1.80,
	2.53, 2.90, 3.34, 3.64, 3.90, 5.57
}

local function RunScript(script)
	while true do script() end
end

local function isClutchPressed(inp, activePly)
	return inp == 11 and activePly == 0
end

local function isClutchReleased(inp, lastinp)
	return inp == 15 and lastinp == 11
end

local function isResetPressed(inp)
	return inp == 7
end

local function calcDisposition(time, targettime)
	local newdispo = (time/0.03) - (targettime/0.03)
	disposition = disposition + math.abs(newdispo)
end

local seconds, fraction, input,
transmission, activePlayer

-- Script declaration
RunScript(function()
	-- Read Memory
	seconds = memory.readbyte(0x33,"Main RAM")
	fraction = memory.readbyte(0x35,"Main RAM")
	input = memory.readbyte(0x2D,"Main RAM")
	transmission = memory.readbyte(0x4C,"Main RAM")
	activePlayer = memory.readbyte(0x0F,"Main RAM")

	-- Clutch is down
	if isClutchPressed(input, activePlayer) then
		clutchFrames = clutchFrames + 1
	end

	-- Clutch is released
	if isClutchReleased(input, lastinput) then
		shifts = shifts + 1

		-- If the game detected the clutch depressed for at least one frame
		if clutchFrames > 0 and seconds == 170 then -- Timer hasn't started
			shiftDisplay[shifts] = {
				str = string.format("%d: EARLY", shifts),
				color = "red"
			}
		elseif clutchFrames > 0 and fraction < 100 then
			if fraction < 10 then
				fraction = "0"..fraction -- add the 0 for fractions that need it
			end

			local rawtime = string.format("%d.%s", seconds, fraction)
			local shifttime = tonumber(string.format("%.2f", rawtime))
			local shifttarget = goldsplits[shifts] -- Gold split for this gear

			if shifttime and shifttarget then -- Nullcheck prevents oddball errors
				calcDisposition(shifttime, shifttarget)
			end

			local txtcolor
			if shifttime == shifttarget then -- Compare to gold split
				txtcolor = "gold"
			elseif disposition < 15 then -- We've missed less than 15 frames
				txtcolor = "green"
			else
				txtcolor = "red"
			end

			shiftDisplay[shifts] = {
				str = string.format("%d: %.2f (%d leeway, %d clutch)", shifts, shifttime, 15 - disposition, clutchFrames),
				color = txtcolor
			}
		else -- If we get here, the input was dropped
			shiftDisplay[shifts] = {
				str = string.format("%d: INPUT DROP", shifts),
				color = "gray"
			}
		end

		clutchFrames = 0
	end

	-- Reinstate on reset
	if isResetPressed(input) then
		shifts = 0
		clutchFrames = 0
		shiftDisplay = {}
		disposition = 0
	end

	-- Draw GUI
	for gearvalue,gear in ipairs(shiftDisplay) do
		if gearvalue > 9 then break end -- Skip 10th gear, because the time is captured too early
		gui.text(0, gearvalue * 12 + 300, gear.str, gear.color)
	end

	-- Set last input
	lastinput = input

	-- Advance frame
	emu.frameadvance()
end)
