local comber = require "curl:utils/combers/comber"

local json_comber = { }

local syntaxEscapes = "'"

function json_comber.comb(text)
		return json_comber.remove_null_values(comber.comb(text, syntaxEscapes))
end

function json_comber.remove_null_values(dirtyJson)
		local res = ""

		local keyLength = 0

		local textlen = #dirtyJson

		local i = 1

		local parsingKey

		local appendChar = true

		local inQuotes = false

		local ignoreComma

		while i <= textlen do
				local char = comber.char_at(dirtyJson, i)

				if char == ',' and ignoreComma then ignoreComma = false
				else res = res..char end

				if char == '"' and comber.char_at(dirtyJson, i - 1) ~= '\\' then inQuotes = not inQuotes
				elseif not inQuotes and res:ends_with("null") then
						local j = #res - 4
						local inQuotes = false
						local lengthWithQuotes
						local commaIndex
						local lengthToClear = 4

						while j > 0 do
								local char = comber.char_at(res, j)

								lengthToClear = lengthToClear + 1

								if not lengthWithQuotes then
									if char == '"' then
											if inQuotes then
													lengthWithQuotes = lengthToClear
											else
													inQuotes = true
											end
									end
								elseif char == '{' then break
								elseif char == ',' then
										commaIndex = j
										break
								end

								j = j - 1
						end

						if not commaIndex then
								lengthToClear = lengthWithQuotes

								local singleElement = false

								local len = #dirtyJson - #res
								local j = 1

								while j < len do
										local char = comber.char_at(dirtyJson, j + i)

										if char == '}' or char == ']' then
												singleElement = true
												break
										elseif char == ',' then
												break
										end

										j = j + 1
								end

								if not singleElement then
										ignoreComma = true
								end
						end

						res = res:sub(1, #res - lengthToClear)
				end

				i = i + 1
		end

		return res
end

return json_comber