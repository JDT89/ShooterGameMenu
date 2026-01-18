--!strict
export type Task = RBXScriptConnection | Instance | (() -> ()) | { Destroy: (any) -> () }

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} :: { Task } }, Maid)
end

function Maid:give(task: Task): Task
	table.insert(self._tasks, task)
	return task
end

function Maid:cleanup()
	for i = #self._tasks, 1, -1 do
		local task = self._tasks[i]
		self._tasks[i] = nil

		local t = typeof(task)
		if t == "RBXScriptConnection" then
			(task :: RBXScriptConnection):Disconnect()
		elseif t == "Instance" then
			(task :: Instance):Destroy()
		elseif t == "function" then
			(task :: () -> ())()
		elseif t == "table" then
			local tbl = task :: any
			if typeof(tbl.Destroy) == "function" then
				tbl:Destroy()
			end
		end
	end
end

return Maid
