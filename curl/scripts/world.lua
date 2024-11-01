local curl = require "curl:curl"
local http = require "curl:protocols/http"

local routine = coroutine.create(
	function()
		local status, error = pcall(
			function()
				print("REQUEST SENDED!!!!!!!!!!!!!!")
		
				local info, head = http.get("voxelworld.ru/api/v1/mods",
					{
						responseType = "dirty_json",
						secured = true
					}
				)

				debug.print(head)
				debug.print(info)
			end
		)

		if not status then print(error) end
	end
)

function on_world_open()
	curl.initialize()
	require "curl:utils/fileutils".initialize()
end

function on_world_tick()
	curl.process_responses()

	if coroutine.status(routine) ~= "dead" then
		coroutine.resume(routine)
	end
end