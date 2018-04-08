local sw, sh = guiGetScreenSize ( )

local xrPackageShaders = { }
local xrPackageTextures = { }
local xrShaders = { }

local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3
local ENV_SUNDIR = 4

local xrShadowFlags = { 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020 }

local g_TreeLODRefs = 0
--[[
	Разбирает флаг освещения на список лайтмапов
]]
function extractLightmaps ( flagsStr )
	local lmaps = { }
	for i = 1, 6 do
		if bitAnd ( flagsStr, xrShadowFlags [ i ] ) > 0 then
			table.insert ( lmaps, i )
		end
	end
	
	return lmaps
end

function getElementRoot ( element )
	local parent = getElementParent ( element )
	repeat
		parent = getElementParent ( parent )
	until parent ~= false
	return parent
end

function findOrCreateTexture ( texIndex, pkgName )
	local textures = xrPackageTextures [ pkgName ]
	if textures then
		local texture = textures [ texIndex ]
		if texture then
			texture.refs = texture.refs + 1
		else
			texture = { 
				refs = 1, 
				[ 1 ] = dxCreateTexture ( ":" .. pkgName .. "/maps/lmap_" .. texIndex .. "_2.dds", "dxt5" ) 
			}
			textures [ texIndex ] = texture
		end
		return texture [ 1 ]
	else
		local texture = dxCreateTexture ( ":" .. pkgName .. "/maps/lmap_" .. texIndex .. "_2.dds", "dxt5" )
		xrPackageTextures [ pkgName ] = {
			[ texIndex ] = { refs = 1, texture }
		}
		return texture
	end
end

function unlinkTexture ( texIndex, pkgName )
	local textures = xrPackageTextures [ pkgName ]
	if textures then
		local texture = textures [ texIndex ]
		if texture then
			texture.refs = texture.refs - 1
			if texture.refs <= 0 then
				outputDebugString ( "    Destroyed texture lmap_" .. texIndex )

				destroyElement ( texture [ 1 ] )
				textures [ texIndex ] = nil
			end
		end
	end
end

function createTypedShader ( flagsStr, pkgName )
	local shader = dxCreateShader ( "shaders/default.fx", 0, 0, false, "object" )

	local lmaps = extractLightmaps ( flagsStr )
	for _, lmapIndex in ipairs ( lmaps ) do
		local texture = findOrCreateTexture ( lmapIndex, pkgName )
		dxSetShaderValue ( shader, "TexHemi" .. lmapIndex, texture )
	end
	
	return shader
end

function unlinkTypedShader ( flagsStr, pkgName )
	local lmaps = extractLightmaps ( flagsStr )
	for _, lmapIndex in ipairs ( lmaps ) do
		unlinkTexture ( lmapIndex, pkgName )
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		g_Shader = dxCreateShader ( "shaders/def_vertex.fx", 0, 0, false, "object" )
		xrShaders [ 1 ] = g_Shader
		
		g_Internal = dxCreateShader ( "shaders/default_internal.fx", 0, 0, false, "object" )
		xrShaders [ "internal" ] = g_Internal
	end
, false )

local lastUpdate = getTickCount ( )
addEventHandler ( "onClientRender", root,
	function ( )
		local ambr, ambg, ambb = exports.xrskybox:getEnvValue ( ENV_AMBIENT )
		local hemir, hemig, hemib, hemia = exports.xrskybox:getEnvValue ( ENV_HEMI )
		local sunr, sung, sunb = exports.xrskybox:getEnvValue ( ENV_SUNCOLOR )
		local sunx, suny, sunz = exports.xrskybox:getEnvValue ( ENV_SUNDIR )
		
		for _, shader in pairs ( xrShaders ) do
			dxSetShaderValue ( shader, "L_ambient", ambr, ambg, ambb )
			dxSetShaderValue ( shader, "L_hemi_color", hemir, hemig, hemib, hemia )
			dxSetShaderValue ( shader, "L_sun_color", sunr*0.4, sung*0.4, sunb*0.4 )
			dxSetShaderValue ( shader, "L_sun_dir_w", sunx, suny, sunz )
		end
		
		if g_TreeLODShader then
			dxSetShaderValue ( g_TreeLODShader, "useNM", getKeyState ( "z" ) )
		end
		
		LightManager.render ( )
		
		local now = getTickCount ( )
		if now - lastUpdate > 100 then
			lastUpdate = now
			
			LightManager.update ( )
		end
	end
, false )

LightManager = { 
	lights = { },
	lightsP = { },
	shaders = { }
}

function LightManager.init ( )
	--LightManager.coneShader = dxCreateShader ( "shader_conetransform.fx" )
	--LightManager.coneTex = dxCreateTexture ( "textures/lights_cone2.dds" )
	--dxSetShaderValue ( LightManager.coneShader, "Tex", LightManager.coneTex )
end

function LightManager.insertShader ( shader )
	table.insert ( LightManager.shaders, shader )
end

