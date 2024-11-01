local comber = { }

comber.octals = "01234567"
comber.hex = "0123456789abcdefABCDEF"

function comber.char_at(str, i)
	return str:sub(i, i)
end

function comber.get_utf(cp)
      if cp < 128 then
          return string.char(cp)
      end

      local s = ""
      local prefix_max = 32
      
      while true do
          local suffix = cp % 64
          s = string.char(128 + suffix)..s
          cp = (cp - suffix) / 64

          if cp < prefix_max then
              return string.char((256 - (2 * prefix_max)) + cp)..s
          end

          prefix_max = prefix_max / 2
      end
end

function comber.comb(text, syntaxEscapes)
		return comber.replace_escapes(text, syntaxEscapes)
end

function comber.replace_escapes(text, syntaxEscapes)
	return comber.replace_unicode_escapes(
						comber.replace_syntax_escapes(
								comber.replace_octal_escapes(text), syntaxEscapes
						)
					)
end

function comber.replace_syntax_escapes(text, syntaxEscapes)
	if not syntaxEscapes or syntaxEscapes == "" then return text end

	local res = ""

	local i = 1

	local textlen = #text

	while i <= textlen do
	    local char, nextChar = comber.char_at(text, i), comber.char_at(text, i + 1)

	    if char == '\\' and syntaxEscapes:find(nextChar) then
	    		res = res..nextChar
	    		i = i + 1
	    else res = res..char end

	    i = i + 1
	end

	return res
end

function comber.replace_octal_escapes(text)
		local res = ""

		local i = 1

		local textlen = #text

		while i <= textlen do
		    local char = comber.char_at(text, i)

		    if char == '\\' then
		    		local isEscape = true

		        local octal = ""

		        for j = 1, 3 do
		        		local char = comber.char_at(text, i + j)

		        		if not comber.octals:find(char) then
		        			isEscape = false
		        			break
		        		end

		           	octal = octal..char
		        end

		        if isEscape then
				        i = i + 3

				        res = res..string.char(tonumber(octal, 8))
		        else
		        		res = res..'\\'
		        end
		    else res = res..char end

		    i = i + 1
		end

		return res
end

function comber.replace_unicode_escapes(text)
	local res = ""

	local i = 1

	local textlen = #text

	while i <= textlen do
	    local char = comber.char_at(text, i)

	    if char == '\\' and comber.char_at(text, i + 1) == 'u' then
	    		local isEscape = true

	        local codepoint = ""

	        for j = 1, 4 do
	        		local char = comber.char_at(text, i + j + 1)

	        		if not comber.hex:find(char) then
	        				isEscape = false
	        				break
	        		end

	           	codepoint = codepoint..char
	        end

	        if isEscape then
			        i = i + 5

			        res = res..comber.get_utf(tonumber(codepoint, 16))
		      else
		      		res = res.."\\"
		      end
	    else res = res..char end

	    i = i + 1
	end

	return res
end

return comber