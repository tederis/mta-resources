local stringLen = string.len
local mathSqrt = math.sqrt
local mathFloor = math.floor
local mathMax = math.max

local fileHatches = { }
local fileHatch = function ( file, name )
	local hatch = fileHatches [ file ]
	if hatch then	
		local hatchNum = hatch [ name ]
		if hatchNum then
			fileHatches [ file ] [ name ] = nil
			return hatchNum
		end
		fileHatches [ file ] [ name ] = 0
	else
		fileHatches [ file ] = {
			[ name ] = 0
		}
	end
end
local _fileWrite = fileWrite
function fileWrite ( file, ... )
	local hatch = fileHatches [ file ]
	if hatch then
		local arg = { ... }
		local size = 0
		for i = 1, #arg do
			size = size + stringLen ( arg [ i ] )
		end
		for name, bytes in pairs ( hatch ) do
			hatch [ name ] = bytes + size
		end
	end
	_fileWrite ( file, ... )
end

-- TEST

RwTypes = {
    ANY = -1,
    
    STRUCT = 0x0001,
    STRING = 0x0002,
    EXTENSION = 0x0003,
    TEXTURE = 0x0006,
    MATERIAL = 0x0007,
    MATERIALLIST = 0x0008,
    FRAMELIST = 0x000E,
    GEOMETRY = 0x000F,
    CLUMP = 0x0010,
    ATOMIC = 0x0014,
    GEOMETRYLIST = 0x001A,
    RENDERRIGHTS = 0x001F,
    
    MORPHPLG = 0x0105,
    SKINPLG = 0x116,
    HANIMPLG = 0x11E,
    MATEFFECTS = 0x0120,
    BINMESHPLG = 0x050E,
    FRAMENAME = 0x253F2FE,
    COLLISION = 0x253F2FA,
    MATSPECULAR = 0x253F2F6,
    NIGHTCOLS = 0x253F2F9,
    MATREFLECTION = 0x253F2FC,
    MESHEXTENSION = 0x253F2FD,
	
	decodeVersion = function ( version )
		if bitAnd ( version, 0xFFFF0000 ) == 0 then
			return bitLShift ( version, 8 )
		else
			local p1 = bitAnd ( bitRShift ( version, 14 ), 0x3FF00 ) + 0x30000
			local p2 = bitAnd ( bitRShift ( version, 16 ), 0x3F )
            
            return bitOr ( p1, p2 )
		end
	end
}

RpGeomFlag = {
    TRISTRIP = 0x0001,
    POSITIONS = 0x0002,
    TEXTURED = 0x0004,
    PRELIT = 0x0008,
    NORMALS = 0x0010,
    LIGHT = 0x0020,
    MODULATEMATERIALCOLOR = 0x0040,
    TEXTURED2 = 0x0080
}

RwChunkHeader = {
	new = function ( self, type, size )
		local chunkHeader = {
			type = type,
			size = size
		}
		return setmetatable ( chunkHeader, { __index = self } )
	end,
	bin = function ( self, file )
		--dataToBytes ( "uiuiui", self.type, self.size, targetVer ) -- 12 byte
		dataToBytes ( "i", self.type )
		dataToBytes ( "i", self.size )
		dataToBytes ( "i", targetVer )
	end
}

RpAtomicChunkInfo = {
	new = function ( self, frameIndex, geometryIndex, flags )
		local atomicChunkInfo = {
			frameIndex = frameIndex,
			geometryIndex = geometryIndex,
			flags = flags
		}
		return setmetatable ( atomicChunkInfo, { __index = self } )
	end,
	bin = function ( self, file )
		RwChunkHeader:new ( RwTypes.STRUCT, 16 ):bin ( file )
		dataToBytes ( "iiii", self.frameIndex, self.geometryIndex, self.flags, 0 )
	end
}

