sw, sh = guiGetScreenSize ( )

g_EventBase = {
	WEAPON = 1
}

color = { 
	green = tocolor ( 0, 255, 0, 230 ),
	orangeLight = tocolor ( 255, 187, 0, 100 ),
	red = tocolor ( 255, 0, 0, 230 ),
	blue = tocolor ( 0, 0, 255, 230 ),
	text = tocolor ( 240, 248, 255, 240 ),
	black = tocolor ( 0, 0, 0, 255 ),
	white = tocolor ( 255, 255, 255, 255 ),
	aqua = tocolor ( 0, 255, 255, 255 ),
	background = tocolor ( 0, 0, 0, 200 ),
	selected = tocolor ( 70, 140, 30, 150 ),
}

function table.removevalue(t, val)
	for i,v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function math.lerp ( from, alpha, to )
    return from + ( to - from ) * alpha
end

function math.unlerp ( from, pos, to )
	if to == from then
		return 1
	end
	return ( pos - from ) / ( to - from )
end

function math.clamp ( low, value, high )
    return math.max ( low, math.min ( value, high ) )
end

function math.unlerpclamped ( from, pos, to )
	return math.clamp ( 0, math.unlerp ( from, pos, to ), 1 )
end

function math.round ( number, decimals, method )
    decimals = decimals or 0
    local factor = 10 ^ decimals
	
    if method == "ceil" or method == "floor" then 
		return math [ method ] ( number * factor ) / factor
    else 
		return tonumber ( ( "%." .. decimals .. "f" ):format ( number ) ) 
	end
end

function realToGui ( tlo, thi, value, bInt )
	local pos = math.unlerpclamped ( tlo, value, thi )
	local tvalue = math.lerp ( 0, pos, 100 )
	
	if bInt then
		tvalue = math.floor ( tvalue + 0.5 )
	end
	
	return tvalue
end

function guiToReal ( tlo, thi, value, bInt )
	local pos = math.unlerpclamped ( 0, value, 100 )
	local tvalue = math.lerp( tlo, pos, thi )

	if bInt then
		tvalue = math.floor ( tvalue + 0.5 )
	end
	
	return tvalue
end

function findRotation(x1,y1,x2,y2) 
  local t = -math.deg(math.atan2(x2-x1,y2-y1))
  if t < 0 then t = t + 360 end;
  return t; 
end

function getWorldCursorPosition ( )
	if isCursorShowing ( ) then
		local screenx, screeny, worldx, worldy, worldz = getCursorPosition ( )
		local px, py, pz = getCameraMatrix ( )
		local hit, x, y, z, elementHit = processLineOfSight ( px, py, pz, worldx, worldy, worldz )
 
		if hit then
			return x, y, z, elementHit
		end
	end
end

function getRotateValue ( value )
	value = tonumber ( value )
	
	if value > 0 and value < 45 then
		value = 45
	elseif value > 46 and value < 90 then
		value = 90
	elseif value > 91 and value < 135 then
		value = 135
	elseif value > 136 and value < 180 then
		value = 180
	elseif value > 181 and value < 225 then
		value = 225
	elseif value > 226 and value < 270 then
		value = 270
	elseif value > 271 and value < 315 then
		value = 315
	elseif value > 316 and value < 360 then
		value = 360
	end
		
	return value
end

function getPositionOnMap ( posX, posY )
	local minX, minY, maxX, maxY = getPlayerMapBoundingBox ( )
	local sizeX = maxX - minX
	local sizeY = maxY - minY
	sizeX = sizeX / 6000
	sizeY = sizeY / 6000
	local mapX = posX + 3000
	local mapY = posY + 3000
	mapX = mapX * sizeX + minX
	mapY = maxY - mapY * sizeY
	
	return mapX - 0.5, mapY - 0.5
end

--[[
addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		loadTranslations ( "conf/translations.xml" )
		
		EntitySnap.loadModelsFromXml ( "conf/snapmodels.xml" )
		
		setTimer ( ModelReplacer.replace, 1000, 1, 1 )
		
		server = createServerCallInterface ( )
	end 
)]]

function getElementResourceName ( element )
	if isElement ( element ) then
		local parent = getElementParent ( element )
		while getElementType ( parent ) ~= "resource" do
			parent = getElementParent ( parent )
		end
		
		return getElementID ( parent )
	end
end

bindedGridLists = { }

g_ModelLookupTypes = { }

function loadList ( file )
	local xml = getResourceConfig ( file )
	
	if xml then
		local result = { }
		local _test = { }
		
		for i, groupNode in pairs ( xmlNodeGetChildren ( xml ) ) do
			local group = { 
				name = xmlNodeGetAttribute ( groupNode, "name" )
			}
			
			for _, childNode in pairs ( xmlNodeGetChildren ( groupNode ) ) do
				local child = { 
					name = xmlNodeGetAttribute ( childNode, "name" ),
					model = xmlNodeGetAttribute ( childNode, "model" )
				}
				
				table.insert ( group, child )
			end
			
			table.insert ( result, group )
		end
		
		xmlUnloadFile ( xml )
		
		return result
	end
end

