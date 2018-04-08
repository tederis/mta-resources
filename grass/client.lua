local g_Obj
local g_Rt
xrElements = { }

local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3

function math.lerp(a, b, k)
	return a * (1-k) + b * k
end

PI_MUL_2 = 6.2831853071795864769252867665590

--[[
	xrSwingValue
]]
xrSwingValue = {
	new = function ( )
		local swing = {
			rot1 = 0,
			rot2 = 0,
			amp1 = 0,
			amp2 = 0,
			speed = 0
		}
		
		return setmetatable ( swing, xrSwingValueMT )
	end,
	lerp = function ( self, A, B, f )
		local fi	= 1 - f
		self.amp1		= fi*A.amp1  + f*B.amp1
		self.amp2		= fi*A.amp2  + f*B.amp2
		self.rot1		= fi*A.rot1  + f*B.rot1
		self.rot2		= fi*A.rot2  + f*B.rot2
		self.speed		= fi*A.speed + f*B.speed
	end
}
xrSwingValueMT = { __index = xrSwingValue }

xrGrass = { 
	sectorsToUpdate = { }
}

function xrGrass.markSectorToUpdate ( sector )
	xrGrass.sectorsToUpdate [ sector ] = true
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local txd = engineLoadTXD ( "models/grass.txd" )
		local col = engineLoadCOL ( "models/grass.col" )
		local dff = engineLoadDFF ( "models/grass.dff", 0 )
		
		engineImportTXD ( txd, GRASS_MODEL )
		engineReplaceCOL ( col, GRASS_MODEL )
		engineReplaceModel ( dff, GRASS_MODEL, true )
		
		local xml = xmlLoadFile ( "grass.xml" )
		for i, node in ipairs ( xmlNodeGetChildren ( xml ) ) do
			local texCoordX = xmlNodeGetAttribute ( node, "texCoordX" )
			local texCoordY = xmlNodeGetAttribute ( node, "texCoordY" )
			local posX = xmlNodeGetAttribute ( node, "posX" )
			local posY = xmlNodeGetAttribute ( node, "posY" )
			
			table.insert ( xrElements, {
				tx = math.floor ( tonumber ( texCoordX ) * 32 ), ty = 32 - math.floor ( tonumber ( texCoordY ) * 32 ),
				x = tonumber ( posX ), y = tonumber ( posY )
			} )
		end
		
		xrGrass.swingOne = xrSwingValue.new ( )
		xrGrass.swingOne.amp1 = exports.xrskybox:getXrSetting ( "details", "swing_normal_amp1", "number" )
		xrGrass.swingOne.amp2 = exports.xrskybox:getXrSetting ( "details", "swing_normal_amp2", "number" )
		xrGrass.swingOne.rot1 = exports.xrskybox:getXrSetting ( "details", "swing_normal_rot1", "number" )
		xrGrass.swingOne.rot2 = exports.xrskybox:getXrSetting ( "details", "swing_normal_rot2", "number" )
		xrGrass.swingOne.speed = exports.xrskybox:getXrSetting ( "details", "swing_normal_speed", "number" )
		
		-- fast
		xrGrass.swingTwo = xrSwingValue.new ( )
		xrGrass.swingTwo.amp1 = exports.xrskybox:getXrSetting ( "details", "swing_fast_amp1", "number" )
		xrGrass.swingTwo.amp2 = exports.xrskybox:getXrSetting ( "details", "swing_fast_amp2", "number" )
		xrGrass.swingTwo.rot1 = exports.xrskybox:getXrSetting ( "details", "swing_fast_rot1", "number" )
		xrGrass.swingTwo.rot2 = exports.xrskybox:getXrSetting ( "details", "swing_fast_rot2", "number" )
		xrGrass.swingTwo.speed = exports.xrskybox:getXrSetting ( "details", "swing_fast_speed", "number" )
		
		xrGrass.swingCurrent = xrSwingValue.new ( )
		
		xrStreamerWorld.init ( )
	end
, false )

local startTime = getTickCount ( )
local duration = 1728000
local popDown
local startValue = 0
local targetValue = 1


addEventHandler ( "onClientPreRender", root,
	function ( dd )
		for sector, _ in pairs ( xrGrass.sectorsToUpdate ) do
			if sector:updateRT ( ) then
				xrGrass.sectorsToUpdate [ sector ] = nil
			end
			break
		end
		
		local now = getTickCount ( )
		local elapsedTime = now - startTime
		local progress = elapsedTime / duration
	
		if progress > 1 then
			startTime = now
			startValue = targetValue
			targetValue = targetValue == 1 and 0 or 1
			progress = 0
		end
		
		progress = math.lerp ( startValue, targetValue, progress )

		
		xrGrass.swingCurrent:lerp ( xrGrass.swingOne, xrGrass.swingTwo, progress )
		
		--dxDrawText ( xrGrass.swingCurrent.rot1, 500, 500 )
		
		local time = getTickCount ( ) / 1000
		
		local tm_rot1 = PI_MUL_2*time/xrGrass.swingCurrent.rot1
		local dir1 = Vector4 ( math.sin ( tm_rot1 ), 0, math.cos ( tm_rot1 ), 0 )
		dir1:normalize ( )
		dir1 = dir1 * xrGrass.swingCurrent.amp1
		
		
		local wave = Vector4 ( 1/5, 1/3, 1/7, time * xrGrass.swingCurrent.speed ) / PI_MUL_2
		
		local ambr, ambg, ambb = exports.xrskybox:getEnvValue ( ENV_AMBIENT )
		local hemir, hemig, hemib, hemia = exports.xrskybox:getEnvValue ( ENV_HEMI )
		local sunr, sung, sunb = exports.xrskybox:getEnvValue ( ENV_SUNCOLOR )
		
		local cr = ambr + hemir*0.25 + sunr*0.25
		local cg = ambg + hemig*0.25 + sung*0.25
		local cb = ambb + hemib*0.25 + sunb*0.25
		
		for sector, _ in pairs ( xrStreamerWorld.activated ) do
			for _, element in ipairs ( sector.elements ) do
				dxSetShaderValue ( element.shader, "vecColor", cr, cg, cb )
				dxSetShaderValue ( element.shader, "dir2D", dir1.x, dir1.y, dir1.z, dir1.w )
				dxSetShaderValue ( element.shader, "wave", wave.x, wave.y, wave.z, wave.w )
			end
		end
		
		xrStreamerWorld.update ( )
	end
, false )
