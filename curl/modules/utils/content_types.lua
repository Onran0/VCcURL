local json_comber = require "curl:utils/combers/json_comber"
local comber = require "curl:utils/combers/comber"

local content_types = { }

local readers, writers, defProviders, textFormatFlags = { }, { }, { }, { }

local function checkContentType(id)
	if not content_types.has_content_type(id) then error 'unregistered content type' end
end

function content_types.has_content_type(id)
	return (readers[id] or writers[id] or defProviders[id]) ~= nil
end

function content_types.is_binary_format(id)
	return not content_types.is_text_format(id)
end

function content_types.is_text_format(id)
	return textFormatFlags[id]
end

function content_types.deserialize(id, data)
	checkContentType(id)

	return content_types.get_reader(id)(data)
end

function content_types.serialize(id, content)
	checkContentType(id)

	return content_types.get_writer(id)(content)
end

function content_types.read_from_file(id, path)
	checkContentType(id)

	if not file.exists(path) then end

	local readfn = content_types.is_text_format(id) and file.read or file.read_bytes

	return content_types.deserialize(id, readfn(path))
end

function content_types.write_to_file(id, path, content)
	checkContentType(id)

	local writefn = content_types.is_text_format(id) and file.write or file.write_bytes

	writefn(path, content_types.serialize(id, content))
end

function content_types.get_reader(id)
	return readers[id]
end

function content_types.get_writer(id)
	return writers[id]
end

function content_types.get_default_value_provider(id)
	return defProviders[id]
end

local function xReturn(x) return x end

function content_types.register_content_type(id, reader, writer, defProvider, isTextFormat)
	if content_types.has_content_type(id) then error("content type with id \""..id.."\" already registered") end

	readers[id], writers[id], defProviders[id], textFormatFlags[id] = reader or xReturn, writer or xReturn, defProvider, isTextFormat == true
end

content_types.register_content_type("text", nil, nil, function() return "" end, true)

content_types.register_content_type("binary", nil, nil, function() return { } end, false)

content_types.register_content_type(
	"json",
	function(text)
		return json.parse(text)
	end,
	function(table)
		return json.tostring(table)
	end,
	function() return { } end,
	true
)

content_types.register_content_type(
	"dirty_json",
	function(text)
		return json.parse(json_comber.comb(text))
	end,
	function(table)
		return json_comber.comb(json.tostring(table))
	end,
	function() return { } end,
	true
)

content_types.register_content_type(
	"toml",
	function(text)
		return toml.parse(text)
	end,
	function(table)
		return toml.tostring(table)
	end,
	function() return { } end,
	true
)

content_types.register_content_type(
	"dirty_toml",
	function(text)
		return toml.parse(comber.comb(text))
	end,
	function(table)
		return comber.comb(toml.tostring(table))
	end,
	function() return { } end,
	true
)

content_types.register_content_type(
	"vcbjson",
	function(bin)
		return bjson.frombytes(bin)
	end,
	function(table)
		return bjson.tobytes(table)
	end,
	function() return { } end,
	false
)

content_types.register_content_type(
	"file",
	file.read_bytes,
	file.read_bytes,
	function() return { } end,
	false
)

return content_types