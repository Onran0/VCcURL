local curl = require "curl:curl"

function on_world_open()
	curl.initialize()
	require "curl:utils/fileutils".initialize()
end

function on_world_tick()
	curl.process_responses()
end
