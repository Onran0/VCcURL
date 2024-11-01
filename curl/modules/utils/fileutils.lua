local fileutils = { }

local tempDir = "export:curl/internal/temp"

local nextTempFileId = -1

local initialized

function fileutils.initialize()
	if initialized then return end

	if file.exists(tempDir) and #file.list(tempDir) ~= 0 then file.remove_tree(tempDir) end

	file.mkdirs(tempDir)

	initialized = true
end

function fileutils.get_temp_file(dir)
	dir = dir or tempDir

	nextTempFileId = nextTempFileId + 1

	local tmpName = nextTempFileId..".tmp"

	return dir.."/"..tmpName, tmpName
end

function fileutils.get_file_name(path)
	local lastSlash = -1
	local colon = -1

	for i = 1, #path do
		local char = path:sub(i, i)

		if char == '/' or char == '\\' then
			lastSlash = i
		elseif char == ':' and colon == -1 then
			colon = i
		end
	end

	if lastSlash == -1 then
		if colon == -1 then
			return path
		else
			return path:sub(colon + 1, #path)
		end
	else
		return path:sub(lastSlash + 1, #path)
	end
end

return fileutils