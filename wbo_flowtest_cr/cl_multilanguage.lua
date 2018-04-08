availableLangs = { 
	{ "English", "en" },
	{ "Русский", "ru" }
}
local actualLang = 1
local translations = { }
local bindedGui = { }

local TransMT = {
	__concat = function ( op1, op2 )
		op1._concatStr = tostring ( op2 )
		return op1
	end,
	__index = {
		get = function ( self )
			return self [ actualLang ] or "no-text"
		end
	}
}

--[[
	Возвращает строку перевода.
]]
function _L ( lname )
	local trans = translations [ lname ]
	if trans then
		return trans [ actualLang ] or "no-text"
	end
	
	return "no-trans"
end

--[[
	Возвращает таблицу перевода. Если ее нет, тогда создает ее.
]]
function _LD ( lname )
	local trans = translations [ lname ]
	if trans == nil then
		trans = setmetatable ( { }, TransMT )
		translations [ lname ] = trans
	end

	return trans
end

function setActualLang ( index )
	local lang = availableLangs [ index ]
	if lang then
		actualLang = index
		
		for gui, trans in pairs ( bindedGui ) do
			guiSetText ( gui, trans [ actualLang ] or "no-text" )
		end
	end
end

function getLStr ( trans )
	if type ( trans ) == "table" then
		local str = tostring ( trans [ actualLang ] )
		if trans._concatStr then str = str .. trans._concatStr end
		return tostring ( str )
	end
	
	return tostring ( trans )
end

function bindGui ( lname, guielement )
	local trans = translations [ lname ]
	if trans then
		bindedGui [ guielement ] = lname
	end
end

function loadTranslations ( filename )
	local xmlfile = xmlLoadFile ( filename )
	if xmlfile then
		local strings = xmlNodeGetChildren ( xmlfile )
		for _, strNode in ipairs ( strings ) do
			local strName = xmlNodeGetAttribute ( strNode, "name" )
			local trans = translations [ strName ]
			if trans == nil then
				trans = setmetatable ( { }, TransMT )
				translations [ strName ] = trans
			end
			
			for i, lang in ipairs ( availableLangs ) do
				local lstr = xmlNodeGetAttribute ( strNode, lang [ 2 ] )
				trans [ i ] = lstr or ""
			end
		end
	end
end

--[[
	Wrappers
]]
local _outputChatBox = outputChatBox
function outputChatBox ( text, r, g, b, colorCoded )
	_outputChatBox ( getLStr ( text ), r, g, b, colorCoded )
end

--[[
	GUI Wrappers
]]
local _guiSetText = guiSetText
function guiSetText ( guiElement, text )
	if isElement ( guiElement ) then
		return _guiSetText ( guiElement, getLStr ( text ) )
	end
end

local _guiCreateButton = guiCreateButton
function guiCreateButton ( x, y, width, height, text, relative, parent )
	local btn = _guiCreateButton ( x, y, width, height, getLStr ( text ), relative, parent )
	if type ( text ) == "table" then bindedGui [ btn ] = text end;
	return btn
end

local _guiCreateTab = guiCreateTab
function guiCreateTab ( text, parent )
	local tab = _guiCreateTab ( getLStr ( text ), parent )
	if type ( text ) == "table" then bindedGui [ tab ] = text end;
	return tab
end

local _guiCreateLabel = guiCreateLabel
function guiCreateLabel ( x, y, width, height, text, relative, parent )
	local lbl = _guiCreateLabel ( x, y, width, height, getLStr ( text ), relative, parent )
	if type ( text ) == "table" then bindedGui [ lbl ] = text end;
	return lbl
end

local _guiCreateCheckBox = guiCreateCheckBox
function guiCreateCheckBox ( x, y, width, height, text, selected, relative, parent )
	local cb = _guiCreateCheckBox ( x, y, width, height, getLStr ( text ), selected, relative, parent )
	if type ( text ) == "table" then bindedGui [ cb ] = text end;
	return cb
end