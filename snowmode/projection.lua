--if true then return end

local sw, sh = guiGetScreenSize ( )

local shader
local screenSource = dxCreateScreenSource ( sw, sh )

local streamedInProjectors = { }

local sectorMatrix = { 
	{ -1, 1 }, { 0, 1 }, { 1, 1 },
	{ -1, 0 }, { 0, 0 }, { 1, 0 },
	{ -1, -1 }, { 0, -1 }, { 1, -1 }
}
streamedInSectors = { }

addEventHandler ( "onClientRender", root,
	function ( )
		TextureProjector.update ( )
		
		--local x, y, z = getElementPosition ( localPlayer )
		
		--xrStreamerWorld.update ( )
		
		--[[local sx, sy = -3000, 3000
		local relx, rely = ( x - sx ) / 6000, ( sy - y ) / 6000
		local texx, texy = relx * 1024, rely * 1024
		
		dxSetRenderTarget ( g_Rt, false )
		dxDrawRectangle ( texx - 1, texy - 1, 3, 3, tocolor ( 255, 0, 0 ) )
		dxSetRenderTarget ( )]]
	end
)

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		--xrStreamerWorld.init ( )
		
		g_Rt2 = dxCreateTexture ( "snowmap.dds" )
		--g_Rt = dxCreateRenderTarget ( 1024, 1024, false )

		proj = TextureProjector.create ( 0, 0, 0, loadedTextures.single )
		proj:setMaterial ( g_Rt2 )
	end
, false )

TextureProjector = {
	items = { }
}
TextureProjector.__index = TextureProjector

function TextureProjector.create ( x, y, z, texture )
	local texProj = {
		x = x, y = y, z = z,
		
		shader = dxCreateShader ( "shaders/projection.fx", 0, 0, false, "world" )
	}
	
	texProj.viewPoint = ViewPoint:new ( )
	texProj.viewPoint:setPosition ( x, y, z )
	texProj.viewPoint:setLookAt ( x, y, z )
	texProj.viewPoint:setRotation ( 0, 0, 0 )
	texProj.viewPoint:generateViewMatrix ( )
	--texProj.viewPoint:setProjectionParameters ( math.rad ( 180 - 90 ), 1, 1, 100 )
	texProj.viewPoint:generateProjectionMatrix ( )
	
	dxSetShaderValue ( texProj.shader, "lightView", texProj.viewPoint.viewMatrix )
	dxSetShaderValue ( texProj.shader, "lightProj", texProj.viewPoint.projectionMatrix )
	dxSetShaderValue ( texProj.shader, "snowTex", texture )
	
	for _, shader in ipairs ( readyShaders ) do
		dxSetShaderValue ( shader, "lightView", texProj.viewPoint.viewMatrix )
		dxSetShaderValue ( shader, "lightProj", texProj.viewPoint.projectionMatrix )
		dxSetShaderValue ( shader, "Tex0", g_Rt2 )
	end
	
	setShaderPrelight ( texProj.shader )
	
	--engineApplyShaderToWorldTexture ( texProj.shader, "*" )
	
	TextureProjector.items [ texProj ] = true
	
	setmetatable ( texProj, TextureProjector )
	
	return texProj
end

function TextureProjector:destroy ( )
	TextureProjector.items [ self ] = nil
	
	destroyElement ( self.shader )
end

function TextureProjector:setMatrix ( x, y, z, rx, ry, rz )
	self.viewPoint:setPosition ( x, y, z )
	self.viewPoint:setRotation ( rx, ry, rz )
	
	self.viewPoint:generateViewMatrix ( )
	
	dxSetShaderValue ( self.shader, "lightView", self.viewPoint.viewMatrix )
	dxSetShaderValue ( self.shader, "lightProj", self.viewPoint.projectionMatrix )
end

function TextureProjector:setMaterial ( material )
	self.material = material
	
	dxSetShaderValue ( self.shader, "Tex0", material )
end

function TextureProjector:draw ( )
	self.viewPoint:debugDraw ( )
end

local stbl = {
	{ 0, 0 }, { 1, 0 }, { 2, 0 },
	{ 0, 1 }, { 1, 1 }, { 2, 1 },
	{ 0, 2 }, { 1, 2 }, { 2, 2 }
}

