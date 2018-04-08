function math.clamp ( lower, value, upper )
	return math.max ( math.min ( value, upper ), lower )
end

function math.lerp(a, b, k)
	return a * (1-k) + b * k
end

function setVector3HP ( vector, h, p )
	local ch, cp, sh, sp = math.cos ( h ), math.cos ( p ), math.sin ( h ), math.sin ( p )
	vector.x = -cp*sh
	vector.y = sp
	vector.z = cp*ch
end

function Vector4:lerp ( A, B, t )
	local x, y, z = interpolateBetween ( A.x, A.y, A.z, B.x, B.y, B.z, t, "Linear" )
	self.x = x; self.y = y; self.z = z;
	self.w = math.lerp ( A.w, B.w, t )
end

function Vector3:lerp ( A, B, t )
	local x, y, z = interpolateBetween ( A.x, A.y, A.z, B.x, B.y, B.z, t, "Linear" )
	self.x = x; self.y = y; self.z = z;
end

function Vector2:lerp ( A, B, t )
	local x, y = interpolateBetween ( A.x, A.y, 0, B.x, B.y, 0, t, "Linear" )
	self.x = x; self.y = y
end

--[[
	xrSection
]]
xrSection = {
	new = function ( name, gameVer )
		local section = {
			ver = gameVer,
			name = name,
			items = { }
		}
		
		return setmetatable ( section, xrSectionMT )
	end,
	insertItem = function ( self, key, value )
		if value == nil then
			table.insert ( self.items, key )
		else
			self.items [ key ] = value
		end
	end,
	inheritItems = function ( self, inheritFrom )
		for key, value in pairs ( inheritFrom.items ) do
			self.items [ key ] = value
		end
	end,
	readString = function ( self, key )
		return self.items [ key ]
	end,
	readNumber = function ( self, key )
		return tonumber ( self.items [ key ] )
	end,
	readVector2 = function ( self, key )
		local value = self.items [ key ]
		if value then
			local first = tonumber ( gettok ( value, 1, "," ) )
			local second = tonumber ( gettok ( value, 2, "," ) )
			if first and second then
				return Vector2 ( first, second )
			end
		end
	end,
	readVector3 = function ( self, key )
		local value = self.items [ key ]
		if value then
			local first = tonumber ( gettok ( value, 1, "," ) )
			local second = tonumber ( gettok ( value, 2, "," ) )
			local third = tonumber ( gettok ( value, 3, "," ) )
			if first and second and third then
				return Vector3 ( first, second, third )
			end
		end
	end,
	readVector4 = function ( self, key )
		local value = self.items [ key ]
		if value then
			local first = tonumber ( gettok ( value, 1, "," ) )
			local second = tonumber ( gettok ( value, 2, "," ) )
			local third = tonumber ( gettok ( value, 3, "," ) )
			local fourth = tonumber ( gettok ( value, 4, "," ) )
			if first and second and third then
				return Vector4 ( first, second, third, fourth )
			end
		end
	end
}
xrSectionMT = { __index = xrSection }

--[[
	xrSettings
]]
xrSettings = { }
xrSettingsMT = { __index = xrSettings }

function xrSettings.new ( filename )
	local ini = {
		sections = { }
	}
	
	-- Парсим базовый файл system.ltx
	if fileExists ( filename ) then
		local file = fileOpen ( filename, true )
		setmetatable ( ini, xrSettingsMT ):load ( file, filename )
		fileClose ( file )
		
		return ini
	end
end

-- Функция ищет двойные кавычки и удаляет их
local function _parse ( str )
	if str:sub ( 1, 1 ) == '"' then
		local endPos = str:find ( '"', 2 )
		if endPos then
			return str:sub ( 2, endPos - 1 )
		else
			outputDebugString ( "Обнаружена незавершенная строка: " .. str, 2 )
			return str:sub ( 2, str:len ( ) )
		end
	end
	return str
end
function xrSettings:load ( file, filename )
	local str = fileRead ( file, fileGetSize ( file ) )
	local lines = split ( str, "\n" )
	local current
	local gameVer = "soc"
	for _, line in ipairs ( lines ) do
		line = line:gsub ( ";.*$", "" ) -- Удалим комментарии
		line = line:gsub ( "//.*$", "" ) -- Удалим комментарии
		local trimmed = line:gsub ( "%s+", "" ) -- Удаляем все пробелы
		local trimmedLen = trimmed:len ( )
		if trimmedLen > 0 then
			local ch = trimmed:sub ( 1, 1 )
			if ch == "#" then
				if trimmed:find ( "#include" ) == 1 then
					local includeName = _parse ( trimmed:sub ( 9, trimmedLen ) )
					local path = string.match ( filename , "(.-)([^\\]-([^%.]+))$" )
					local includePath = path .. includeName
					if fileExists ( includePath ) then
						local file = fileOpen ( includePath, true )
						self:load ( file, includePath )
						fileClose ( file )
					else
						outputDebugString ( "Файл для внедрения не был найден: " .. includePath, 2 )
					end
				elseif trimmed:find ( "#game_ver" ) then
					local verName = _parse ( trimmed:sub ( 10, trimmedLen ) )
					gameVer = verName
				end
			elseif ch == "[" then
				local endPos = trimmed:find ( "]" )
				if endPos then
					local secName = trimmed:sub ( 2, endPos - 1 )
					if self.sections [ secName ] == nil then
						current = xrSection.new ( secName, gameVer )
						self.sections [ secName ] = current
					
						-- Если у секции есть наследование
						if endPos + 1 < trimmedLen and trimmed:sub ( endPos + 1, endPos + 1 ) == ":" then
							local inheritedNames = split ( trimmed:sub ( endPos + 2, trimmedLen ), "," )
							for _, name in ipairs ( inheritedNames ) do
								local inheritedSection = self.sections [ name ]
								if inheritedSection then
									current:inheritItems ( inheritedSection )
								else
									outputDebugString ( "Не была найдена секция для наследование: " .. name, 2 )
								end
							end
						end
					else
						outputDebugString ( "Обнаружен дубликат секции " .. secName .. "!", 2 )
					end
				else
					outputDebugString ( "Обнаружена незавершенная секция: " .. trimmed, 2 )
				end
			else
				-- Если мы вошли в секцию
				if current then
					local key = gettok ( trimmed, 1, "=" )
					local value = gettok ( trimmed, 2, "=" )
					if key and value then
						current:insertItem ( key, _parse ( value ) )
					else
						current:insertItem ( trimmed )
					end
				end
			end
		end
	end
end

--[[
	Utils
]]
-- Возвращает текущее игровое время в секундах
function getEnvironmentGameDayTimeSec ( timeFactor )
	return math.floor ( ( getTickCount ( ) * timeFactor ) % 86400000 / 1000 )
end