function LightManager.removeShader ( shader )
	for i, shad in ipairs ( LightManager.shaders ) do
		if shad == shader then
			table.remove ( LightManager.shaders, i )
			break
		end
	end
end

function LightManager.createSpotLight ( x, y, z, lx, ly, lz )
	local spot = SpotLight.new ( x, y, z, lx, ly, lz )
	table.insert ( LightManager.lights, spot )
	
	return spot
end

function LightManager.createPointLight ( x, y, z )
	local point = PointLight.new ( x, y, z )
	table.insert ( LightManager.lightsP, point )
	
	return point
end

function LightManager.clearAllPoints ( )
	LightManager.lightsP = { }
	
	outputDebugString ( "Point lights have been removed" )
end

function LightManager.update ( )
	local cx, cy, cz = getCameraMatrix ( )
	LightManager.sort ( cx, cy, cz )
end

function LightManager.render ( )
	local lights = LightManager.lights
	local lightsP = LightManager.lightsP
	
	local spotPosition = { }
	local spotDirection = { }
	
	for i = 1, 5 do
		local spotLight = lights [ i ]
		if spotLight then
			local num = #spotPosition
			spotPosition [ num + 1 ] = spotLight.x
			spotPosition [ num + 2 ] = spotLight.y
			spotPosition [ num + 3 ] = spotLight.z
			
			num = #spotDirection
			spotDirection [ num + 1 ] = spotLight.lx
			spotDirection [ num + 2 ] = spotLight.ly
			spotDirection [ num + 3 ] = spotLight.lz
			
			-- render cone
			--[[dxDrawMaterialLine3D ( 
				spotLight.x, spotLight.y, spotLight.z + 0.1, 
				spotLight.x - spotLight.lx*10, spotLight.y - spotLight.ly*10, spotLight.z - spotLight.lz*10,
				LightManager.coneShader, 1
			)]]
		else
			local num = #spotPosition
			spotPosition [ num + 1 ] = 0
			spotPosition [ num + 2 ] = 0
			spotPosition [ num + 3 ] = 0
			
			num = #spotDirection
			spotDirection [ num + 1 ] = 0
			spotDirection [ num + 2 ] = 0
			spotDirection [ num + 3 ] = 0
		end
	end
	
	local pointPosition = { }
	local pointColor = { }
	
	for i = 1, 5 do
		local pointLight = lightsP [ i ]
		if pointLight then
			local num = #pointPosition
			pointPosition [ num + 1 ] = pointLight.x
			pointPosition [ num + 2 ] = pointLight.y
			pointPosition [ num + 3 ] = pointLight.z
			
			num = #pointColor
			pointColor [ num + 1 ] = pointLight.r / 256
			pointColor [ num + 2 ] = pointLight.g / 256
			pointColor [ num + 3 ] = pointLight.b / 256
			
			dxDrawLine3D ( pointLight.x, pointLight.y, pointLight.z - 0.05, pointLight.x, pointLight.y, pointLight.z + 0.05, tocolor(255, 0, 0))
		else
			local num = #pointPosition
			pointPosition [ num + 1 ] = 0
			pointPosition [ num + 2 ] = 0
			pointPosition [ num + 3 ] = 0
			
			num = #pointColor
			pointColor [ num + 1 ] = 0
			pointColor [ num + 2 ] = 0
			pointColor [ num + 3 ] = 0
		end
	end
	
	for _, shader in ipairs ( LightManager.shaders ) do
		dxSetShaderValue ( shader, "SpotLightPosition", spotPosition )
		dxSetShaderValue ( shader, "SpotLightDirection", spotDirection )
		
		dxSetShaderValue ( shader, "PointLightPosition", pointPosition )
		dxSetShaderValue ( shader, "PointLightColor", pointColor )
	end
end

local _dist3d = getDistanceBetweenPoints3D
function LightManager.sort ( cx, cy, cz )
	local tbl = LightManager.lightsP
	local temp
	for i = 1, #tbl - 1 do
		for j = i, #tbl do
			local x, y, z = tbl [ i ].x, tbl [ i ].y, tbl [ i ].z
			local x2, y2, z2 = tbl [ j ].x, tbl [ j ].y, tbl [ j ].z
				
			if _dist3d ( cx, cy, cz, x, y, z ) > _dist3d ( cx, cy, cz, x2, y2, z2 ) then
				temp = tbl [ i ]
				tbl [ i ] = tbl [ j ]
				tbl [ j ] = temp
			end
		end
	end
end

SpotLight = { }
SpotLight.__index = SpotLight

function SpotLight.new ( x, y, z, lx, ly, lz )
	local spot = {
		x = x, y = y, z = z,
		lx = lx, ly = ly, lz = lz,
		type = 0
	}
	
	return setmetatable ( spot, SpotLight )
end

function SpotLight:setPosition ( x, y, z )
	self.x = x
	self.y = y
	self.z = z
end

function SpotLight:setDirection ( x, y, z )
	self.lx = x
	self.ly = y
	self.lz = z
end

PointLight = { }
PointLight.__index = PointLight

