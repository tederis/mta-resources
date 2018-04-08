local sw, sh = guiGetScreenSize ( )

--[[
	xrMain
]]
controls = {
	armor = {
		x = 860, y = 590,
		width = 150, height = 64
	},
	health = {
		x = 860, y = 635,
		width = 150, height = 64
	},
	weapon = {
		x = 860, y = 685,
		width = 200, height = 64
	},
	map = {
		x = 9, y = 6,
		width = 177, height = 185
	},
	pager = {
		x = 1, y = 187,
		width = 200, height = 32
	},
	motion = {
		x = 0, y = 685,
		width = 64, height = 64
	},
	
	progressArmor = {
		x = 16, y = 23,
		width = 120, height = 18
	},
	progressHealth = {
		x = 16, y = 23,
		width = 120, height = 18
	}
}

local ui_frame_03 = {
	left_top = { "ui_frame_03/ui_frame_03_lt", width = 64, height = 64 },
	top = { "ui_frame_03/ui_frame_03_t", width = 128, height = 64 },
	right_top = { "ui_frame_03/ui_frame_03_rt", width = 64, height = 64 },
	left = { "ui_frame_03/ui_frame_03_l", width = 64, height = 128 },
	back = { "ui_frame_03/ui_frame_03_back", width = 64, height = 64 },
	right = { "ui_frame_03/ui_frame_03_r", width = 64, height = 128 },
	left_bottom = { "ui_frame_03/ui_frame_03_lb", width = 64, height = 64 },
	bottom = { "ui_frame_03/ui_frame_03_b", width = 128, height = 64 },
	right_bottom = { "ui_frame_03/ui_frame_03_rb", width = 64, height = 64 }
}

local function resizeControls ( width, height )
	local factor = sw / width
	local factor2 = sh / height
	
	g_FactorH = factor
	g_FactorV = factor2
	
	for _, control in pairs ( controls ) do
		if type ( control ) == "table" then
			control.x = control.x * factor
			control.y = control.y * factor2
		
			control.width = control.width * factor2
			control.height = control.height * factor2
		end
	end
end

local _text = function ( value )
	local str = xrSystem.getString ( value )
	if str then
		return str.lnrus
	else
		return value
	end
end

xrMain = { }

function xrMain.open ( )
	xrMain.font = dxCreateFont ( "AG Letterica Roman Medium.ttf", 18, true )
	xrMain.font2 = dxCreateFont ( "AG Letterica Roman Medium.ttf", 20, true )
	
	--[[g_Frame = UIFrame.new ( controls.dialogFrame.x, controls.dialogFrame.y, controls.dialogFrame.width, controls.dialogFrame.height, ui_frame_03 )
	g_Frame2 = UIFrame.new ( controls.ourPhrasesFrame.x, controls.ourPhrasesFrame.y, controls.ourPhrasesFrame.width, controls.ourPhrasesFrame.height, ui_frame_03 )]]

	xrMain.power = 1000
	
	addEventHandler ( "onClientRender", root, xrMain.onRender, false )
end

function xrMain.close ( )
	removeEventHandler ( "onClientRender", root, xrMain.onRender )
	
	destroyElement ( xrMain.font )
	destroyElement ( xrMain.font2 )
end

function findWeaponItem ( id )
	for _, item in pairs ( g_Items ) do
		if item.weapon == id then
			return item
		end
	end
end

