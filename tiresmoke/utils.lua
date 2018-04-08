XR_MAX_INTERNALS_PER_SHADER = 5

--[[
	Material
]]
Material = { }
Material.__index = Material

function Material.new ( textureName )
	local material = {
		diffuse_color = { 255, 255, 255 },
		alpha = 255,
		ambient = 1,
		specular_intensity = 1,
		diffuse_intensity = 1,
		raytrace_mirror = { },
		mirror_color = { 124, 165, 34 },
		
		textureName = textureName
	}
	return setmetatable ( material, Material )
end

--[[
	Mesh
]]
SurfaceMesh = { }
SurfaceMesh.__index = SurfaceMesh

function SurfaceMesh.new ( textureName )
	local mesh = {
		hasNormals = true,
		vertices = { },
		polygons = { },
		materials = { },
		uv_layers = { 
			{
				data = { 
					
				}
			}
		},
		uv_textures = {
			{
				name = textureName
			}
		}
	}
	return setmetatable ( mesh, SurfaceMesh )
end

function SurfaceMesh:defineVertex ( x, y, z, nx, ny, nz )
	local verticesNum = #self.vertices
	self.vertices [ verticesNum + 1 ] = { co = { x, y, z } }
	if self.hasNormals then
		self.vertices [ verticesNum + 1 ].normal = { nx, ny, nz }
	end
	local layersNum = #self.uv_layers [ 1 ].data
	self.uv_layers [ 1 ].data [ layersNum + 1 ] = {	uv = { 0, 0 } }

	return verticesNum + 1
end

function SurfaceMesh:definePolygon ( a, b, c )
	local polygonsNum = #self.polygons
	self.polygons [ polygonsNum + 1 ] = { vertices = { a, b, c }, loop_indices = { a, b, c }, material_index = 1 }
end

function SurfaceMesh:defineMaterial ( material )
	table.insert ( self.materials, material )
	return #self.materials
end

--[[
	xrPEBuilder
]]
xrPEBuilder = {
	sizeX = 2,
	sizeY = 2
}

function xrPEBuilder.makeAndBuildPEMesh ( particlesNum )
	local mesh = SurfaceMesh.new ( )
	mesh:defineMaterial ( Material.new ( "_Textur2_" ) )
	
	local lastIndex = 1
	for i = 1, particlesNum do
		if lastIndex > XR_MAX_INTERNALS_PER_SHADER then
			lastIndex = 0
		end
		
		xrPEBuilder.buildPlane ( mesh, xrPEBuilder.sizeX, xrPEBuilder.sizeY, i - 1 )
			
		lastIndex = lastIndex + 1
	end
	
	local now = getTickCount ( )
	local dffFile = fileCreate ( "models/fxmesh.dff" )
	_bytesFile =  dffFile
	local dff = RpClump:new ( 0x1803FFFF, mesh )
	dff:bin ( dffFile )
	outputChatBox(fileGetPos(dffFile))
	fileClose ( dffFile )
	_bytesFile = nil
	outputDebugString ( "DFF построен за " .. getTickCount ( ) - now .. " мс" )
end

function xrPEBuilder.buildPlane ( mesh, sizeX, sizeY, index )
	local halfSizeX = sizeX / 2
	local halfSizeY = sizeY / 2
	local v0 = mesh:defineVertex ( -halfSizeX, halfSizeY, 0, index, 0, 0 )
	local v1 = mesh:defineVertex ( halfSizeX, halfSizeY, 0, index, 0, 0 )
	local v2 = mesh:defineVertex ( -halfSizeX, -halfSizeY, 0, index, 0, 0 )
	local v3 = mesh:defineVertex ( halfSizeX, -halfSizeY, 0, index, 0, 0 )
	
	mesh.uv_layers [ 1 ].data [ v0 ] = { uv = { 0, 0 } }
	mesh.uv_layers [ 1 ].data [ v1 ] = { uv = { 1, 0 } }
	mesh.uv_layers [ 1 ].data [ v2 ] = { uv = { 0, 1 } }
	mesh.uv_layers [ 1 ].data [ v3 ] = { uv = { 1, 1 } }
	
	mesh:definePolygon ( v0, v1, v2 )
	mesh:definePolygon ( v2, v1, v3 )
end

addCommandHandler ( "makepemesh",
	function ( _, _, particlesNum )
		particlesNum = tonumber ( particlesNum )
		if particlesNum then
			xrPEBuilder.makeAndBuildPEMesh ( particlesNum )
			
			outputChatBox ( "Модель частиц создана" )
		else
			outputChatBox ( "Некорректный синтаксис: makepemesh <particlesNum>" )
		end
	end
)