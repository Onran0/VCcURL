local logger = require "curl:utils/logger":create("curl/http")

local curl = require "curl:curl"
local content_types = require "curl:utils/content_types"
local fileutils = require "curl:utils/fileutils"

local HTTP_HEAD = "HEAD"
local HTTP_GET = "GET"
local HTTP_POST = "POST"
local HTTP_PUT = "PUT"
local HTTP_DELETE = "DELETE"

local HTTP_INFO = "info"
local HTTP_SUCCESS = "success"
local HTTP_REDIRECTION = "redirection"
local HTTP_CLIENT_ERROR = "client error"
local HTTP_SERVER_ERROR = "server error"

local maxRedirectionsCount = 5

local textFormsCharactersLimit = 50

local tempDirIPCRelative = "../temp"

local httpFilesDir = "export:curl/internal/ipc/http"
local headersDir = httpFilesDir.."/headers"

local headersDirIPCRelative = "http/headers"

local http = { }

http.methods =
{
	head = HTTP_HEAD,
	get = HTTP_GET,
	post = HTTP_POST,
	put = HTTP_PUT,
	delete = HTTP_DELETE
}

http.statuses =
{
	[1] = HTTP_INFO,
	[2] = HTTP_SUCCESS,
	[3] = HTTP_REDIRECTION,
	[4] = HTTP_CLIENT_ERROR,
	[5] = HTTP_SERVER_ERROR
}

local IMPL_TOO_MANY_REDIRECTIONS_ERROR = "too many redirects"
local IMPL_TOO_MANY_REDIRECTIONS_ERROR_CODE = 1

http.errors =
{
	[IMPL_TOO_MANY_REDIRECTIONS_ERROR_CODE] = IMPL_TOO_MANY_REDIRECTIONS_ERROR
}

http.async = { }

local initialized
local curl_execute, curl_delete

function http.initialize(_curl_execute, _curl_delete)
	if initialized then return end

	curl_execute, curl_delete = _curl_execute, _curl_delete

	if file.exists(httpFilesDir) and #file.list(httpFilesDir) ~= 0 then file.remove_tree(httpFilesDir) end

	file.mkdirs(httpFilesDir)
	file.mkdirs(headersDir)

	initialized = true

	logger:info("http protocol initialized")
end

local function checkForProgramApi()
	if not curl.has_program_api() then error "program API is missing. HTTP protocol cannot be used" end
end

local function copyDataToTempFile(data, dataType, serialized)
	if data then
		if not content_types.has_content_type(dataType) then error "invalid data type" end

		local tmpPath, tmpName = fileutils.get_temp_file()

		if serialized then (content_types.is_text_format(dataType) and file.write or file.write_bytes)(serialized)
		else content_types.write_to_file(dataType, tmpPath, data) end

		return tmpPath, tmpName
	end
end

local function headersTableToString(headersTable)
	local headersStr = ""

	if headersTable then
		for k, v in pairs(headersTable) do
			headersStr = headersStr..'--header "'..k..': '..v..'" '
		end
	end

	return headersStr
end

local function formsTableToString(formsTable, tmpFiles)
	local formsStr = ""

	if formsTable then
		for i = 1, #formsTable do
			local formValue = ""

			local form = formsTable[i]

			if form.content then
				local contentType = form.type or "text"

				local needWriteToFile, serialized

				if content_types.is_text_format(contentType) then
					serialized = content_types.serialize(contentType, form.content)

					if serialized:sub(1, 1) == '@' then error "serialized text starts with '@'" end

					if #serialized < textFormsCharactersLimit then formValue = serialized
					else needWriteToFile = true end
				else needWriteToFile = true end

				if needWriteToFile then
					local tmpPath, tmpName = copyDataToTempFile(form.content, contentType, serialized)

					table.insert(tmpFiles, { tmpPath, tmpName })

					formValue = '@'..tempDirIPCRelative..'/'..tmpName
				end
			end

			formsStr = formsStr..'--form "'..form.name..'='..formValue..'" '
		end
	end

	return formsStr
end

local function parsePair(line)
	local indexOfSeparator = string.find(line, ':')

	if indexOfSeparator then
		return line:sub(1, indexOfSeparator - 1), line:sub(indexOfSeparator + 2)
	end
end

