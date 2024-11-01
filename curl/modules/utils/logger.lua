local logger = {
	levels = {
		info = 'I',
		warn = 'W',
		error = 'E',
		fatal = 'F'
	}
}

local DEBUG = true

local prefixLength = 20

for level, char in pairs(logger.levels) do
	logger[level] =
	function(self, ...)
		logger.log(self, char, ...)
	end
end

function logger:create(group)
	if #group > prefixLength then error("max group length is "..prefixLength) end	

	local o = { }

	local prefix = group

	for i = 1, prefixLength - #group do
		prefix = ' '..prefix
	end

	o.prefix = prefix

	self.__index = self

	setmetatable(o, self)

	return o
end

function logger:debug(...)
	if DEBUG then self:log('D', ...) end
end

function logger:log(level, ...)
	local msg = ""

	local tbl = { ... }

	if #tbl == 1 then
		msg = tostring(tbl[1])
	elseif #tbl > 0 then
		for i = 1, #tbl do
			msg = msg..tostring(tbl[i])..' '
		end
	end

	print('['..level..'] XXXX/XX/XX XX:XX:XX.XXX+XXXX ['..self.prefix..'] '..msg)
end

return logger