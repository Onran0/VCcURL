local fileutils = require "curl:utils/fileutils"

local ipc = { }

setmetatable(ipc, ipc)

function ipc:new(ipcDir)
	local o = { }

    self.__index = self

    setmetatable(o, self)

    self.responsesDirName = "responses"
    self.requestsDirName = "requests"
    self.deleteDirName = "delete"
    self.rawResponsesDirName = "raw_responses"

	self.requestsDir = ipcDir..'/'..self.requestsDirName
	self.responsesDir = ipcDir..'/'..self.responsesDirName
	self.deleteDir = ipcDir..'/'..self.deleteDirName
	self.rawResponsesDir = ipcDir..'/'..self.rawResponsesDirName
	self.processedResponses = { }

	self.nextExecuteRequestId = -1
	self.nextDeleteRequestId = -1
	self.activeExecuteRequestsCount = 0

	self.responseHandlers = { }

	file.mkdirs(self.requestsDir)
	file.mkdirs(self.responsesDir)
	file.mkdirs(self.deleteDir)
	file.mkdirs(self.rawResponsesDir)

	return o
end

function ipc:process_responses()
	if self.activeExecuteRequestsCount == 0 then return end

	for _, responseFile in ipairs(file.list(self.responsesDir)) do
		if not self.processedResponses[responseFile] then
			local requestId = fileutils.get_file_name(responseFile)
			
			if file.isdir(responseFile) then
				print "what is the directory doing here?"
			else
				local handler = self.responseHandlers[requestId]

				if handler then
					local status, error = pcall(
						handler,
						responseFile
					)

					if error then print("failed to handle request with id " .. requestId .. ": ".. error) end

					self.responseHandlers[requestId] = nil
				end

				self.activeExecuteRequestsCount = self.activeExecuteRequestsCount - 1

				self.processedResponses[responseFile] = true
			end

			self:delete_request(self.responsesDirName.."/"..requestId)
		end
	end
end

function ipc:delete_request(relativePath)
	self.nextDeleteRequestId = self.nextDeleteRequestId + 1

	local requestId = tostring(self.nextDeleteRequestId)

	file.write(self.deleteDir.."/"..requestId, relativePath)

	return requestId
end

function ipc:execute_request(handler, commandProvider)
	self.nextExecuteRequestId = self.nextExecuteRequestId + 1

	local requestId = tostring(self.nextExecuteRequestId)

	if handler then self.responseHandlers[requestId] = handler end

	self.activeExecuteRequestsCount = self.activeExecuteRequestsCount + 1

	local requestPath = self.requestsDir .. '/' .. requestId

	local command

	if type(commandProvider) == "string" then
		command = commandProvider
	else
		command = commandProvider(
			requestPath,
			self.rawResponsesDir .. '/' .. requestId,
			self.rawResponsesDirName,
			requestId
		)
	end

	file.write(requestPath, command)

	return requestId
end

return ipc