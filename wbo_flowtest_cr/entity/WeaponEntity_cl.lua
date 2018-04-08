WeaponEntity = GameEntity.create ( )
WeaponEntity.wrapper = true

function WeaponEntity.streamIn ( element )
	WeaponEntity:addElement ( element )

	if WeaponEntity.refs == 1 then
		WeaponEntity.texture = dxCreateTexture ( "images/VisualBudgetSystemAnalyzeOne.png" )
		addEventHandler ( "onClientPreRender", root, WeaponEntity.update, false )
		
		outputDebugString ( "WeaponEntity: update created" )
	end
end

function WeaponEntity.streamOut ( element )
	WeaponEntity:removeElement ( element )
	
	if WeaponEntity.refs == 0 then
		removeEventHandler ( "onClientPreRender", root, WeaponEntity.update )
		destroyElement ( WeaponEntity.texture )
		outputDebugString ( "WeaponEntity: update removed" )
	end
end

function WeaponEntity.collisionTest ( element, lineStart, lineEnd )
	local x, y, z = getElementPosition ( element )

	local weapon = getElementChild ( element, 0 )
	if weapon and getElementType ( weapon ) == "weapon" then
		x, y, z = getElementPosition ( weapon )
	end

	local collision = collisionTest.Sphere ( lineStart, lineEnd, Vector3D:new ( x, y, z ), 0.25 )
	
	if collision then return element, collision end;
end

function WeaponEntity.update ( )
	if Editor.started and getSettingByID ( "s_emode" ):getData ( ) ~= true then
		return
	end
	
	for s_weapon, _ in pairs ( WeaponEntity.elements ) do
		local x, y, z = getElementPosition ( s_weapon )
		local weapon = getElementChild ( s_weapon, 0 )
		if isElement ( weapon ) and getElementType ( weapon ) == "weapon" then
			x, y, z = getElementPosition ( weapon )
		end
	
		dxDrawMaterialLine3D ( x, y, z + 0.125, x, y, z - 0.125, WeaponEntity.texture, 0.25, color.white )
	end
end

--[[
	Weapon management
]]
local weaponsBind = { }

local onWeaponDestroy = function ( )
	WeaponEntity.streamOut ( source )
	weaponsBind [ source ] = nil
end
local onWeaponStreamIn = function ( )
	local s_weapon = getElementParent ( source )
	WeaponEntity.streamIn ( s_weapon )
end
local onWeaponStreamOut = function ( )
	local s_weapon = getElementParent ( source )
	WeaponEntity.streamOut ( s_weapon )
end

function _createWeapon ( s_weapon )
	if weaponsBind [ s_weapon ] then
		outputDebugString ( "TCT: Оружие для этого элемента уже создано", 3 )
		return
	end

	local weaponType = getElementData ( s_weapon, "type", false )
	local x, y, z = getFormattedElementData ( s_weapon, "posX", "posY", "posZ", "number", false )
	local rx, ry, rz = getFormattedElementData ( s_weapon, "rotX", "rotY", "rotZ", "number", false )
	local dimension = getElementData ( s_weapon, "dimension", false )
	
	if x and rz then
		local weapon = createWeapon ( weaponType, x, y, z )
		setElementRotation ( weapon, rx, ry, rz )
		setElementParent ( weapon, s_weapon )
		setElementDimension ( weapon, tonumber ( dimension ) or 0 )
		addEventHandler ( "onClientElementDestroy", s_weapon, onWeaponDestroy, false )
		addEventHandler ( "onClientElementStreamIn", weapon, onWeaponStreamIn, false )
		addEventHandler ( "onClientElementStreamOut", weapon, onWeaponStreamOut, false )
		
		WeaponEntity.streamIn ( s_weapon )
		weaponsBind [ s_weapon ] = weapon
		
		
		local attachTo = getElementData ( s_weapon, "attachTo", false )
		if type ( attachTo ) == "string" then
			attachTo = getElementByID ( attachTo )
			if attachTo then
				local offX = getElementData ( s_weapon, "attachX", false )
				local offY = getElementData ( s_weapon, "attachY", false )
				local offZ = getElementData ( s_weapon, "attachZ", false )
				
				local offRZ = getElementData ( s_weapon, "attachRZ", false )
			
				attachElements ( weapon, attachTo, offX or 0, offY or 0, offZ or 0, 0, 0, offRZ or 0 )
			end
		end
	end
end

function _setWeaponState ( s_weapon, state )
	local weapon = weaponsBind [ s_weapon ]
	if weapon then
		setWeaponState ( weapon, state )
	end
end

function _setWeaponTarget ( s_weapon, element )
	local weapon = weaponsBind [ s_weapon ]
	if weapon and isElement ( element ) then
		setWeaponTarget ( weapon, element )
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local weapons = getElementsByType ( "s_weapon", resourceRoot )
		for i = 1, #weapons do
			_createWeapon ( weapons [ i ] )
		end
	end
, false )

addEvent ( "onClientCustomAttach", true )
addEventHandler ( "onClientCustomAttach", resourceRoot,
	function ( attachTo, offx, offy, offz, offrz )
		local weapon = getElementChild ( source, 0 )
		if weapon and getElementType ( weapon ) == "weapon" then
			attachElements ( weapon, attachTo, offx, offy, offz, 0, 0, offrz )
		end
	end
)

-- При создании нового оружия на стороне сервера
addEvent ( "_e" .. g_EventBase.WEAPON, true )
addEventHandler ( "_e" .. g_EventBase.WEAPON, resourceRoot,
	function ( eventType, arg )
		-- Create weapon
		if eventType == 0 then
			_createWeapon ( source )
			
		-- State
		elseif eventType == 1 then
			_setWeaponState ( source, arg )
		
		-- Target
		elseif eventType == 2 then
			_setWeaponTarget ( source, arg )
		end
	end
)