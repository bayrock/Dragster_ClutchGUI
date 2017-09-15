--[[
Dragster Clutching Display Script
Version 1.0
Date 2017-09-12
Written by Elipsis

This script was written and tested for BizHawk.  Basically, it will track and display how the clutch is used throughout a run.  The format is as follows.

InputNumber: TimeOfButtonRelease (NumberOfPlayerOneFramesHeldDown)

Note that I had to account for the fact that this game only processes inputs for player 1 on every other frame.  This means that it is possible to do a 1/60th second button press on an odd frame and not get a clutch.
A 3/60th of a frame button press may clutch for 1 or 2 increments of time for player 1.

Outstanding issues:
Alternating processing causes the script to be one frame ahead of game display of clutch on 50% of the frames.
Displays "1.03" as "1.3" whereas "1.30" is correct
--]]

shifts = 0
clutchFrames = 0
shiftDisplay = {}

while true do

    --Read Memory
    seconds = memory.readbyte(0x33,"Main RAM")
    fraction = memory.readbyte(0x35,"Main RAM")
    input = memory.readbyte(0x2D,"Main RAM")
    gear = memory.readbyte(0x4C,"Main RAM")
    activePlayer = memory.readbyte(0x0F,"Main RAM")

    --Clutch is down
    if (input == 11 and activePlayer == 0) then
        clutchFrames = clutchFrames + 1
    end

    --Clutch is released
    if (input == 15 and lastinput == 11) then

        shifts = shifts + 1

        --If the game detected the clutch depressed for at least one P1 frame
        if(clutchFrames > 0) then
            if(seconds == 170) then
                shiftDisplay [shifts] = (shifts .. ": EARLY")
            else
                shiftDisplay [shifts] = (shifts .. ": " .. string.format("%x",seconds) .. "." .. string.format("%x",fraction) .. "(" .. clutchFrames.. ")" )
            end

        --If we get here, the input was dropped
        else
            shiftDisplay[shifts] = (shifts .. ": INPUT DROP (0)")

        end

        clutchFrames = 0

    end

    --Reinitialize on reset press
    if (input == 7) then
        shifts = 0
        clutchFrames = 0
        shiftDisplay = {}
    end

    --Output full array!
    for i,v in ipairs(shiftDisplay) do
        gui.text(0, i * 12 + 300, v , "red")
    end

    lastinput = input

    emu.frameadvance()
end