function xrMain.onRender ( )
	local vx, vy, vz = getElementVelocity ( localPlayer )
	local force = (vx^2 + vy^2 + vz^2) ^ 0.1
	
	if force > 0 then
		if getControlState ( "sprint" ) then
			force = force * 4
		elseif getControlState ( "jump" ) then
			force = force * 80
		end
		
		xrMain.power = math.max ( xrMain.power - force, 0 )
	else
		xrMain.power = math.min ( xrMain.power + 2, 1000 )
	end
	
	local base = controls.armor
	dxDrawImageSection ( base.x + 50, base.y, base.width, base.height, 0, 0, 150, 64, "textures/ui_mn_health.dds" )
	local control = controls.progressArmor
	local armor = getPedArmor ( localPlayer )
	local progress = armor / 100
	local biasx, biasy = _scale ( 80, 5 )
	dxDrawText ( "armor", base.x + biasx, base.y + biasy )
	dxDrawImageSection ( base.x + 50 + control.x, base.y + control.y, control.width, control.height, 0, 0, 120, 18, "textures/ui_mg_progress_efficiency_empty.dds" )
	dxDrawImageSection ( 
		base.x + 50 + control.x + control.width, base.y + control.y, -(control.width * progress), control.height, 
		0, 0, 120, 18, "textures/ui_mg_progress_efficiency_full.dds",
		0, 0, 0, tocolor ( 0, 0, 255 ) 
	)

	base = controls.health
	dxDrawImageSection ( base.x + 50, base.y, base.width, base.height, 0, 0, 150, 64, "textures/ui_mn_health.dds" )
	control = controls.progressHealth
	local health = getElementHealth ( localPlayer )
	progress = health / 100
	biasx, biasy = _scale ( 80, 5 )
	dxDrawText ( "health", base.x + biasx, base.y + biasy )
	dxDrawImageSection ( base.x + 50 + control.x, base.y + control.y, control.width, control.height, 0, 0, 120, 18, "textures/ui_mg_progress_efficiency_empty.dds" )
	dxDrawImageSection ( 
		base.x + 50 + control.x + control.width, base.y + control.y, -(control.width * progress), control.height, 
		0, 0, 120, 18, "textures/ui_mg_progress_efficiency_full.dds",
		0, 0, 0, tocolor ( 255, 50, 50 ) 
	)
	
	base = controls.weapon
	dxDrawImageSection ( base.x + 50, base.y, base.width, base.height, 0, 0, 200, 64, "textures/ui_mn_weapons.dds" )
	local weapon = getPedWeapon ( localPlayer )
	local item = findWeaponItem ( weapon )
	if item then
		biasx, biasy = _scale ( 60, 4 )
		dxDrawText ( item.name, base.x + 50 + biasx, base.y + biasy )
		if item.ammo ~= nil and g_Items [ item.ammo ] then
			local ammo = g_Items [ item.ammo ]
			biasx, biasy = _scale ( 5, 12 )
			local width, height = _scale ( 100, 50 )
			dxDrawImageSection ( base.x + 50 + biasx, base.y + biasx, width, height, 50 * ammo.inv_grid_x, 50 * ammo.inv_grid_y, ammo.inv_grid_width * 50, ammo.inv_grid_height * 50, "textures/ui_icon_equipment.dds" )
		end
		
		biasx, biasy = _scale ( 82, 22 )
		local ammo = getPedAmmoInClip ( localPlayer )
		if ammo then
			dxDrawText ( ammo .. "/--", base.x + 50 + biasx, base.y + biasy, 0, 0, tocolor ( 238, 155, 23 ), 1, xrMain.font )
		end
	end
	
	
	base = controls.map
	dxDrawImageSection ( base.x, base.y, base.width, base.height, 0, 0, 177, 185, "textures/ui_mg_back_map.dds" )
	
	local _, bias = _scale ( 0, 150 )
	local width, height = _scale ( 32, 32 )
	local rot = getPedCameraRotation ( localPlayer )
	dxDrawImageSection ( bias, bias, width, height, 0, 0, 32, 32, "textures/ui_hud_map_arrow.dds", -rot )
	
	width, height = _scale ( 3, 3 )
	dxDrawImage ( base.x + base.width/2, base.y + base.height/2, width, height, "textures/hud_map_point.dds" )
	
	base = controls.pager
	dxDrawImageSection ( base.x, base.y, base.width, base.height, 0, 0, 200, 32, "textures/ui_mg_back_pager.dds" )
	
	base = controls.motion
	progress = xrMain.power / 1000
	local task = getPedTask ( localPlayer, "secondary", 1 )
	if task then
		dxDrawImageSection ( base.x, base.y, base.width, base.height, 128, 0, 64, 64, "textures/ui_motion_icon.dds" )
		dxDrawImageSection ( base.x, base.y + base.height, base.width, -(base.height*progress), 128, 0, 64, -64 * progress, "textures/ui_motion_icon.dds" )
	else
		dxDrawImageSection ( base.x, base.y, base.width, base.height, 0, 0, 64, 64, "textures/ui_motion_icon.dds" )
		dxDrawImageSection ( base.x, base.y + base.height, base.width, -(base.height*progress), 0, 0, 64, -64 * progress, "textures/ui_motion_icon.dds" )
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		resizeControls ( 1024, 768 )
		
		xrMain.open ( )
	end
, false )