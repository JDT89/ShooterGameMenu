--!strict

local PlayerProfile = {}

-- Simple, stable leveling curve (tweak later)
-- Level 1 -> 100 XP, grows ~15% each level
function PlayerProfile.getExpToNext(level: number): number
	level = math.max(1, math.floor(level))
	local base = 100
	local growth = 1.15
	local exp = math.floor(base * (growth ^ (level - 1)))
	return math.max(50, exp)
end

function PlayerProfile.addExp(level: number, exp: number, addAmount: number): (number, number, number)
	local newLevel = math.max(1, math.floor(level))
	local newExp = math.max(0, math.floor(exp)) + math.max(0, math.floor(addAmount))

	while true do
		local expToNext = PlayerProfile.getExpToNext(newLevel)
		if newExp < expToNext then
			return newLevel, newExp, expToNext
		end
		newExp -= expToNext
		newLevel += 1
	end
end

return PlayerProfile