function guiGridListLoadTable ( gridlist, tbl, fn )
	bindedGridLists [ gridlist ] = tbl
	
	updateGridList ( gridlist, true )
	
	addEventHandler ( "onClientGUIClick", gridlist,
		function ( )
			local selectedRow = guiGridListGetSelectedItem ( source )
			
			if selectedRow > -1 then
				local name = guiGridListGetItemText ( source, selectedRow, 1 )
				
				if name == "..." then
					updateGridList ( source, true )
				else
					if guiGridListGetItemText ( source, 0, 1 ) ~= "..." then
						updateGridList ( source, false, selectedRow + 1, guiGridListGetItemData ( gridlist, selectedRow, 1 ) )
					else
						local model = guiGridListGetItemData ( source, selectedRow, 1 )
						fn ( source, model )
					end
				end
			end
		end
	, false )
end

function updateGridList ( gridlist, isGroup, index, extra )
	guiGridListClear ( gridlist )
	
	if isGroup then
		for _, group in ipairs ( bindedGridLists [ gridlist ] ) do
			guiGridListSetItemText ( gridlist, guiGridListAddRow ( gridlist ), 1, group.name, false, false )
		end
		
		-- Ищем модели в данных типов
		local resourceNames = { }
		for elementType, _ in pairs ( g_ModelLookupTypes ) do
			for _, element in ipairs ( getElementsByType ( elementType ) ) do
				if getElementData ( element, "model", false ) ~= false then
					local resName = getElementResourceName ( element )
					if resourceNames [ resName ] == nil then
						resourceNames [ resName ] = true
						
						local row = guiGridListAddRow ( gridlist )
						guiGridListSetItemText ( gridlist, row, 1, resName, false, false )
						guiGridListSetItemData ( gridlist, row, 1, resName )
					end
				end
			end
		end
	else
		if index then
			local row = guiGridListAddRow ( gridlist )
			guiGridListSetItemText ( gridlist, row, 1, "...", false, false )
			guiGridListSetItemColor ( gridlist, row, 1, 238, 216, 174, 255 )
			
			-- Если нам нужно показать найденные модели
			if extra then
				local unknownCounter = 0
				for elementType, _ in pairs ( g_ModelLookupTypes ) do
					for _, element in ipairs ( getElementsByType ( elementType, extra ) ) do
						local model = tonumber (
							getElementData ( element, "model", false )
						)
						if model ~= nil then
							local name = getElementData ( element, "name", false )
							if type ( name ) ~= "string" then
								unknownCounter = unknownCounter + 1
								name = "Unknown " .. unknownCounter
							end
							
							local row = guiGridListAddRow ( gridlist )
							guiGridListSetItemText ( gridlist, row, 1, name, false, false )
							guiGridListSetItemData ( gridlist, row, 1, tostring ( model ) )
						end
					end
				end
			else
				for _, child in ipairs ( bindedGridLists [ gridlist ] [ index ] ) do
					local row = guiGridListAddRow ( gridlist )
					guiGridListSetItemText ( gridlist, row, 1, child.name, false, false )
					guiGridListSetItemData ( gridlist, row, 1, child.model )
				end
			end
		end
	end
end

addEventHandler ( "onClientElementDestroy", root, 
	function ( )
		local elementType = getElementType ( source )
		if ( elementType == "object" or elementType == "vehicle" ) and isElementLocal ( source ) then
			for _, element in ipairs ( getAttachedElements ( source ) ) do
				if isElement ( element ) then
					destroyElement ( element )
				end
			end
		end
	end
)

function getPedWorldTarget ( )
	local tx, ty, tz = getPedTargetEnd ( localPlayer )
		
	if tx then
		local sx, sy, sz = getCameraMatrix ( )
		local _, _, _, _, _, _, _, _, _, _, _, worldModelID = processLineOfSight ( sx, sy, sz, tx, ty, tz, true, false, false, false, false, true, false, true, localPlayer, true )
			
		if worldModelID then
			return worldModelID
		end
	end
end

function getElementPositionByOffset ( element, xOffset, yOffset, zOffset )
	local matrix = getElementMatrix ( element )
	if not matrix then
		local x, y, z = getElementPosition ( element )
		local rx, ry, rz = getElementRotation ( element )
	
		matrix = getMatrix ( x, y, z, rx, ry, rz )
	end
	
	return getMatrixOffset ( matrix, xOffset, yOffset, zOffset )
end

function isPointInBox ( px, py, bx, by, bwidth, bheight )
	return ( px > bx and px < bx + bwidth ) and ( py > by and py < by + bheight )
end

--[[
rox,roy,roz = ray start point
rdx,rdy,rdz = ray destination point

bminx,bminy,bminz = box min corner
bmaxx,bmaxy,bmaxz = box max corner
]]

function raybox ( rox, roy, roz, rdx, rdy, rdz, bminx, bminy, bminz, bmaxx, bmaxy, bmaxz )
	local txmin,txmax,tymin,tymax

	local ddx = 1/(rox-rdx)
	local ddy = 1/(roy-rdy)

	if ddx >= 0 then
		txmin = (bminx - rox) * ddx
		txmax = (bmaxx - rox) * ddx
	else
		txmin = (bmaxx - rox) * ddx
		txmax = (bminx - rox) * ddx
	end
 
	if ddy >= 0 then
		tymin = (bminy - roy) * ddy
		tymax = (bmaxy - roy) * ddy
	else
		tymin = (bmaxy - roy) * ddy
		tymax = (bminy - roy) * ddy
	end

	if ( (txmin > tymax) or (tymin > txmax) ) then return false end
	
	if (tymin > txmin) then txmin = tymin end
	if (tymax < txmax) then txmax = tymax end

	local tzmin,tzmax
	local ddz = 1/(roz-rdz)

	if ddz >= 0 then
		tzmin = (bminz - roz) * ddz
		tzmax = (bmaxz - roz) * ddz
	else
		tzmin = (bmaxz - roz) * ddz
		tzmax = (bminz - roz) * ddz
	end

	if (txmin > tzmax) or (tzmin > txmax) then return false end

	return true