function TextureProjector.update ( )
	for texProj, _ in pairs ( TextureProjector.items ) do
		texProj:draw ( )
	end

	if sector == nil then
		return
	end
	
	local picPos = { x = 500, y = 200 }
	local picSize = 200
	
	dxDrawRectangle ( picPos.x, picPos.y, picSize * 3, picSize * 3, tocolor ( 0, 0, 0, 150 ) )
	for i = 1, 9 do
		local sector = streamedInSectors [ i ]
		local off = stbl [ i ]
		
		local x, y = picPos.x + ( picSize * off [ 1 ] ), picPos.y + ( picSize * off [ 2 ] )
		dxDrawImage ( x, y, picSize, picSize, sector.texture )
		dxDrawText ( sector.column .. ", " ..sector.row, x, y )
	end
end


function D3DXMatrixPerspectiveFovLH ( fovy, aspect, zn, zf )
    local pout = D3DXMatrixIdentity ( ) 
	-- [ 0 ] = { 0, 1, 2, 3 },
	-- [ 1 ] = { 0, 1, 2, 3 },
	-- [ 2 ] = { 0, 1, 2, 3 },
	-- [ 3 ] = { 0, 1, 2, 3 }
	
	pout [ 1 ] = 1 / (aspect * math.tan(fovy/2))
	pout [ 6 ] = 1 / math.tan(fovy/2)
	pout [ 11 ] = zf / (zf - zn)
	pout [ 12 ] = 1
	pout [ 15 ] = (zf * zn) / (zn - zf)
	pout [ 16 ] = 0
	
    return pout
end

function D3DXMatrixOrthoOffCenterLH ( l, r, b, t, zn, zf )
	local pout = {
		2/(r-l),      0,            0,           0,
		0,            2/(t-b),      0,           0,
		0,            0,            1/(zf-zn),   0,
		(l+r)/(l-r),  (t+b)/(b-t),  zn/(zn-zf),  1
	}
	
    return pout
end

function D3DXMatrixLookAtLH ( peye, pat, pup )
	local vec2 = pat:SubV ( peye )
	vec2:Normalize ( )
	local right = pup:CrossV ( vec2 )
	local up = vec2:CrossV ( right )
	right:Normalize ( )
	up:Normalize ( )
	
	local pout = { 
		right.x, up.x, vec2.x, 0,
		right.y, up.y, vec2.y, 0,
		right.z, up.z, vec2.z, 0,
		-right:Dot ( peye ), -up:Dot ( peye ), -vec2:Dot ( peye ), 1
	}
	
	return pout
end

function D3DXMatrixIdentity ( )
	local matrix = {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	}

	return matrix
end

function D3DXMatrixRotationYawPitchRoll(yaw, pitch, roll)
	local sroll = math.sin(roll);
	local croll = math.cos(roll);
	local spitch = math.sin(pitch);
    local cpitch = math.cos(pitch);
	local syaw = math.sin(yaw);
	local cyaw = math.cos(yaw);
	
	local out = { }
	
	-- [ 0 ] = { 0, 1, 2, 3 },
	-- [ 1 ] = { 0, 1, 2, 3 },
	-- [ 2 ] = { 0, 1, 2, 3 },
	-- [ 3 ] = { 0, 1, 2, 3 }
 
	--[[out->u.m[0][0] = sroll * spitch * syaw + croll * cyaw;
	out->u.m[0][1] = sroll * cpitch;
	out->u.m[0][2] = sroll * spitch * cyaw - croll * syaw;
	out->u.m[0][3] = 0.0;
	out->u.m[1][0] = croll * spitch * syaw - sroll * cyaw;
	out->u.m[1][1] = croll * cpitch;
	out->u.m[1][2] = croll * spitch * cyaw + sroll * syaw;
    out->u.m[1][3] = 0.0;
    out->u.m[2][0] = cpitch * syaw;
    out->u.m[2][1] = -spitch;
    out->u.m[2][2] = cpitch * cyaw;
    out->u.m[2][3] = 0.0;
	out->u.m[3][0] = 0.0;
	out->u.m[3][1] = 0.0;
	out->u.m[3][2] = 0.0;
	out->u.m[3][3] = 1.0;]]
	
	out [ 1 ] = sroll * spitch * syaw + croll * cyaw;
	out [ 2 ] = sroll * cpitch;
	out [ 3 ] = sroll * spitch * cyaw - croll * syaw;
	out [ 4 ] = 0.0;
	out [ 5 ] = croll * spitch * syaw - sroll * cyaw;
	out [ 6 ] = croll * cpitch;
	out [ 7 ] = croll * spitch * cyaw + sroll * syaw;
    out [ 8 ] = 0.0;
    out [ 9 ] = cpitch * syaw;
    out [ 10 ] = -spitch;
    out [ 11 ] = cpitch * cyaw;
    out [ 12 ] = 0.0;
	out [ 13 ] = 0.0;
	out [ 14 ] = 0.0;
	out [ 15 ] = 0.0;
	out [ 16 ] = 1.0;

	return out