RpAtomic = {
	new = function ( self, frame )
		local atomic = {
			clump = frame.clump,
			frame = frame,
			mesh = frame.mesh
		}
		
		atomic.geometry = RpGeometry:new ( atomic )
		atomic.flags = 5
		
		return setmetatable ( atomic, { __index = self } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "ATOMIC" )
		local base = fileGetPos ( file )
		
		fileSetPos ( file, base + 12 )
		RpAtomicChunkInfo:new ( self.frame.index, self.geometry.index, self.flags ):bin ( file )
		
		--local extensions = "" --self:binext_rights ( ) .. self:binext_matfx ( )
		RwChunkHeader:new ( RwTypes.EXTENSION, 0 ):bin ( file )
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.ATOMIC, fileHatch ( file, "ATOMIC" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpVertex = {
	new = function ( self, pos, uv, uve, normal )
		local vertex = {
			pos = pos,
			uv = uv,
			uve = uve,
			normal = normal
		}
		return setmetatable ( vertex, { __index = self } )
	end
}

RpTriangle = {
	new = function ( self, a, b, c, mat )
		local triangle = {
			a = a, b = b, c = c,
			mat = mat
		}
		return setmetatable ( triangle, { __index = self } )
	end,
	bin = function ( self, file )
		dataToBytes ( "usususus", self.a, self.b, self.mat, self.c ) -- 8 bytes
	end
}

RwUVCoord = {
	new = function ( self, u, v )
		return setmetatable ( { u = u, v = v }, { __index = self } )
	end,
	bin = function ( self, file )
		dataToBytes ( "ff", self.u, 1 - self.v ) -- 8 bytes
	end
}

RwTexture = {
	new = function ( self, material, bltexslot )
		local texture = {
			material = material,
			bltexslot = bltexslot,
			--bltex = bltexslot.texture\
			bltex = bltexslot
		}
		return setmetatable ( texture, { __index = self } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "TEXTURE" )
		local base = fileGetPos ( file )
		
		-- Flags structure
		fileSetPos ( file, base + 12 ) -- Прыгаем через заголовок
		RwChunkHeader:new ( RwTypes.STRUCT, 4 ):bin ( file )
		dataToBytes ( "usus", 0x1106, 0 ) -- 4 bytes
		
		-- Diffuse texture structure
		RwChunkHeader:new ( RwTypes.STRING, 21 ):bin ( file )
		dataToBytes ( "ccccccccc", "_", "T", "e", "x", "t", "u", "r", "2", "_" ) -- 4 bytes
		dataToBytes ( "iii", 0, 0, 0 )
		
		--[[fileSetPos ( file, base + 12 + 4 + 12 )
		local code = ""
		local str = { } 
		for i = 1, string.len ( self.bltex ) do 
			code = code .. "c"
			str [ i ] = string.sub ( self.bltex, i, i )
		end
		--dataToBytes ( code, unpack ( str ) )
		dataToBytes ( "c", "_" )
		for i = 1, 4 - bitAnd ( stringLen ( strdata ), 3 ) do
			strdata = strdata .. dataToBytes ( "ub", 0 ) -- 1 byte
		end
		fileWrite ( file, strdata )
		local _current = fileGetPos ( file )
		fileSetPos ( file, base + 12 + 4 )
		RwChunkHeader:new ( RwTypes.STRING, stringLen ( strdata ) ):bin ( file )]]
		
		-- Alpha texture structure
		--fileSetPos ( file, _current )
		RwChunkHeader:new ( RwTypes.STRING, 4 ):bin ( file )
		dataToBytes ( "i", 0 ) -- 4 bytes
		
		-- Extensions
		--local extensions = ""
		--extensions = RwChunkHeader:new ( RwTypes.EXTENSION, stringLen ( extensions ) ):bin ( ) .. extensions
		--payload = payload .. extensions
		
		RwChunkHeader:new ( RwTypes.EXTENSION, 0 ):bin ( file )
		
		local current = fileGetPos ( file )
			
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.TEXTURE, fileHatch ( file, "TEXTURE" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpMaterial = {
	new = function ( self, materialList, blMaterial )
		local material = {
			materialList = materialList,
			
			index = #materialList.mats,
			mesh = materialList.mesh,
			blmaterial = blMaterial,
			
			red = blMaterial.diffuse_color [ 1 ],
			green = blMaterial.diffuse_color [ 2 ],
			blue = blMaterial.diffuse_color [ 3 ],
			alpha = blMaterial.alpha,
			
			ambient = blMaterial.ambient,
			specular = blMaterial.specular_intensity,
			diffuse = blMaterial.diffuse_intensity,
			
			--bltex_diffuse = _abstractTexSlot_, --self.findTexSlot("DIFFUSE"),
			--bltex_specular = 1, -- self.findTexSlot("SPECULAR"),
			--bltex_envmap = 1, --self.findTexSlot("ENVMAP"),
		}
		
		material.bltex_diffuse = material.mesh.materials [ 1 ].textureName
		if material.bltex_diffuse then
			material.tex_diffuse = RwTexture:new ( material, material.bltex_diffuse )
                
			if not material.materialList.geometry.uvname_diff then
			--if material.bltex_diffuse.texture_coords == "UV" and stringLen ( material.bltex_diffuse.uv_layer ) > 0 and not material.materialList.geometry.uvname_diff then
				--material.materialList.geometry.uvname_diff = material.bltex_diffuse.uv_layer
				material.materialList.geometry.uvname_diff = material.bltex_diffuse
			end
		end
		
		if material.bltex_envmap then
			material.tex_envmap = RwTexture:new ( material, material.bltex_envmap )
                
			if material.bltex_envmap.texture_coords == "UV" and #material.bltex_envmap.uv_layer > 0 and not material.materialList.geometry.uvname_env then
				material.materialList.geometry.uvname_env = material.bltex_envmap.uv_layer
			end
		end
		
		return setmetatable ( material, { __index = self } )
	end,
	binext_matfx = function ( self, file )
		if not self.tex_envmap then
			return
		end
		
		dataToBytes ( "iifii", 2, 2, self.bltex_envmap.specular_color_factor, 0, 1 )
		
		-- TODO
	end,
	binext_reflect = function ( self, file )
		if not self.blmaterial.raytrace_mirror.use and decodedVer <= 0x34003 then
			return
		end
		
		RwChunkHeader:new ( RwTypes.MATREFLECTION, 24 ):bin ( file )
		
		local factor = self.blmaterial.raytrace_mirror.use == true and self.blmaterial.raytrace_mirror.reflect_factor or 0
		local colour = self.blmaterial.mirror_color
		dataToBytes ( "fffffi", colour [ 1 ], colour [ 2 ], colour [ 3 ], 1, factor, 0 )
	end,
	binext_specular = function ( self )
		if not self.bltex_specular then
			return
		end
	end,
	bin = function ( self, file )
		fileHatch ( file, "MATERIAL" )
		local base = fileGetPos ( file )
	
		fileSetPos ( file, base + 12 ) -- Прыгаем через заголовок MATERIAL
		RwChunkHeader:new ( RwTypes.STRUCT, 28 ):bin ( file )
		dataToBytes ( "iububububiuifff", 0, mathFloor ( self.red ), mathFloor ( self.green ), mathFloor ( self.blue ), mathFloor ( self.alpha ), 0, self.tex_diffuse ~= nil and 1 or 0, self.ambient, self.specular, self.diffuse ) -- 28 bytes
		
		if self.tex_diffuse then
			self.tex_diffuse:bin ( file )
		end
		
		-- Extensions
		fileHatch ( file, "MATERIAL_EXTENSION" )
		local _current = fileGetPos ( file )
		fileSetPos ( file, _current + 12 )
		
		self:binext_matfx ( file )
		self:binext_reflect ( file )
		self:binext_specular ( file )
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, _current )
		RwChunkHeader:new ( RwTypes.EXTENSION, fileHatch ( file, "MATERIAL_EXTENSION" ) ):bin ( file )
		--RwChunkHeader:new ( RwTypes.EXTENSION, 0 ):bin ( file )
		
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.MATERIAL, fileHatch ( file, "MATERIAL" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpMaterialList = {
	new = function ( self, geometry )
		local materialList = {
			geometry = geometry,
			clump = geometry.clump,
			
			mesh = geometry.mesh,
			
			mats = { }
		}
		
		for _, mat in ipairs ( materialList.mesh.materials ) do
			table.insert ( materialList.mats, RpMaterial:new ( materialList, mat ) )
		end
		
		return setmetatable ( materialList, { __index = self } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "MATERIALLIST" )
		local base = fileGetPos ( file )
		
		fileSetPos ( file, base + 12 ) -- Прыгаем через заголовок MATERIALLIST
		RwChunkHeader:new ( RwTypes.STRUCT, 4 + (#self.mats*4) ):bin ( file )
	
		-- Material count
		dataToBytes ( "i", #self.mesh.materials ) -- 4 bytes
		
		for _, mat in ipairs ( self.mats ) do
			dataToBytes ( "i", -1 ) -- 4 bytes
		end
		
		-- Materials
		for _, mat in ipairs ( self.mats ) do
			mat:bin ( file )
		end
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.MATERIALLIST, fileHatch ( file, "MATERIALLIST" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpGeometryList = {
	new = function ( self )
		local geometryList = {
			geoms = { }
		}
		return setmetatable ( geometryList, { __index = self } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "GEOMETRYLIST" )
		local listBase = fileGetPos ( file )
	
		fileSetPos ( file, listBase + 12 ) -- Прыгаем через заголовок GEOMETRYLIST
		RwChunkHeader:new ( RwTypes.STRUCT, 4 ):bin ( file )
	
		-- Geometry count
		dataToBytes ( "i", #self.geoms ) -- 4 bytes
		
		-- Geometries
		for _, geom in ipairs ( self.geoms ) do
			geom:bin ( file )
		end
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, listBase ) -- Возвращаемся на начало
		RwChunkHeader:new ( RwTypes.GEOMETRYLIST, fileHatch ( file, "GEOMETRYLIST" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpGeometryChunkInfo = {
	new = function ( self )
		local geometryChunkInfo = {
			flags = bitOr ( RpGeomFlag.TEXTURED, RpGeomFlag.NORMALS, RpGeomFlag.LIGHT, RpGeomFlag.MODULATEMATERIALCOLOR ),
			texCount = 1,
			triangleCount = 1,
			vertexCount = 1,
			frameCount = 1
		}
		return setmetatable ( geometryChunkInfo, { __index = self } )
	end,
	binraw = function ( self, file )
		dataToBytes ( "ususiii", self.flags, self.texCount, self.triangleCount, self.vertexCount, self.frameCount ) -- 16 bytes
	end
}

RpGeometry = {
	new = function ( self, atomic )
		local geometry = {
			clump = atomic.clump,
			atomic = atomic,
			mesh = atomic.mesh,
			chunkInfo = RpGeometryChunkInfo:new ( ),
			
			matTris = { },
			vdict = { }
		}
		setmetatable ( geometry, { __index = self } )
		
		geometry.index = #geometry.clump.geometryList.geoms
		table.insert ( geometry.clump.geometryList.geoms, geometry )
		
		geometry.materialList = RpMaterialList:new ( geometry )
		
		for i = 1, #geometry.materialList.mats do
			table.insert ( geometry.matTris, { } )
		end
		
		for i = 1, #geometry.mesh.vertices do
			table.insert ( geometry.vdict, { } )
		end
		
		geometry.uvc = geometry:getUVData ( geometry.uvname_diff )
		
		if geometry.uvname_env and geometry.uvname_env ~= geometry.uvname_diff then
			geometry.uvce = geometry:getUVData ( geometry.uvname_env )
		end
		
		geometry.vertices = { }
		geometry.triangles = { }
		
		--[[
		for _, vcol in ipairs ( geometry.mesh.vertex_colors ) do
			if string.lower ( vcol.name ) == "night" and geometry.nightVertCol == nil then
				geometry.nightVertCol = { }
				geometry.nightVertColData = vcol.data
			elseif geometry.vertCol == nil then
				geometry.vertCol = { }
				geometry.vertColData = vcol.data
			end
		end]]
		
		-- TEST
		geometry:_insertVertices ( )
		geometry:_insertTriangles ( )
		
		--[[for _, poly in ipairs ( geometry.mesh.polygons ) do
			geometry:addBlenderPoly ( poly )
		end]]
		
		if #geometry.vertices > 65535 then
			outputDebugString ( "Aborting export: vertex count exceeds 65535", 2 )
			return
		end
		
		geometry.maxDist = 0
		
		for _, v in ipairs ( geometry.mesh.vertices ) do
			geometry.maxDist = mathMax ( geometry.maxDist, mathSqrt ( v.co [ 1 ] * v.co [ 1 ] + v.co [ 2 ]* v.co [ 2 ] + v.co [ 3 ] * v.co [ 3 ] ) )
		end
		
		geometry.chunkInfo.triangleCount = #geometry.triangles
		geometry.chunkInfo.vertexCount = #geometry.vertices
		
		if geometry.uvce then
			geometry.chunkInfo.texCount = 2
			geometry.chunkInfo.flags = bitAnd ( geometry.chunkInfo.flags, bitLRotate ( RpGeomFlag.TEXTURED )--[[ & (~RpGeomFlag.TEXTURED)]] )
			geometry.chunkInfo.flags = bitOr ( geometry.chunkInfo.flags, RpGeomFlag.TEXTURED2 )
		end
		
		if decodedVer > 0x34003 then
			geometry.chunkInfo.flags = bitOr ( geometry.chunkInfo.flags, RpGeomFlag.POSITIONS )
		end
	
		if geometry.vertColData then
			geometry.chunkInfo.flags = bitOr ( geometry.chunkInfo.flags, RpGeomFlag.PRELIT )
		end
		
		--geometry.chunkInfo.flags = bitNot ( geometry.chunkInfo.flags, RpGeomFlag.NORMALS )
		
		return geometry
	end,
	getUVData = function ( self, name )
		for i = 1, #self.mesh.uv_textures do
			if name and self.mesh.uv_textures [ i ] and name == self.mesh.uv_textures [ i ].name then
				return self.mesh.uv_layers [ i ].data
			end
		end
	end,
	
	-- TEST
	_insertVertices = function ( self )
		local uve = { 0, 0 }
		local normal = { 0, 0, 1 }
		local uvLayers = self.mesh.uv_layers [ 1 ].data
		
		for i, vertex in ipairs ( self.mesh.vertices ) do
			local uv = uvLayers [ i ].uv
			table.insert ( self.vertices, RpVertex:new ( vertex.co, uv, uve, normal ) )
		end
	end,
	_insertTriangles = function ( self )
		for i, polygon in ipairs ( self.mesh.polygons ) do
			local verticesIds = polygon.vertices
			table.insert ( self.triangles, RpTriangle:new ( verticesIds [ 1 ] - 1, verticesIds [ 2 ] - 1, verticesIds [ 3 ] - 1, polygon.material_index ) )
			
			table.insert ( self.matTris [ 1 ], verticesIds [ 1 ] - 1 )
			table.insert ( self.matTris [ 1 ], verticesIds [ 2 ] - 1 )
			table.insert ( self.matTris [ 1 ], verticesIds [ 3 ] - 1 )
		end
	end,
	
	
	newVertId = function ( self, id, uv, uve )
		if self.vdict [ id ] [ ( uv [ 1 ] + uv [ 2 ] + uve [ 1 ] + uve [ 2 ] ) ] == nil then
			self.vdict [ id ] [ ( uv [ 1 ] + uv [ 2 ] + uve [ 1 ] + uve [ 2 ] ) ] = #self.vertices

			table.insert ( self.vertices, RpVertex:new ( self.mesh.vertices [ id ].co, uv, uve, self.mesh.vertices [ id ].normal ) )
	                
			if self.vertColData then
				table.insert ( self.vertCol, { self.vertColData [ id ].color [ 1 ], self.vertColData [ id ].color [ 2 ], self.vertColData [ id ].color [ 3 ] } )
			end
                
			if self.nightVertColData then
				table.insert ( self.nightVertCol, { self.nightVertColData [ id ].color [ 1 ], self.nightVertColData [ id ].color [ 2 ], self.nightVertColData [ id ].color [ 3 ] } )
			end
		end

		return self.vdict [ id ] [ ( uv [ 1 ] + uv [ 2 ] + uve [ 1 ] + uve [ 2 ] ) ]
	end,
	addRawPoly = function ( self, verts, uvs, mat )
		local newIds = { }
		
		for i = 1, 3 do
			local uv = { 0, 0 } if self.uvc ~= nil then uv = self.uvc [ uvs [ i ] ].uv end;
			local uve = { 0, 0 }; if self.uvce ~= nil then uve = self.uvce [ uvs [ i ] ].uv end;
                
			newIds [ i ] = self:newVertId ( verts [ i ], uv, uve )
		end
		
		table.insert ( self.triangles, RpTriangle:new ( newIds [ 1 ], newIds [ 2 ], newIds [ 3 ], mat ) )
		
		if mat > 0 then
			local matsNum = #self.matTris [ mat ]
			self.matTris [ mat ] [ matsNum + 1 ] = newIds [ 1 ]
			self.matTris [ mat ] [ matsNum + 2 ] = newIds [ 2 ]
			self.matTris [ mat ] [ matsNum + 3 ] = newIds [ 3 ]
		end
	end,
	addBlenderPoly = function ( self, p )
		if #p.vertices < 3 or #p.vertices > 4 then
			outputDebugString ( "Aborting export: Invalid number of vertices on an edge(" .. #p .. ")." )
			return
		end
		
		--local x1, y1, z1 = self.mesh.vertices [ p.vertices [ 1 ] ].co [ 1 ], self.mesh.vertices [ p.vertices [ 1 ] ].co  [ 2 ], self.mesh.vertices [ p.vertices [ 1 ] ].co  [ 3 ]
		--local x2, y2, z2 = self.mesh.vertices [ p.vertices [ 2 ] ].co  [ 1 ], self.mesh.vertices [ p.vertices [ 2 ] ].co  [ 2 ], self.mesh.vertices [ p.vertices [ 2 ] ].co  [ 3 ]
		
		--outputDebugString ( tostring ( p.vertices [ 1 ] ) .. ", " .. p.vertices [ 2 ] .. ", " .. p.vertices [ 3 ] )
		
		-- loop_indices нужен для UV слоя
		self:addRawPoly ( { p.vertices [ 1 ], p.vertices [ 2 ], p.vertices [ 3 ] }, { p.loop_indices [ 1 ], p.loop_indices [ 2 ], p.loop_indices [ 3 ] }, p.material_index )
		--[[if #p.vertices == 4 then
			self:addRawPoly ( { p.vertices [ 1 ], p.vertices [ 4 ], p.vertices [ 3 ] }, { p.loop_indices [ 1 ], p.loop_indices [ 4 ], p.loop_indices [ 3 ] }, p.material_index )
		end]]
	end,
	binext_binmesh = function ( self, file )
		--self.clump.profiler:trace ( "GeometryBin_binext_binmesh" )
		
		-- TODO!
		fileHatch ( file, "BINMESHPLG" )
		local base = fileGetPos ( file )
		fileSetPos ( file, base + 12 + 12 )
	
		local payload = ""
		local splits = 0
		local total = 0
		
		--self.clump.profiler:trace ( "GeometryBin_binext_binmesh_magic" )
		for i = 1, #self.matTris do
			local triangles = self.matTris [ i ]
			if #triangles > 0 then
				splits = splits + 1
                total = total + #triangles
                dataToBytes ( "ii", #triangles, i - 1 )
                
				for j = 1, #triangles do
					dataToBytes ( "i", triangles [ j ] )
				end
				--outputDebugString(splits .. ", " .. total )
			end
		end
		--self.clump.profiler:trace ( "GeometryBin_binext_binmesh_magic" )
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, base + 12 )
		dataToBytes ( "iii", 0, splits, total )
		
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.BINMESHPLG, fileHatch ( file, "BINMESHPLG" ) ):bin ( file )
		
		--self.clump.profiler:trace ( "GeometryBin_binext_binmesh" )
		
		fileSetPos ( file, current )
	end,
	binext_morph = function ( self, file )
		--self.clump.profiler:trace ( "GeometryBin_binext_morph" )
	
		if decodedVer > 0x34003 or decodedVer < 0x33000 then
			return
		end
		
		RwChunkHeader:new ( RwTypes.MORPHPLG, 4 ):bin ( file )
		dataToBytes ( "i", 0 ) -- 4 bytes
		
		--self.clump.profiler:trace ( "GeometryBin_binext_morph" )
	end,
	binext_meshext = function ( self, file )
		--self.clump.profiler:trace ( "GeometryBin_binext_meshext" )
	
		if decodedVer <= 0x34003 then
			return
		end
		
		RwChunkHeader:new ( RwTypes.MESHEXTENSION, 4 ):bin ( file )
		dataToBytes ( "i", 0 ) -- 4 bytes
		
		--self.clump.profiler:trace ( "GeometryBin_binext_meshext" )
	end,
	binext_nightcol = function ( self, file )
		--self.clump.profiler:trace ( "GeometryBin_binext_nightcol" )
	
		if not self.nightVertCol then
			return
		end
		
		RwChunkHeader:new ( RwTypes.NIGHTCOLS, 4 + #self.nightVertCol*4 ):bin ( file )
		
		dataToBytes ( "ui", 1 ) -- 4 bytes
		
		for _, col in ipairs ( self.nightVertCol ) do
			dataToBytes ( "ubububub", col [ 1 ], col [ 2 ], col [ 3 ], 255 ) -- 4 bytes
		end
			
		--self.clump.profiler:trace ( "GeometryBin_binext_nightcol" )
	end,
	bin = function ( self, file )
		fileHatch ( file, "GEOMETRY" )
		fileHatch ( file, "GEOMETRY_STRUCT" )
		local base = fileGetPos ( file )
	
		--self.clump.profiler:trace ( "ENTER_RpGeometryList" )
		
		fileSetPos ( file, base + 12 + 12 ) -- Прыгаем через заголовок GEOMETRY и через заголовок STRUCT
		self.chunkInfo:binraw ( file )
		
		if decodedVer < 0x34001 then
			dataToBytes ( "fff", 0, 0, 1 ) -- 12 bytes
		end
		
		if self.vertCol then
			for _, col in ipairs ( self.vertCol ) do
				--payload = dataToBytes ( "usususus", col [ 1 ], col [ 2 ], col [ 3 ], 255 )
				dataToBytes ( "i", 0x00FFFFFF ) -- 4 bytes
			end
		end
		
		--self.clump.profiler:trace ( "RwUVCoord_create_generate" )
		outputDebugString ( "UV offset " .. fileGetPos ( file ) )
		for _, vertex in ipairs ( self.vertices ) do
			RwUVCoord:new ( vertex.uv [ 1 ], vertex.uv [ 2 ] ):bin ( file )
		end
		--self.clump.profiler:trace ( "RwUVCoord_create_generate" )
		
		if self.uvce then
			for _, vertex in ipairs ( self.vertices ) do
				RwUVCoord:new ( vertex.uve [ 1 ], vertex.uve [ 2 ] ):bin ( file )
			end
		end
		
		--self.clump.profiler:trace ( "GeometryBin_TriangleBin" )
		outputDebugString ( "Triangle offset " .. fileGetPos ( file ) )
		for _, triangle in ipairs ( self.triangles ) do
			triangle:bin ( file )
		end
		--self.clump.profiler:trace ( "GeometryBin_TriangleBin" )
		
		--outputChatBox(self.maxDist)
		outputDebugString ( "max dist DFF " .. fileGetPos ( file ) )
		dataToBytes ( "ffffii", 0.0, 0.0, 0.0, self.maxDist, 1, 1 ) -- 24 bytes
		
		--self.clump.profiler:trace ( "GeometryBin_vertexpos_creation_bin" )
		outputDebugString ( "Vertex offset " .. fileGetPos ( file ) )
		for _, vertex in ipairs ( self.vertices ) do
			RwVector3:new ( vertex.pos [ 1 ], vertex.pos [ 2 ], vertex.pos [ 3 ] ):bin ( file )
		end
		--self.clump.profiler:trace ( "GeometryBin_vertexpos_creation_bin" )
		
		--self.clump.profiler:trace ( "GeometryBin_vertexnormal_creation_bin" )
		for _, vertex in ipairs ( self.vertices ) do
			RwVector3:new ( vertex.normal [ 1 ], vertex.normal [ 2 ], vertex.normal [ 3 ] ):bin ( file )
		end
		--self.clump.profiler:trace ( "GeometryBin_vertexnormal_creation_bin" )
		
		local structSize = fileHatch ( file, "GEOMETRY_STRUCT" )
		
		--self.clump.profiler:trace ( "GeometryBin_MaterialList_bin" )
		self.materialList:bin ( file )
		--self.clump.profiler:trace ( "GeometryBin_MaterialList_bin" )
		
		--self.clump.profiler:trace ( "GeometryBin_extensions" )
		fileHatch ( file, "GEOMETRY_EXTENSION" )
		local _current = fileGetPos ( file )
		fileSetPos ( file, _current + 12 )
		self:binext_binmesh ( file ) 
		self:binext_morph ( file ) 
		self:binext_meshext ( file )
		self:binext_nightcol ( file ) 
		-- + self.binext_skin() + self.binext_morph() + self.binext_meshext() + self.binext_nightcol()
		--self.clump.profiler:trace ( "GeometryBin_extensions" )
		
		local current = fileGetPos ( file )
		
		--self.clump.profiler:trace ( "GeometryBin_extensionsheader_bin" )
		fileSetPos ( file, _current )
		RwChunkHeader:new ( RwTypes.EXTENSION, fileHatch ( file, "GEOMETRY_EXTENSION" ) ):bin ( file )
		--self.clump.profiler:trace ( "GeometryBin_extensionsheader_bin" )
		
		--self.clump.profiler:trace ( "GeometryBin_RwChunkHeader_creation_bin" )
		fileSetPos ( file, base + 12 )
		RwChunkHeader:new ( RwTypes.STRUCT, structSize ):bin ( file )
		--self.clump.profiler:trace ( "GeometryBin_RwChunkHeader_creation_bin" )
		
		--self.clump.profiler:trace ( "GeometryBin_header_bin" )
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.GEOMETRY, fileHatch ( file, "GEOMETRY" ) ):bin ( file )
		--self.clump.profiler:trace ( "GeometryBin_header_bin" )
		
		--self.clump.profiler:trace ( "ENTER_RpGeometryList" )
		
		fileSetPos ( file, current )
	end
}

RwVector3 = {
	new = function ( self, x, y, z )
		local vector = {
			x = x, y = y, z = z
		}
		return setmetatable ( vector, { __index = RwVector3 } )
	end,
	bin = function ( self, file )
		dataToBytes ( "fff", self.x, self.y, self.z ) -- 12 bytes
	end
}

RwRotMatrix = {
	new = function ( self )
		local matrix = {
			1.0, 0.0, 0.0,
			0.0, 1.0, 0.0,
			0.0, 0.0, 1.0
		}
		return setmetatable ( matrix, { __index = RwRotMatrix } )
	end,
	bin = function ( self, file )
		for _, float in ipairs ( self ) do
			dataToBytes ( "f", float )
		end
	end
}

RwFrameList = {
	new = function ( self )
		local frameList = {
			frames = { }
		}
		return setmetatable ( frameList, { __index = self } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "FRAMELIST" ) -- Обнуляем счетчик байтов
		fileHatch ( file, "FRAMELIST_STRUCT" )
		local listBase = fileGetPos ( file )
		
		fileSetPos ( file, listBase + 12 + 12 ) -- Прыгаем через заголовок FRAMELIST и заголовок STRUCT
		dataToBytes ( "i", #self.frames ) -- 4 bytes
		
		for _, frame in ipairs ( self.frames ) do
			frame:binraw ( file )
		end
		
		local structSize = fileHatch ( file, "FRAMELIST_STRUCT" )

		for _, frame in ipairs ( self.frames ) do
			frame:binext ( file )
		end
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, listBase + 12 ) -- Прыгаем в конец заголовка FRAMELIST
		RwChunkHeader:new ( RwTypes.STRUCT, structSize ):bin ( file )
		
		fileSetPos ( file, listBase ) -- Прыгаем на начало
		RwChunkHeader:new ( RwTypes.FRAMELIST, fileHatch ( file, "FRAMELIST" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RwFrame = {
	new = function ( self, clump, mesh, parentFrame )
		local frame = {
			clump = clump,
			mesh = mesh,
			
			index = #clump.frameList.frames,
			
			name = "_Frame_",
			parent = parentFrame,
			
			rotation = RwRotMatrix:new ( ),
			position = RwVector3:new ( 0, 0, 0 ),
		}
		
		frame.atomic = RpAtomic:new ( frame )
		
		table.insert ( clump.frameList.frames, frame )
		
		clump.colbin = nil
		
		return setmetatable ( frame, { __index = RwFrame } )
	end,
	binraw = function ( self, file )
		self.rotation:bin ( file )
		self.position:bin ( file )
		
		dataToBytes ( "ii", -1, 0 ) -- 8 bytes
	end,
	binext_name = function ( self, file )
		local base = fileGetPos ( file )
		
		fileSetPos ( file, base + 12 ) -- Прыгаем через заголовок FRAMENAME
		dataToBytes ( "cccc" , "s", "e", "x", "y" )
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, base )
		RwChunkHeader:new ( RwTypes.FRAMENAME, 4 ):bin ( file )
		
		fileSetPos ( file, current )
	end,
	binext = function ( self, file )
		fileHatch ( file, "FRAME_EXTENSION" ) -- Обнуляем счетчик байтов
		local base = fileGetPos ( file )
		
		fileSetPos ( file, base + 12 ) -- Прыгаем через заголовок EXTENSION
		self:binext_name ( file )
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, base ) -- Возвращаемся на начало
		RwChunkHeader:new ( RwTypes.EXTENSION, fileHatch ( file, "FRAME_EXTENSION" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpClumpChunkInfo = {
	new = function ( self, atomicCount, lightCount, cameraCount )
		local clumpChunkInfo = {
			atomicCount = atomicCount,
			lightCount = lightCount,
			cameraCount = cameraCount
		}
		return setmetatable ( clumpChunkInfo, { __index = RpClumpChunkInfo } )
	end,
	bin = function ( self, file )
		fileHatch ( file, "CLUMP_STRUCT" ) -- Создаем отметку для начала отсчета
		local chunkBase = fileGetPos ( file )
		
		fileSetPos ( file, chunkBase + 12 ) -- Прыгаем через заголовок
		dataToBytes ( "i", self.atomicCount ) -- 4 byte
		
		if decodedVer > 0x33000 then
			dataToBytes ( "ii", self.lightCount, self.cameraCount ) -- 8 byte
		end
		
		local current = fileGetPos ( file )
		
		fileSetPos ( file, chunkBase ) -- Возвращаемся на начало чанка
		RwChunkHeader:new ( RwTypes.STRUCT, fileHatch ( file, "CLUMP_STRUCT" ) ):bin ( file )
		
		fileSetPos ( file, current )
	end
}

RpClump = {
	new = function ( self, exportVer, mesh, profiler )
		local clump = {
			mesh = mesh,
			
			--profiler = profiler
		}
		
		--profiler:trace ( "RwFrameList_creation" )
		clump.frameList = RwFrameList:new ( )
		--profiler:trace ( "RwFrameList_creation" )
		
		--profiler:trace ( "RpGeometryList_creation" )
		clump.geometryList = RpGeometryList:new ( )
		--profiler:trace ( "RpGeometryList_creation" )
		
		targetVer = exportVer
		decodedVer = RwTypes.decodeVersion ( targetVer )
		
		--profiler:trace ( "RwFrame_creation" )
		
		RwFrame:new ( clump, mesh )
		
		--profiler:trace ( "RwFrame_creation" )
		
		if #clump.frameList.frames == 0 then
			outputDebugString ( "Aborting export: no frames selected.", 2 )
			return
		end
		
		return setmetatable ( clump, { __index = RpClump } )
	end,
	bin = function ( self, file )
		--self.profiler:trace ( "RpClump_GENERATE" )
	
		fileHatch ( file, "CLUMP" )
	
		-- RpClumpChunkInfo
		fileSetPos ( file, 12 )
		--self.profiler:trace ( "RpClumpChunkInfo_creation_generate" )
		RpClumpChunkInfo:new ( #self.geometryList.geoms, 0, 0 ):bin ( file )
		--self.profiler:trace ( "RpClumpChunkInfo_creation_generate" )
		
		-- Frame list
		--self.profiler:trace ( "RwFrameList_generate" )
		self.frameList:bin ( file )
		--self.profiler:trace ( "RwFrameList_generate" )
		
		-- Geometry list
		--self.profiler:trace ( "RpGeometryList_generate" )
		self.geometryList:bin ( file )
		--self.profiler:trace ( "RpGeometryList_generate" )
		
		-- Atomic
		--self.profiler:trace ( "RpGeometryAtomic_generate" )
		for _, geometry in ipairs ( self.geometryList.geoms ) do
			geometry.atomic:bin ( file )
		end
		--self.profiler:trace ( "RpGeometryAtomic_generate" )
		
		-- Extensions
		--local extensions = "" --= self.binext_coll()
		--self.profiler:trace ( "RwChunkHeaderEXTENSION_creation_generate" )
		RwChunkHeader:new ( RwTypes.EXTENSION, 0 ):bin ( file )
		--self.profiler:trace ( "RwChunkHeaderEXTENSION_creation_generate" )
		
		--self.profiler:trace ( "RwChunkHeaderCLUMP_creation_generate" )
		fileSetPos ( file, 0 )
		RwChunkHeader:new ( RwTypes.CLUMP, fileHatch ( file, "CLUMP" ) ):bin ( file )
		--self.profiler:trace ( "RwChunkHeaderCLUMP_creation_generate" )
		
		--self.profiler:trace ( "RpClump_GENERATE" )
	end
}