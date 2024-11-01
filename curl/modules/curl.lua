local logger = require "curl:utils/logger":create("curl")

local curl = { }

curl.info = { }

local ipc = require "curl:ipc":new("export:curl/internal/ipc")

local http

local initialized, connectable, has_program_api

local curlVersionChars =
{
	'0', '1', '2',
	'3', '4', '5',
	'6', '7', '8',
	'9', '.'
}

local function parseCurlInfo(info)
	--curl 8.9.1

    for line in info:gmatch("[^\r\n]+") do
    	if string.starts_with(line, "curl ") then
	       	local version = ""
			local system = ""

			local versionEndIndex = -1

			for i = 6, #line do
				local char = line:sub(i, i)

				if not table.has(curlVersionChars, char) then
					versionEndIndex = i
					break
				end

				version = version..char
			end

			for i = versionEndIndex + 2, #line do
				local char = line:sub(i, i)

				if char == ')' then
					break
				end

				system = system..char
			end

			curl.info.version = version
			curl.info.system = system
		elseif string.starts_with(line, "Release-Date:") then
			curl.info.release_date = { }

			curl.info.release_date.readable = line:sub(15)

			local releaseDateParts = string.split(curl.info.release_date.readable, "-")

			for i = 1, #releaseDateParts do
				releaseDateParts[i] = tonumber(releaseDateParts[i])
			end

			curl.info.release_date.parts =
			{
				year = releaseDateParts[1],
				month = releaseDateParts[2],
				day = releaseDateParts[3]
			}

			curl.info.release_date.epoch =
			require "curl:utils/datetime2epoch"(
				0, 0, 0,
				releaseDateParts[3],
				releaseDateParts[2],
				releaseDateParts[1]
			)
		elseif string.starts_with(line, "Protocols:") then
			curl.info.protocols = string.split(line:sub(12), " ")
		elseif string.starts_with(line, "Features:") then
			curl.info.features = string.split(line:sub(11), " ")
		end
    end
end

local function delete(relativePath)
	local requestId = ipc:delete_request(relativePath)

	logger:debug("created delete request. ID: ", requestId, ", relative path: ", relativePath)

	return requestId
end

local function execute(responseHandler, argsProvider)
	local requestId = ipc:execute_request(responseHandler, argsProvider)

	logger:debug("created execute request. ID: ", requestId)

	return requestId
end

function curl.initialize()
	if initialized then return end

	if curl.has_program_api() then
		execute(
			function(info)
				logger:info("program API is connectable")

				connectable = true

				logger:debug("parsing curl version info")

				curl.info.version = ""
				curl.info.system = ""
				curl.info.release_date = { epoch = 0, readable = "", parts = { year = 0, month = 0, day = 0 } }
				curl.info.protocols = { }
				curl.info.features = { }

				local status, error = pcall(parseCurlInfo, info)

				if not status then
					logger:error("failed to parse curl info: "..error)
				end
			end,
			"-V"
		)
	else
		logger:warn("program API is missing")
		connectable = false
	end

	http = require "curl:protocols/http"

	http.initialize(execute, delete)

	initialized = true

	logger:info("curl initialized")
end

function curl.has_program_api()
	if has_program_api == nil then
		has_program_api = file.exists("user:vccurl_replier.bat") or file.exists("user:vccurl_replier.sh")
	end

	return has_program_api
end

function curl.is_program_api_connectable()
	return connectable
end

function curl.process_responses()
	ipc:process_responses()
end

function curl.url_encode(str)
	if str == nil then
		return
	end

	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w _ %- . ~])", function(c) return string.format("%%%02X", string.byte(c)) end)
	str = str:gsub(" ", "+")

	return str
end

function curl.url_decode(str)
	if str == nil then
		return
	end

	str = str:gsub("+", " ")
	str = str:gsub("%%(%x%x)", function(x) return string.char(tonumber(x, 16)) end)

	return str
end

function curl.get_protocol(url)
	local protocolEndIndex = url:find('://')

	if not protocolEndIndex then return end

	return url:sub(1, protocolEndIndex - 1)
end

function curl.use_protocol(protocol, url)
	return protocol.."://"..url
end

function curl.check_url_protocol(protocol, url, alt)
	local specifiedProtocol = curl.get_protocol(url)

	if not specifiedProtocol then
		return curl.use_protocol(protocol, url)
	else
		if specifiedProtocol == protocol then return url
		elseif alt then
			if type(alt) == "string" then
				if alt == specifiedProtocol then return url end
			else
				for i = 1, #alt do
					if alt[i] == specifiedProtocol then return url end
				end
			end
		end

		error("unallowed protocol specified: "..specifiedProtocol)
	end
end

return curl