end

Vector3D = {
	new = function(self, _x, _y, _z)
		local newVector = { x = _x or 0.0, y = _y or 0.0, z = _z or 0.0 }
		return setmetatable(newVector, { __index = Vector3D })
	end,

	Copy = function(self)
		return Vector3D:new(self.x, self.y, self.z)
	end,

	Normalize = function(self)
		local mod = self:Module()
		self.x = self.x / mod
		self.y = self.y / mod
		self.z = self.z / mod
	end,

	Dot = function(self, V)
		return self.x * V.x + self.y * V.y + self.z * V.z
	end,

	Module = function(self)
		return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	end,

	AddV = function(self, V)
		return Vector3D:new(self.x + V.x, self.y + V.y, self.z + V.z)
	end,

	SubV = function(self, V)
		return Vector3D:new(self.x - V.x, self.y - V.y, self.z - V.z)
	end,

	CrossV = function(self, V)
		return Vector3D:new(self.y * V.z - self.z * V.y,
		                    self.z * V.x - self.x * V.z,
				    self.x * V.y - self.y * V.z) --!
	end,

	Mul = function(self, n)
		return Vector3D:new(self.x * n, self.y * n, self.z * n)
	end,

	Div = function(self, n)
		return Vector3D:new(self.x / n, self.y / n, self.z / n)
	end,
}

ViewPoint = { 
	new = function ( self )
		return setmetatable ( { }, { __index = ViewPoint } )
	end,
	setPosition = function ( self, x, y, z )
		self.position = Vector3D:new ( x, y, z )
	end,
	setRotation = function ( self, rx, ry, rz )
		self.rotation = Vector3D:new ( rx, ry, rz )
	end,
	setLookAt = function ( self, lx, ly, lz )
		self.lookAt = Vector3D:new ( lx, ly, lz )
	end,
	setProjectionParameters = function ( self, fieldOfView, aspectRatio, nearPlane, farPlane )
		self.fieldOfView = fieldOfView
		self.aspectRatio = aspectRatio
		self.nearPlane = nearPlane
		self.farPlane = farPlane
	end,
	generateViewMatrix = function ( self )
		--local up = Vector3D:new ( 0, 0, -1 )
		
		--self.viewMatrix = D3DXMatrixLookAtLH ( self.position, self.lookAt, up )
		self.viewMatrix = D3DXMatrixRotationYawPitchRoll ( math.rad ( self.rotation.x ), math.rad ( self.rotation.y ), math.rad ( self.rotation.z ) )
		self.viewMatrix [ 13 ] = -self.position.x
		self.viewMatrix [ 14 ] = -self.position.y
		self.viewMatrix [ 15 ] = self.position.z
	end,
	generateProjectionMatrix = function ( self )
		--self.projectionMatrix = D3DXMatrixPerspectiveFovLH ( self.fieldOfView, self.aspectRatio, self.nearPlane, self.farPlane )
		local sectorSize = 6000--SECTOR_SIZE
		local halfSectorSize = sectorSize / 2 
		self.projectionMatrix = D3DXMatrixOrthoOffCenterLH ( -halfSectorSize, halfSectorSize, -halfSectorSize, halfSectorSize, 0, 1 )
	end,
	debugDraw = function ( self )
		dxDrawLine3D ( 
			self.position.x, self.position.y, self.position.z - 1000, 
			self.position.x, self.position.y, self.position.z + 1000, 
			tocolor ( 255, 0, 0, 255 ), 5 )
	end
}

function getElementPositionByOffset ( element, xOffset, yOffset, zOffset )
	local pX, pY, pZ

	local matrix = getElementMatrix ( element )
	
	if matrix then
		pX = xOffset * matrix [ 1 ] [ 1 ] + yOffset * matrix [ 2 ] [ 1 ] + zOffset * matrix [ 3 ] [ 1 ] + matrix [ 4 ] [ 1 ]
		pY = xOffset * matrix [ 1 ] [ 2 ] + yOffset * matrix [ 2 ] [ 2 ] + zOffset * matrix [ 3 ] [ 2 ] + matrix [ 4 ] [ 2 ]
		pZ = xOffset * matrix [ 1 ] [ 3 ] + yOffset * matrix [ 2 ] [ 3 ] + zOffset * matrix [ 3 ] [ 3 ] + matrix [ 4 ] [ 3 ]
	else
		pX, pY, pZ = getElementPosition ( element )
	end
	
	return pX, pY, pZ
end