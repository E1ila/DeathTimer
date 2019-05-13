local unit, hpStack, dpsStack
local interval = 0.2
local stackSize = 15
local elapsed = 0
local secondsToDeath = nil 
local lastTime = nil

local function print(text)
    DEFAULT_CHAT_FRAME:AddMessage(text)
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
	print("|cFFFF962F DeathTimer |rLoaded")
	lastTime = GetTime()
end 

function DeathTimer_OnUpdate()
	local time = GetTime()
	local diff = time - lastTime
	lastTime = time

	elapsed = elapsed + diff
	if elapsed >= interval then 
		elapsed = elapsed - interval 

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
			if table.getn(hpStack) > stackSize then 
				table.remove(hpStack, 0)
				local percent = hpStack[1] - hpStack[stackSize]
				if percent == 0 or percent < 2 and hp > 80 then 
					secondsToDeath = nil 
				else 
					local dps = percent / (interval * stackSize)

					table.insert(dpsStack, dps)
					if table.getn(dpsStack) > stackSize then 
						table.remove(dpsStack, 0)
					end		

					local avgDps = average(dpsStack)
					if not avgDps then 
						secondsToDeath = nil 
					else
						secondsToDeath = hp / avgDps 
						-- print('dps ' .. avgDps .. '% et ' .. secondsToDeath)
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

