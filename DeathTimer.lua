
Enabled = true 
Interval = 0.2
StackSize = 15
Debug = false

local unit, hpStack, dpsStack
local elapsed = 0
local secondsToDeath = nil 
local lastTime = nil

local MIN_INTERVAL_MS = 50
local MAX_TIME_MS = 20000
local MIN_TIME_MS = 1000

local function print(text)
    DEFAULT_CHAT_FRAME:AddMessage(text)
end

local function round(num, numDecimalPlaces)
	return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function average(stack) 
	if not stack then return nil end 
	
	local i 
	local sum = 0
	local count = table.getn(stack)

	if count == 0 then return nil end 

	for i = 1, count do 
		sum = sum + stack[i]
	end
	return sum / count
end 

function DeathTimer() 
	return secondsToDeath
end 

function DeathTimer_OnLoad()
	SLASH_DeathTimer1 = "/death"
    SlashCmdList["DeathTimer"] = DeathTimer_Main

	lastTime = GetTime()

	print("|cFFFF962F DeathTimer |rLoaded")
end 

function DeathTimer_OnUpdate()
	if not Enabled then return end 

	local time = GetTime()
	local diff = time - lastTime
	lastTime = time

	elapsed = elapsed + diff
	if elapsed >= Interval then 
		elapsed = elapsed - Interval 

		local target = UnitName'target'
		if target then
			if target ~= unit then 
				unit = target
				secondsToDeath = nil 
				hpStack = {}
				dpsStack = {}
			end 
			hp = UnitHealth'target'
			if hpStack and table.getn(hpStack) > 0 and hp > hpStack[table.getn(hpStack)] then 
				secondsToDeath = nil 
				hpStack = {}
			end
			if not hpStack then 
				hpStack = {}
				dpsStack = {}
			end
			table.insert(hpStack, hp)
			if table.getn(hpStack) > StackSize then 
				table.remove(hpStack, 0)
				-- print('StackSize = ' .. StackSize .. '   hpStack.len = ' .. table.getn(hpStack))
				local percent = hpStack[1] - hpStack[StackSize]
				if percent == 0 or percent < 2 and hp > 80 then 
					secondsToDeath = nil 
				else 
					local dps = percent / (Interval * StackSize)

					table.insert(dpsStack, dps)
					if table.getn(dpsStack) > StackSize then 
						table.remove(dpsStack, 0)
					end		

					local avgDps = average(dpsStack)
					if not avgDps then 
						secondsToDeath = nil 
					else
						secondsToDeath = hp / avgDps 
						if Debug then 
							print('|cFFFF962F DeathTimer |rDPS ' .. round(avgDps, 0) .. '  Time |cFFFFFF00' .. round(secondsToDeath, 1))
						end 
					end
				end 
			end 
		else
			secondsToDeath = nil 
			unit = nil
			hpStack = {}
			dpsStack = {}
		end
	end
end

function DeathTimer_Main(msg)
    local _, _, cmd, arg1 = string.find(string.upper(msg), "([%w]+)%s*(.*)$");
    -- print("|cFFFF962F RaidLogger |rcmd " .. cmd .. " / arg1 " .. arg1)
	if not cmd then
		local t = DeathTimer()
		if not t then 
			print("|cFFFF962F DeathTimer |rUnknown")
		else 
			print("|cFFFF962F DeathTimer |rTime to death: |cFF0000FF" .. DeathTimer())
		end 
    elseif  "R" == cmd or "RES" == cmd then
		if arg1 and string.len(arg1) > 0 then
			local x = tonumber(arg1)
			if x > 0 then 
				if x < MIN_INTERVAL_MS then x = MIN_INTERVAL_MS end 
				Interval = x / 1000
			else 
				print("|cFFFF962F DeathTimer |cFFFF0000Bad time " .. x .. "!")
			end
        else
            print("|cFFFF962F DeathTimer |cFFFF0000Missing time in miliseconds!")
        end
	elseif  "T" == cmd or "TIME" == cmd then
		if arg1 and string.len(arg1) > 0 then
			local x = tonumber(arg1)
			if x > 0 then 
				if x > MAX_TIME_MS then x = MAX_TIME_MS end 
				if x < MIN_TIME_MS then x = MIN_TIME_MS end 
				x = x / 1000
				StackSize = x / Interval
				if StackSize < 3 then StackSize = 3 end 
			else 
				print("|cFFFF962F DeathTimer |cFFFF0000Bad time " .. x .. "!")
			end
        else
            print("|cFFFF962F DeathTimer |cFFFF0000Missing time in miliseconds!")
		end
	elseif  "C" == cmd or "CONFIG" == cmd then
		local t = StackSize * Interval
		print("|cFFFF962F DeathTimer |rInterval=" .. round(Interval, 3) .. ", Time=" .. round(t, 3))
	elseif  "D" == cmd or "DISABLE" == cmd then
		Enabled = false 
		print("|cFFFF962F DeathTimer |rDisabled")
	elseif  "E" == cmd or "ENABLE" == cmd then
		Enabled = true 
		print("|cFFFF962F DeathTimer |rEnabled")
	elseif  "G" == cmd or "DEBUG" == cmd then
		Debug = not Debug 
		if Debug then 
			print("|cFFFF962F DeathTimer |rDebug enabled!")
		else 
			print("|cFFFF962F DeathTimer |rDebug disabled!")
		end 
    elseif  "H" == cmd or "HELP" == cmd then
        print("|cFFFF962F DeathTimer |rCommands: ")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl|r - print time to death")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl res <miliseconds>|r - sampling resolution in miliseconds.")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl time <miliseconds>|r - how far back (in miliseconds) to use for DPS calculation.")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl config|r - print current config of sampling resolution and time.")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl disable|r - disable calculations.")
        print("|cFFFF962F DeathTimer |r  |cFF00FF00/rl enable|r - enable calculations.")
	end 
end