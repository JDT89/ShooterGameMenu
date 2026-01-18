--!strict
local Logger = {}

local function now()
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function Logger.info(tag: string, ...: any)
	print(string.format("[%s][%s] ", now(), tag), ...)
end

function Logger.warn(tag: string, ...: any)
	warn(string.format("[%s][%s] ", now(), tag), ...)
end

function Logger.debug(enabled: boolean, tag: string, ...: any)
	if enabled then
		print(string.format("[%s][%s][DEBUG] ", now(), tag), ...)
	end
end

return Logger