function PointLight.new ( x, y, z )
	local point = {
		x = x, y = y, z = z,
		r = 0, g = 0, b = 0,
		type = 1
	}
	
	return setmetatable ( point, PointLight )
end

function PointLight:setPosition ( x, y, z )
	self.x = x
	self.y = y
	self.z = z
end

function PointLight:setColor ( r, g, b )
	self.r = r
	self.g = g
	self.b = b
end

function createPointLight ( x, y, z, r, g, b )
	local point = LightManager.createPointLight ( x, y, z )
	point:setColor ( r, g, b )
end

function clearAllPoints ( )
	LightManager.clearAllPoints ( )
end

--[[
	EXPORTS
]]

--[[
	shader xrDefineMeshShader ( mesh )
	mesh - элемент описание модели
]]
function xrDefineMeshShader ( mesh )
	local meshRoot = getElementRoot ( mesh )
	if meshRoot == false or getElementType ( meshRoot ) ~= "resource" then
		outputDebugString ( "Не было найдено дерева", 2 )
		return
	end
	local pkgName = getElementID ( meshRoot )
	local meshFlags = getElementData ( mesh, "flag", false )
	
	if getElementData ( mesh, "treelod", false ) == "1" then
		if g_TreeLODShader == nil then
			g_TreeLODShader = dxCreateShader ( "shaders/treelod.fx" )
			g_TreeLODTex = dxCreateTexture ( ":" .. pkgName .. "/maps/level_lods.dds", "dxt5" )
			--g_TreeLODTex2 = dxCreateTexture ( ":" .. pkgName .. "/maps/level_lods_nm.dds", "dxt5" )
			g_TreeLODRefs = 1
			dxSetShaderValue ( g_TreeLODShader, "Tex0", g_TreeLODTex )
			--dxSetShaderValue ( g_TreeLODShader, "Tex1", g_TreeLODTex2 )
			
			xrShaders [ "tree" ] = g_TreeLODShader
			
			outputDebugString ( "TreeLOD shader created" )
		else
			g_TreeLODRefs = g_TreeLODRefs + 1
		end
		
		return g_TreeLODShader
	end
	
	-- Lod or without shadow
	if meshFlags == false or meshFlags == "0" then
		return g_Shader
	end
	
	local shaders = xrPackageShaders [ pkgName ]
	if shaders then
		local typedShader = shaders [ meshFlags ]
		if typedShader then
			typedShader.refs = typedShader.refs + 1
		else
			typedShader = { refs = 1, createTypedShader ( string.format ( '0x%x', meshFlags ), pkgName ) }
			shaders [ meshFlags ] = typedShader
			LightManager.insertShader ( typedShader [ 1 ] ) -- temp lighting
			table.insert ( xrShaders, typedShader [ 1 ] )
		end
		return typedShader [ 1 ]
	else
		local typedShader = createTypedShader ( string.format ( '0x%x', meshFlags ), pkgName )
		xrPackageShaders [ pkgName ] = {
			[ meshFlags ] = { refs = 1, typedShader }
		}
		LightManager.insertShader ( typedShader ) -- temp lighting
		table.insert ( xrShaders, typedShader )
		return typedShader
	end
end

--[[
	xrDestroyMeshShader
]]
function xrDestroyMeshShader ( mesh )
	local meshRoot = getElementRoot ( mesh )
	if meshRoot == false or getElementType ( meshRoot ) ~= "resource" then
		outputDebugString ( "Не было найдено дерева", 2 )
		return
	end
	local pkgName = getElementID ( meshRoot )
	local meshFlags = getElementData ( mesh, "flag", false )
	
	if getElementData ( mesh, "treelod", false ) == "1" then
		g_TreeLODRefs = g_TreeLODRefs - 1
		if isElement ( g_TreeLODShader ) and g_TreeLODRefs <= 0 then
			destroyElement ( g_TreeLODShader )
			destroyElement ( g_TreeLODTex )
			--destroyElement ( g_TreeLODTex2 )
			g_TreeLODShader = nil
			g_TreeLODTex = nil
			
			xrShaders [ "tree" ] = nil
		end
		
		return true
	end
	
	local shaders = xrPackageShaders [ pkgName ]
	if shaders then
		local typedShader = shaders [ meshFlags ]
		if typedShader then
			typedShader.refs = typedShader.refs - 1
			if typedShader.refs <= 0 then
				outputDebugString ( "Destroyed mesh " .. getElementData ( mesh, "model", false ) .. " shader" )
				
				local ourShader = typedShader [ 1 ]
				-- Найдем и удалим шейдер из таблицы
				for i, shader in ipairs ( xrShaders ) do
					if shader == ourShader then
						table.remove ( xrShaders, i )
						break
					end
				end
				
				LightManager.removeShader ( ourShader ) -- temp lighting
				destroyElement ( ourShader )
				unlinkTypedShader ( string.format ( '0x%x', meshFlags ), pkgName )
				shaders [ meshFlags ] = nil
			end
		end
	end
end

--[[
	xrDefineInternal
]]
function xrDefineInternal ( )
	return g_Internal
end