local function parseResponseHeadData(rawHead)
	local head = { headers = { } }

	local isFirstLine = true

	for line in rawHead:gmatch("[^\r\n]+") do
        if isFirstLine then
        	isFirstLine = false

        	local params = string.split(line, " ")
        	local version = string.split(params[1], "/")[2]
        	local majorResponseCode = tonumber(params[2]:sub(1, 1))
        	local responseCode = tonumber(params[2])
        	local responseCodeDesc = ""

        	if #params > 2 then
	        	for i = 3, #params do
	        		responseCodeDesc = responseCodeDesc..params[i].." "
	        	end

	        	responseCodeDesc = responseCodeDesc:sub(1, #responseCodeDesc - 1)
        	end

        	head.status = http.statuses[majorResponseCode]
        	head.version = version
        	head.major_response_code = majorResponseCode
        	head.response_code = responseCode
        	head.response_code_description = responseCodeDesc
        else
        	local key, value = parsePair(line)

        	if key and value then head.headers[string.lower(key)] = value end
       	end
    end

    return head
end

function http.async.head(url, params)
	checkForProgramApi()

	local sourceResponseHandler = params.responseHandler

	if sourceResponseHandler then
		params.responseHandler =
		function(content, head, implError)
			sourceResponseHandler(head, content, implError)
		end
	end

	return http.async.request(HTTP_HEAD, url, params)
end

function http.async.get(url, params)
	return http.async.request(HTTP_GET, url, params)
end

function http.async.post(url, params)
	return http.async.request(HTTP_POST, url, params)
end

function http.async.put(url, params)
	return http.async.request(HTTP_PUT, url, params)
end

function http.async.delete(url, params)
	return http.async.request(HTTP_DELETE, url, params)
end

function http.async.request(
	method, url, params
	--[[
	parameters:
	body, bodyType, forms, headers,
	responseHandler, responseType, autoRedirect,
	redirectionsCount, maxRedirectionsCount, secured
	--]]
)
	checkForProgramApi()

	if method then method = string.upper(method) end

	url = curl.check_url_protocol(params.secured and "https" or "http", url, params.secured and "http" or "https")

	local tmpFiles = { }

	local formsStr = formsTableToString(params.forms, tmpFiles)

	params.responseType = params.responseType or "text"

	if not content_types.has_content_type(params.responseType) then error "invalid response type" end

	if params.body then
		params.bodyType = params.bodyType or 'binary'

		if not content_types.has_content_type(params.bodyType) then error "invalid body type" end

		local tmpPath, tmpName = copyDataToTempFile(params.body, params.bodyType)

		table.insert(tmpFiles, { tmpPath, tmpName })
	end

	local tempHeaderPath, tempHeaderName = fileutils.get_temp_file(headersDir)

	local tempHeaderIPCRelativePath = headersDirIPCRelative.."/"..tempHeaderName

	local requestId

	curl_execute(
		function(receivedContentPath)
			for i = 1, #tmpFiles do
				local tmp = tmpFiles[i]

				if not pcall(file.remove, tmp[1]) then
					curl_delete(tempDirIPCRelative..'/'..tmp[2])
				end
			end

			local rawHead = file.read(tempHeaderPath)

			curl_delete(tempHeaderIPCRelativePath)

			local status, head = pcall(parseResponseHeadData, rawHead)

			if not status then
				logger:error("failed to parse response head: "..head)
				head = nil
			elseif params.autoRedirect and head.status == HTTP_REDIRECTION then
				if not params.redirectionsCount then
					params.redirectionsCount = (params.maxRedirectionsCount or maxRedirectionsCount) - 1
				else
					params.redirectionsCount = params.redirectionsCount - 1
				end

				if params.redirectionsCount == 0 then
					logger:error("too many redirections. last url: "..url)

					local status, error = pcall(params.responseHandler, nil, nil, IMPL_TOO_MANY_REDIRECTIONS_ERROR_CODE)

					if not status then logger:error("error in response handler:", error) end
				else
					logger.info("redirecting from "..url.."to"..head.headers.location)
					http.async.request(method, head.headers.location, params)
				end

				return
			end

			if params.responseHandler then
				local content

				if params.responseType then
					local status, res = pcall(content_types.read_from_file, params.responseType, receivedContentPath)

					if not status then logger:info("failed to read content: "..res)
					else content = res end
				end

				params.responseHandler(content, head)
			end
		end,
		function(requestPath, rawResponsePath, rawResponsesDirName, _requestId)
			requestId = _requestId

			local curlCommand =
			'--dump-header "'..tempHeaderIPCRelativePath..'" "'..url..'" --request "'..method..'" '..
			headersTableToString(params.headers)..formsStr..
			'--output "'..rawResponsesDirName..'/'..
			requestId..'"'

			if params.body then
				curlCommand = curlCommand.." --data"

				if content_types.is_binary_format(params.bodyType) then curlCommand = curlCommand.."-binary"
				else curlCommand = curlCommand..'-raw' end

				curlCommand = curlCommand..' "'..tempDirIPCRelative.."/"..tmpName..'"'
			end

			if method == HTTP_HEAD then
				curlCommand = curlCommand.." --head"
			end

			return curlCommand
		end
	)

	logger:debug(method.." request created to url ", url, " with request id ", requestId)

	return requestId
end

function http.head(url, params)
	checkForProgramApi()

	local content, head, implError = http.request(HTTP_HEAD, url, params)

	return head, implError, content
end

function http.get(url, params)
	return http.request(HTTP_GET, url, params)
end

function http.post(url, params)
	return http.request(HTTP_POST, url, params)
end

function http.put(url, params)
	return http.request(HTTP_PUT, url, params)
end

function http.delete(url, params)
	return http.request(HTTP_DELETE, url, params)
end

function http.request(method, url, params)
	checkForProgramApi()

	local isResponseReceived, content, head, implError

	params.responseHandler =
	function(_content, _head, _implError)
		isResponseReceived = true
		content = _content
		head = _head
		implError = _implError
	end

	http.async.request(method, url, params)

	while not isResponseReceived do coroutine.yield() end

	return content, head, implError
end

return http