end

local letters = { "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" }
local numbers = { "0","1","2","3","4","5","6","7","8","9" }
 
local function generateLetter ( upper )
    if upper then 
		return letters [ math.random ( #letters ) ]:upper ( ) 
	end
	
    return letters [ math.random ( #letters ) ]
end
 
local function generateNumber ( ) 
	return tostring ( math.random ( 0, 9 ) )
end

function generateString ( length )
    if not length or type ( length ) ~= "number" or math.ceil ( length ) < 2 then 
		return false 
	end
	
    local result = ""
	
    for i = 1, math.ceil ( length ) do
		local upper = math.random ( 2 ) == 1 and true or false
		result = result .. ( math.random ( 2 ) == 1 and generateLetter ( upper ) or generateNumber ( ) )
    end
	
    return tostring ( result )
end

function createElementID ( element )
	local elementID = getElementID ( element )
	local isIDNew = false
	
	if elementID == "" then
		elementID = generateString ( 10 )

		setElementID ( element, elementID )
		setElementData ( element, "id", elementID )
  
		isIDNew = true
	end
	
	return elementID, isIDNew
end

function resAdjust(num)
	if not g_ScreenWidth then
		g_ScreenWidth, g_ScreenHeight = guiGetScreenSize()
	end
	if g_ScreenWidth < 1280 then
		return math.floor(num*g_ScreenWidth/1280)
	else
		return num
	end
end

function string:split(sep)
	if #self == 0 then
		return {}
	end
	sep = sep or ' '
	local result = {}
	local from = 1
	local to
	repeat
		to = self:find(sep, from, true) or (#self + 1)
		result[#result+1] = self:sub(from, to - 1)
		from = to + 1
	until from == #self + 2
	return result
end

function table.each(t, index, callback, ...)
	local args = { ... }
	if type(index) == 'function' then
		table.insert(args, 1, callback)
		callback = index
		index = false
	end
	for k,v in pairs(t) do
		callback(index and v[index] or v, unpack(args))
	end
	return t
end

function table.find(t, ...)
	local args = { ... }
	if #args == 0 then
		for k,v in pairs(t) do
			if v then
				return k
			end
		end
		return false
	end
	
	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k,v in pairs(t) do
		for i,index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			return k
		end
	end
	return false
end

function createServerCallInterface()
	return setmetatable(
		{},
		{
			__index = function(t, k)
				t[k] = function(...) triggerServerEvent('onServerCall', localPlayer, k, ...) end
				return t[k]
			end
		}
	)
end

addEvent('onClientCall', true)
addEventHandler('onClientCall', resourceRoot,
	function(fnName, ...)
		local fn = _G
		local path = fnName:split('.')
		for i,pathpart in ipairs(path) do
			fn = fn[pathpart]
		end
        if not fn then
            outputDebugString( 'onClientCall fn is nil for ' .. tostring(fnName) )
        else
    		fn(...)
        end
	end
)

function Vector2D ( x, y )
	return {
		x = x,
		y = y
	}
end

local _getElementDimension = getElementDimension
function getElementDimension ( element )
	local dimension = tonumber ( getElementData ( element, "dimension", false ) ) or _getElementDimension ( element )
	
	return dimension
end

-- Wrappers
local _setElementPosition = setElementPosition

local MTAEntityTypes = {
	[ "player" ] = true, [ "ped" ] = true, [ "vehicle" ] = true, [ "object" ] = true, [ "pickup" ] = true, [ "marker" ] = true
}

setElementPosition = function ( element, x, y, z )
	_setElementPosition ( element, x, y, z )
	
	-- Если это МТА объект выходим из функции
	if MTAEntityTypes [ getElementType ( element ) ] then
		return 
	end
	
	GameManager.onElementChangePosition ( element )
end

local _getElementPosition = getElementPosition

getElementPosition = function ( element )
	local x, y, z = _getElementPosition ( element )
	
	if x ~= false then
		return x, y, z
	end
	
	-- В противном случае читаем ее из данных
	x = getElementData ( element, "posX", false )
	y = getElementData ( element, "posY", false )
	z = getElementData ( element, "posZ", false )
	
	return tonumber ( x ), tonumber ( y ), tonumber ( z )
end

function getMatrix(posX, posY, posZ, rotX, rotY, rotZ)
	local rx, ry, rz = math.rad(rotX), math.rad(rotY), math.rad(rotZ)
	local matrix = {}
	matrix[1] = {}
	matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][3] = -math.cos(rx)*math.sin(ry)
	matrix[1][4] = 1
 
	matrix[2] = {}
	matrix[2][1] = -math.cos(rx)*math.sin(rz)
	matrix[2][2] = math.cos(rz)*math.cos(rx)
	matrix[2][3] = math.sin(rx)
	matrix[2][4] = 1
 
	matrix[3] = {}
	matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
	matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
	matrix[3][3] = math.cos(rx)*math.cos(ry)
	matrix[3][4] = 1
 
	matrix[4] = {}
	matrix[4][1], matrix[4][2], matrix[4][3], matrix[4][4] = posX, posY, posZ, 1 -- this is kinda useless but is used to have the same structure as getElementMatrix
 
	return matrix
end

function getMatrixOffset ( matrix, xOffset, yOffset, zOffset )
	local pX = xOffset * matrix [ 1 ] [ 1 ] + yOffset * matrix [ 2 ] [ 1 ] + zOffset * matrix [ 3 ] [ 1 ] + matrix [ 4 ] [ 1 ]
	local pY = xOffset * matrix [ 1 ] [ 2 ] + yOffset * matrix [ 2 ] [ 2 ] + zOffset * matrix [ 3 ] [ 2 ] + matrix [ 4 ] [ 2 ]
	local pZ = xOffset * matrix [ 1 ] [ 3 ] + yOffset * matrix [ 2 ] [ 3 ] + zOffset * matrix [ 3 ] [ 3 ] + matrix [ 4 ] [ 3 ]
	
	return pX, pY, pZ
end

function getPointFromDistanceRotation(x, y, dist, angle)
    local a = math.rad(90 - angle)
	
    local dx = math.cos(a) * dist
    local dy = math.sin(a) * dist
 
    return x+dx, y+dy 
end

function getEulerAnglesFromMatrix(x1,y1,z1,x2,y2,z2,x3,y3,z3)
	local nz1,nz2,nz3
	nz3 = math.sqrt(x2*x2+y2*y2)
	nz1 = -x2*z2/nz3
	nz2 = -y2*z2/nz3
	local vx = nz1*x1+nz2*y1+nz3*z1
	local vz = nz1*x3+nz2*y3+nz3*z3
	return math.deg(math.asin(z2)),-math.deg(math.atan2(vx,vz)),-math.deg(math.atan2(x2,y2))
end

function math.round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end

----------------------------------
-- Model replace
----------------------------------
ModelReplacer = { }

local engineTextures = {
	mah_industri3_new = "mah_industri3_new.txd"
}

local engineModels = {
	--Стены
	{ 1799, "mah_industri3_new", "garel_grgedoor_new.dff" },
	{ 2118, "mah_industri3_new", "AZS_door2.dff" },
	{ 3037, "mah_industri3_new", "warehouse_door2b_new.dff" },
	{ 1717, "mah_industri3_new", "REMDOOR_new.dff" },
	{ 4374, "mah_industri3_new", "arzgrgedoor_spr3_new.dff" }
}

function ModelReplacer.replace ( step )
	--toolMaterial.loadMaterial ( )
	--if true then return end

	if step == 1 then
		--Сначала загружаем текстуры
		for name, filename in pairs ( engineTextures ) do
			engineTextures [ name ] = engineLoadTXD ( "models/" .. filename )
		end
		
		setTimer ( ModelReplacer.replace, 500, 1, step + 1 )
		
		outputDebugString ( "WBO: Текстуры успешно загружены" )
	elseif step == 2 then
		--Затем грузим модели
		for _, model in ipairs ( engineModels ) do
			engineImportTXD ( engineTextures [ model [ 2 ] ], model [ 1 ] )
	
			local dff = engineLoadDFF ( "models/" .. model [ 3 ], model [ 1 ] )
			engineReplaceModel ( dff, model [ 1 ] )
		end
		
		--Загружаем и применяем материалы
		--initClientMaterials ( )
		--loadMaterials ( )
		
		--Загружаем и применяем слои
		--toolLayer.loadLayers ( )
		
		outputDebugString ( "WBO: Материалы успешно загружены и применены" )
	end
end

--[[
	Key delayed
]]
local keyBinds = { 

}

function bindKeyDelay ( key, time, handlerFunction, ... )
	if keyBinds [ key ] == nil then
		keyBinds [ key ] = {
			time = time,
			fn = handlerFunction,
			args = { ... }
		}
		bindKey ( key, "both", _onKey )
	end
end

function unbindKeyDelay ( key )
	local bind = keyBinds [ key ]
	if bind then
		unbindKey ( key, "both", _onKey )
		if isTimer ( bind.timer ) then
			killTimer ( bind.timer )
		end
	end
	keyBinds [ key ] = nil
end

function _onKey ( key, keyState )
	local bind = keyBinds [ key ]
	if bind then
		if keyState == "down" then
			bind.timer = setTimer ( _onKeyDelay, bind.time, 1, key )
		elseif keyState == "up" then
			if isTimer ( bind.timer ) then
				killTimer ( bind.timer )
				bind.fn ( key, false, unpack ( bind.args ) )
			end
		end
	end
end

function _onKeyDelay ( key )
	local bind = keyBinds [ key ]
	if bind then
		bind.fn ( key, true, unpack ( bind.args ) )
	end
end






TraderUI = { }

function TraderUI.create ( price )
	if TraderUI.visible then return end;
	
	TraderUI.price = price
	addEventHandler ( "onClientRender", root, TraderUI.onRender, false, "low" )
	addEventHandler ( "onClientKey", root, TraderUI.onKey, false, "low" )
	
	TraderUI.visible = true
end

function TraderUI.destroy ( )
	if TraderUI.visible then
		removeEventHandler ( "onClientRender", root, TraderUI.onRender )
		removeEventHandler ( "onClientKey", root, TraderUI.onKey )
		
		TraderUI.visible = nil
	end
end

function TraderUI.onRender ( )
	local width, height = 300, 130
	local x, y = sw/2 - width/2, sh/2 - height/2
	
	local now = getTickCount ( )
	if TraderUI.subTicks then
		if now - TraderUI.subTicks > 500 then TraderUI.price = math.max ( TraderUI.price - 2, 0 ) end;
	elseif TraderUI.addTicks then
		if now - TraderUI.addTicks > 500 then TraderUI.price = TraderUI.price + 2 end;
	end
	
	dxDrawRectangle ( x, y, width, height, tocolor ( 0, 0, 0, 200 ) )
	dxDrawText ( "Продать на сумму", x, y + 10, x + width, 100, tocolor ( 255, 255, 255, 255 ), 1.2, "default", "center", "top", false, true )
	dxDrawText ( TraderUI.price .. "$", x, y + 40, x + width, 100, tocolor ( 255, 255, 255, 255 ), 1.2, "beckett", "center", "top", false, true )
	local priceStrWidth = dxGetTextWidth ( TraderUI.price .. "$", 1.2, "beckett" )/2
	
	local btnsize = 30
	local btnx, btny = x + (width/2) - priceStrWidth - btnsize - 5, y + 40
	dxDrawRectangle ( btnx, btny, btnsize, btnsize, tocolor ( 27, 224, 86, 150 ) )
	dxDrawText ( "-", btnx, btny, btnx + btnsize, btny + btnsize, tocolor ( 255, 255, 255, 255 ), 1.2, "default", "center", "center", false, true )
	btnx = x + (width/2) + priceStrWidth + 5
	dxDrawRectangle ( btnx, btny, btnsize, btnsize, tocolor ( 224, 86, 27, 150 ) )
	dxDrawText ( "+", btnx, btny, btnx + btnsize, btny + btnsize, tocolor ( 255, 255, 255, 255 ), 1.2, "default", "center", "center", false, true )
	
	dxDrawText ( TraderUI.price > 0 and "Выставлено на продажу" or "Не продается", x, y + 90, x + width, 10, tocolor ( 255, 255, 255, 255 ), 1.3, "default", "center", "top", false, true )
end

function TraderUI.onKey ( button, press )
	if button == "mouse1" then
		if press then
			TraderUI.price = math.max ( TraderUI.price - 1, 0 )
			TraderUI.subTicks = getTickCount ( )
		else
			TraderUI.subTicks = nil
		end
	elseif button == "mouse2" then
		if press then
			TraderUI.price = TraderUI.price + 1
			TraderUI.addTicks = getTickCount ( )
		else
			TraderUI.addTicks = nil
		end
	end
end

function guiGetRealPosition ( guielement )
	local x, y = guiGetPosition ( guielement, false )
	local parent = getElementParent ( guielement )
	
	while getElementType ( parent ) ~= "guiroot" do
		local rx, ry = guiGetPosition ( parent, false )
		x, y = x + rx, y + ry
		parent = getElementParent ( parent )
	end
	
	return x, y
end

local _guiGetVisible = guiGetVisible
function guiGetVisible ( guielement )
	if getElementType ( guielement ) == "gui-tab" then
		local tabpanel = getElementParent ( guielement )
		return guiGetSelectedTab ( tabpanel ) == guielement and _guiGetVisible ( guielement )
	end
	
	return _guiGetVisible ( guielement )
end

SAMenu = { 
	scale = 1,
	font = "pricedown",
	color = tocolor ( 210, 210, 210, 255 ),
	selectedColor = tocolor ( 10, 10, 200, 255 )
}

function SAMenu.create ( items, name, callbackFn, keep )
	if SAMenu.visible then return end;
	SAMenu.visible = true
	
	table.insert ( items, "Exit" )
	
	SAMenu.width = 40 + dxGetTextWidth ( tostring ( name ), 1.3, "beckett" )
	for _, item in ipairs ( items ) do
		SAMenu.width = math.max ( dxGetTextWidth ( tostring ( item ), SAMenu.scale, SAMenu.font ) + 40, SAMenu.width )
	end
	SAMenu.itemHeight = dxGetFontHeight ( SAMenu.scale, SAMenu.font )
	SAMenu.height = 40 + SAMenu.itemHeight * #items
	
	SAMenu.x = 30
	SAMenu.y = sh / 2 - SAMenu.height / 2
	
	SAMenu.items = items
	SAMenu.name = tostring ( name )
	SAMenu.selectedItem = 1
	SAMenu.fn = callbackFn
	SAMenu.keep = keep == true
	
	addEventHandler ( "onClientRender", root, SAMenu.onRender, false )
	addEventHandler ( "onClientKey", root, SAMenu.onKey, false )
end

function SAMenu.destroy ( )
	if SAMenu.visible then
		SAMenu.visible = nil
		SAMenu.items = nil
		
		removeEventHandler ( "onClientRender", root, SAMenu.onRender )
		removeEventHandler ( "onClientKey", root, SAMenu.onKey )
	end
end

function SAMenu.onRender ( )
	local self = SAMenu

	dxDrawRectangle ( self.x, self.y, self.width, self.height, tocolor ( 0, 0, 0, 200 ) )
	local nameHeight = dxGetFontHeight ( 1.3, "beckett" ) / 2
	dxDrawText ( self.name, self.x, self.y - nameHeight, self.x + self.width, 0, self.color, 1.3, "diploma", "center", "top" )
	
	for i, item in ipairs ( SAMenu.items ) do
		local _y = self.y + 20 + ( self.itemHeight * ( i - 1 ) )
		
		local color = i == self.selectedItem and self.selectedColor or self.color
		dxDrawText ( item, self.x + 20, _y, 0, _y + self.itemHeight, color, 
                  self.scale, self.font, "left", "center" )
	end
end

function SAMenu.onKey ( button, press )
	if press then
		if button == "mouse_wheel_up" then
			SAMenu.selectedItem = math.max ( SAMenu.selectedItem - 1, 1 )
		elseif button == "mouse_wheel_down" then
			SAMenu.selectedItem = math.min ( SAMenu.selectedItem + 1, #SAMenu.items )
		elseif button == "mouse1" then
			SAMenu.fn ( SAMenu.selectedItem < #SAMenu.items and SAMenu.selectedItem or 0 )
			if SAMenu.selectedItem == #SAMenu.items or SAMenu.keep ~= true then
				SAMenu.destroy ( )
			end
		end
	end
end

function getFormattedElementData ( element, ... )
	local args = { ... }
	local argsNum = #args
	local formatFn = tostring
	local result = { }
	
	local inherit = true
	if type ( args [ argsNum ] ) == "boolean" then
		inherit = args [ argsNum ]
		argsNum = argsNum - 1
	end

	local formatStr = args [ argsNum ]
	if formatStr == "number" then
		formatStr = tonumber
	end
	
	for i = 1, argsNum-1 do
		local key = args [ i ]
		if type ( key ) == "string" then
			result [ i ] = formatFn ( getElementData ( element, key, inherit ) )
		else
			return
		end
	end
	
	return unpack ( result )
end






--[[
	DXDialog(можно заменить GameDialog)
]]
DXDialog = { 
	itemHeight = 35
}

function DXDialog.create ( data, callbackFn, ... )
	if DXDialog.visible then
		return
	end

	DXDialog.data = data
	DXDialog.callback = callbackFn
	DXDialog.callbackData = { ... }
	
	DXDialog.width = dxGetTextWidth ( getLStr ( data.label ), 1.2, "default" )
	for _, item in ipairs ( data.items ) do
		DXDialog.width = math.max ( DXDialog.width, dxGetTextWidth ( getLStr ( item ), 1.2, "default" ) )
	end
	DXDialog.width = DXDialog.width + 40
	
	local textHeight = dxGetFontHeight ( 1.2, "default" )
	DXDialog.height = textHeight + DXDialog.itemHeight*#data.items + 40
	
	DXDialog.x = sw / 2 - DXDialog.width / 2
	DXDialog.y = sh / 2 - DXDialog.height / 2
	
	DXDialog.selectedItem = 1
	DXDialog.visible = true 
	
	addEventHandler ( "onClientRender", root, DXDialog.onRender, false )
	addEventHandler ( "onClientKey", root, DXDialog.onKey, false )
end

function DXDialog.destroy ( )
	if DXDialog.visible then
		removeEventHandler ( "onClientRender", root, DXDialog.onRender )
		removeEventHandler ( "onClientKey", root, DXDialog.onKey )
		
		DXDialog.data = nil
		DXDialog.callback = nil
		DXDialog.visible = nil
	end
end

function DXDialog.onRender ( )
	local self = DXDialog
	local data = self.data
	local y = self.y
	
	dxDrawRectangle ( self.x, y, self.width, self.height, tocolor ( 0, 0, 0, 200 ), true )
	y = y + 5
	dxDrawText ( getLStr ( data.label ), self.x, y, self.x + self.width, 100, tocolor ( 255, 255, 255, 255 ), 1.2, "clear", "center", "top", false, true, true )
	
	y = y + dxGetFontHeight ( 1.2, "default" )*2
	for i, item in ipairs ( data.items ) do
		local _y = y + ( self.itemHeight * ( i - 1 ) )
		
		if i == self.selectedItem then
			dxDrawRectangle ( self.x + 10, _y, self.width - 20, self.itemHeight, tocolor ( 27, 224, 86, 150 ), true )
		end
		dxDrawText ( getLStr ( item ), self.x, _y, self.x + self.width, _y + self.itemHeight, tocolor ( 200, 200, 200, 255 ), 1.2, "default", "center", "center", false, true, true )
	end
end

function DXDialog.onKey ( button, pressed )
	if pressed then
		local self = DXDialog
		if button == "mouse_wheel_up" then
			self.selectedItem = math.max ( self.selectedItem - 1, 1 )
		elseif button == "mouse_wheel_down" then
			local items = self.data.items
			self.selectedItem = math.min ( self.selectedItem + 1, #items )
		elseif button == "mouse1" then
			self.callback ( self.selectedItem, unpack ( self.callbackData ) )
			self.destroy ( )
		end
	end
end


--[[
	GameDialog
]]
GameDialog = { }
local _itemKeys = {
	"A", "B", "C", "D", "E", "F"
}
local _keyIndices = {
	[ "a" ] = 1, [ "b" ] = 2, [ "c" ] = 3, [ "d" ] = 4, [ "e" ] = 5, [ "f" ] = 6
}

function GameDialog.create ( items, text, callback )
	if GameDialog.visible ~= nil then return end;
	
	GameDialog.items = items
	GameDialog.text = text
	GameDialog.callback = callback
	GameDialog.selectedItem = 1
	
	addEventHandler ( "onClientRender", root, GameDialog.onRender, false, "low" )
	addEventHandler ( "onClientKey", root, GameDialog.onKey, false, "low" )
	
	toggleAllControls ( false, true, false )
	
	GameDialog.visible = true
end

function GameDialog.destroy ( )
	if GameDialog.visible ~= nil then
		removeEventHandler ( "onClientRender", root, GameDialog.onRender )
		removeEventHandler ( "onClientKey", root, GameDialog.onKey )
	
		toggleAllControls ( true, true, false )
	end
	GameDialog.visible = nil
end

function GameDialog.onRender ( )
	local btnwidth, btnheight = 135, 40
	local btnbias = 10

	local width, height = ( ( btnwidth + btnbias ) * #GameDialog.items ) + btnbias, 130
	local x, y = sw/2 - width/2, sh/2 - height/2
	
	dxDrawRectangle ( x, y, width, height, tocolor ( 0, 0, 0, 200 ) )
	dxDrawText ( GameDialog.text, x + btnbias, y + btnbias, x + width - btnbias*2, 100, tocolor ( 255, 255, 255, 255 ), 1.2, "default", "center", "top", false, true )
	
	local btnx, btny = x + btnbias, y + height - btnheight - btnbias
	
	for i, item in ipairs ( GameDialog.items ) do
		local _x = btnx + ( ( btnwidth+btnbias ) * ( i-1 ) )
		local _color = i == GameDialog.selectedItem and tocolor ( 255, 142, 20, 150 ) or tocolor ( 27, 224, 86, 150 )
		dxDrawRectangle ( _x, btny, btnwidth, btnheight, _color )
		dxDrawText ( item .. " [" .. _itemKeys [ i ] .. "]", _x, btny, _x + btnwidth, btny + btnheight, tocolor ( 255, 255, 255, 255 ), 1.2, "default", "center", "center", false, true )
	end
end

function GameDialog.onKey ( button, press )
	if press ~= true then return end;
	
	local keyIndex = _keyIndices [ button ]
	if keyIndex then
		if GameDialog.items [ keyIndex ] ~= nil then
			GameDialog.callback ( keyIndex )
			GameDialog.destroy ( )
		end
	end
	
	if button == "mouse_wheel_up" then
		GameDialog.selectedItem = math.min ( GameDialog.selectedItem + 1, #GameDialog.items )
	elseif button == "mouse_wheel_down" then
		GameDialog.selectedItem = math.max ( GameDialog.selectedItem - 1, 1 )
	end
	
	if button == "mouse1" then
		GameDialog.callback ( GameDialog.selectedItem )
		GameDialog.destroy ( )
	elseif button == "mouse2" then
		GameDialog.destroy ( )
	end
end

--[[
	Some stuff
]]
local _showCursor = showCursor
function showCursor ( show, forcibly )
	if forcibly ~= true and show ~= true then
		local windows = getElementsByType ( "gui-window", resourceRoot )
		if #windows > 0 then
			for _, wnd in ipairs ( windows ) do
				if guiGetVisible ( wnd ) then
					return
				end
			end
		end
	end
	
	return _showCursor ( show )
end

local pedAnimation = { }
local streamedIn = { }
addEvent ( "PedAnimStart", true )
addEventHandler ( "PedAnimStart", resourceRoot,
	function ( data )
		pedAnimation [ source ] = data
		setPedAnimation ( source, data [ 1 ], data [ 2 ], 1, true, true, true, true )
		
		if isElementStreamedIn ( source ) then
			table.insert ( streamedIn, source )
		end
	end
)

addEventHandler ( "onClientRender", root,
	function ( )
		if #streamedIn < 1 then
			return
		end
		
		for _, ped in ipairs ( streamedIn ) do
			local animData = pedAnimation [ ped ]
			if animData then
				
			end
		end
	end
, false )

--[[
	Выравнивание педа относительно родительского объекта(только если пед прикреплен)
]]
--[[local adjustPeds = { }
local adjustStreamedInPeds = { }

local _adjustPed = function ( ped, attachedTo )
	local adjustValue = adjustPeds [ ped ]
	if adjustValue then
		local _, _, rot = getElementRotation ( attachedTo )
		setElementRotation ( ped, 0, 0, rot + adjustValue )
	end
end
local onAdjustUpdate = function ( )
	for i = 1, #adjustStreamedInPeds do
		local ped = adjustStreamedInPeds [ i ]
		local attachedTo = getElementAttachedTo ( ped )
		if attachedTo then
			_adjustPed ( ped, attachedTo )
		else
			adjustPeds [ ped ] = nil
			table.remove ( adjustStreamedInPeds, i )
			if #adjustStreamedInPeds == 0 then
				removeEventHandler ( "onClientPreRender", root, onAdjustUpdate )
				
				outputDebugString ( "TCT: Ped adjust update removed" )
			end
		end
	end
end
addEventHandler ( "onClientElementStreamIn", resourceRoot,
	function ( )
		if adjustPeds [ source ] then
			table.insert ( adjustStreamedInPeds, source )
			if #adjustStreamedInPeds == 1 then
				addEventHandler ( "onClientPreRender", root, onAdjustUpdate, false )
				
				outputDebugString ( "TCT: Ped adjust update added" )
			end
		end
	end
)
addEventHandler ( "onClientElementStreamOut", resourceRoot,
	function ( )
		if adjustPeds [ source ] then
			table.removevalue ( adjustStreamedInPeds, source )
			if #adjustStreamedInPeds == 0 then
				removeEventHandler ( "onClientPreRender", root, onAdjustUpdate )
				
				outputDebugString ( "TCT: Ped adjust update removed" )
			end
		end
	end
)

addEvent ( "onClientPedAdjust", true )
addEventHandler ( "onClientPedAdjust", root,
	function ( adjust )
		adjust = tonumber ( adjust )
		adjustPeds [ source ] = adjust
		
		if isElementStreamedIn ( source ) then
			if adjust ~= nil then
				table.insert ( adjustStreamedInPeds, source )
				if #adjustStreamedInPeds == 1 then
					addEventHandler ( "onClientPreRender", root, onAdjustUpdate, false )
					
					outputDebugString ( "TCT: Ped adjust update added" )
				end
			else
				table.removevalue ( adjustStreamedInPeds, source )
				if #adjustStreamedInPeds == 0 then
					removeEventHandler ( "onClientPreRender", root, onAdjustUpdate )
					
					outputDebugString ( "TCT: Ped adjust update removed" )
				end
			end
		end
	end
)]]




local vehicleIDS = { 602, 545, 496, 517, 401, 410, 518, 600, 527, 436, 589, 580, 419, 439, 533, 549, 526, 491, 474, 445, 467, 604, 426, 507, 547, 585,
405, 587, 409, 466, 550, 492, 566, 546, 540, 551, 421, 516, 529, 592, 553, 577, 488, 511, 497, 548, 563, 512, 476, 593, 447, 425, 519, 520, 460,
417, 469, 487, 513, 581, 510, 509, 522, 481, 461, 462, 448, 521, 468, 463, 586, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 485, 552, 431, 
438, 437, 574, 420, 525, 408, 416, 596, 433, 597, 427, 599, 490, 432, 528, 601, 407, 428, 544, 523, 470, 598, 499, 588, 609, 403, 498, 514, 524, 
423, 532, 414, 578, 443, 486, 515, 406, 531, 573, 456, 455, 459, 543, 422, 583, 482, 478, 605, 554, 530, 418, 572, 582, 413, 440, 536, 575, 534, 
567, 535, 576, 412, 402, 542, 603, 475, 449, 537, 538, 441, 464, 501, 465, 564, 568, 557, 424, 471, 504, 495, 457, 539, 483, 508, 571, 500, 
444, 556, 429, 411, 541, 559, 415, 561, 480, 560, 562, 506, 565, 451, 434, 558, 494, 555, 502, 477, 503, 579, 400, 404, 489, 505, 479, 442, 458, 
606, 607, 610, 590, 569, 611, 584, 608, 435, 450, 591, 594 }
function getModelType ( model )
	model = tonumber ( model )
	for _, vehmodel in ipairs ( vehicleIDS ) do
		if vehmodel == model then
			return "vehicle"
		end
	end
	local pedValidModels = getValidPedModels ( )
	for _, pedmodel in ipairs ( pedValidModels ) do
		if pedmodel == model then
			return "ped"
		end
	end
end


local modFileHandlers = { }
local loadedFiles = { }
addEvent ( "onModFileLoaded", false )
addEventHandler ( "onModFileLoaded", root,
	function ( type, id, name, checksum )
		id = tonumber ( id )
		local fn = modFileHandlers [ type ]
		if fn then
			fn ( type, id, name, checksum )
		end
		
		table.insert ( loadedFiles, {
			type = type, id = id,
			name = name, checksum = checksum
		} )
	end
, false )

addEvent ( "onClientPlayerRoomQuit", true )
addEventHandler ( "onClientPlayerRoomQuit", localPlayer,
	function ( room )
		loadedFiles = { }
	end
)

function addModFileHandler ( fn, ... )
	local args = { ... }
	for _, arg in ipairs ( args ) do
		modFileHandlers [ arg ] = fn
	end
end

function getLoadedFiles ( ... )
	local args = { ... }
	if #args > 0 then
		local _files = { }
		for _, arg in ipairs ( args ) do
			for _, file in ipairs ( loadedFiles ) do
				if file.type == arg then
 					table.insert ( _files, file )
				end
			end
		end
		return _files
	end
	return loadedFiles
end

function getFileByID ( id )
	id = tonumber ( id )
	for _, file in ipairs ( loadedFiles ) do
		if file.id == id then
			return file
		end
	end
end

-- Отменяем урон если стоит флаг
addEventHandler ( "onClientPlayerDamage", localPlayer,
	function ( )
		if getElementData ( source, "undam" ) == true then
			cancelEvent ( )
		end
	end
, false )