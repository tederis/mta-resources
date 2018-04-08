sx, sy, sz = 0, 0, 3
tx, ty, tz = 0, 0, 4
fx, fy, fz = 0, 1, 3

function getMatrixFromPoints ( x, y, z, x3, y3, z3, x2, y2, z2 )
	x3 = x3 - x
	y3 = y3 - y
	z3 = z3 - z
	x2 = x2 - x
	y2 = y2 - y
	z2 = z2 - z
	local x1 = y2 * z3 - z2 * y3
	local y1 = z2 * x3 - x2 * z3
	local z1 = x2 * y3 - y2 * x3
	x2 = y3 * z1 - z3 * y1
	y2 = z3 * x1 - x3 * z1
	z2 = x3 * y1 - y3 * x1
	local len1 = 1 / math.sqrt ( x1 * x1 + y1 * y1 + z1 * z1 )
	local len2 = 1 / math.sqrt ( x2 * x2 + y2 * y2 + z2 * z2 )
	local len3 = 1 / math.sqrt ( x3 * x3 + y3 * y3 + z3 * z3 )
	x1 = x1 * len1 y1 = y1 * len1 z1 = z1 * len1
	x2 = x2 * len2 y2 = y2 * len2 z2 = z2 * len2
	x3 = x3 * len3 y3 = y3 * len3 z3 = z3 * len3
	return x1, y1, z1, x2, y2, z2, x3, y3, z3
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

function getMatrixFromEulerAngles(x,y,z)
	x,y,z = math.rad(x),math.rad(y),math.rad(z)
	local sinx,cosx,siny,cosy,sinz,cosz = math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
	return
		cosy*cosz-siny*sinx*sinz,cosy*sinz+siny*sinx*cosz,-siny*cosx,
		-cosx*sinz,cosx*cosz,sinx,
		siny*cosz+cosy*sinx*sinz,siny*sinz-cosy*sinx*cosz,cosy*cosx
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
				    self.x * V.y - self.y * V.z)
	end,

	Mul = function(self, n)
		return Vector3D:new(self.x * n, self.y * n, self.z * n)
	end,

	Div = function(self, n)
		return Vector3D:new(self.x / n, self.y / n, self.z / n)
	end,
}

local p = {}
local permutation = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

for i=0,255 do
  p[i] = permutation[i+1]
  p[256+i] = permutation[i+1]
end

function noise(x, y, z) 
  local X = math.floor(x % 255)
  local Y = math.floor(y % 255)
  local Z = math.floor(z % 255)
  x = x - math.floor(x)
  y = y - math.floor(y)
  z = z - math.floor(z)
  local u = fade(x)
  local v = fade(y)
  local w = fade(z)

  A   = p[X  ]+Y
  AA  = p[A]+Z
  AB  = p[A+1]+Z
  B   = p[X+1]+Y
  BA  = p[B]+Z
  BB  = p[B+1]+Z

  return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ), 
                                 grad(p[BA  ], x-1, y  , z   )), 
                         lerp(u, grad(p[AB  ], x  , y-1, z   ), 
                                 grad(p[BB  ], x-1, y-1, z   ))),
                 lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),  
                                 grad(p[BA+1], x-1, y  , z-1 )),
                         lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
                                 grad(p[BB+1], x-1, y-1, z-1 )))
  )
end


function fade(t)
  return t * t * t * (t * (t * 6 - 15) + 10)
end


function lerp(t,a,b)
  return a + t * (b - a)
end


function grad(hash,x,y,z)
  local h = hash % 16
  local u 
  local v 

  if (h<8) then u = x else u = y end
  if (h<4) then v = y elseif (h==12 or h==14) then v=x else v=z end
  local r

  if ((h%2) == 0) then r=u else r=-u end
  if ((h%4) == 0) then r=r+v else r=r-v end
  return r
end

function fractalsum3 ( x, y, z, freq, octaves )
	x = freq * x
	y = freq * y
	z = freq * z
	local boost = freq
	local sum = 0
	local i = octaves
	while i > 0 do
		i = i - 1
		
		sum = noise ( x, y, z ) / freq + sum
		freq = freq * 2.059
		
		x = freq * x
		y = freq * y
		z = freq * z
	end
	
	return boost * sum
end

function math.slerp ( x1, x2, t )
	local v = ( x2 - x1 ) * t
	
	return v + x1
end

function math.lerp ( v0, v1, t )
	return v0+(v1-v0)*t
end

function getPointFromDistanceRotation(x, y, dist, angle)
 
    local a = math.rad(90 - angle);
 
    local dx = math.cos(a) * dist;
    local dy = math.sin(a) * dist;
 
    return x+dx, y+dy;
 
end

function rotateLine ( cx, cy, lx1, ly1, lx2, ly2, theta )
	theta = math.rad ( theta )

	local cx_x1 = lx1 - cx
	local cy_y1 = ly1 - cy
	local cx_x2 = lx2 - cx
	local cy_y2 = ly2 - cy

    lx1 = cx - (cx_x1 * math.cos(theta)) - (cy_y1 * math.sin(theta))
    ly1 = cy - (cx_x1 * math.sin(theta)) + (cy_y1 * math.cos(theta))

    lx2 = cx - (cx_x2 * math.cos(theta)) - (cy_y2 * math.sin(theta))
    ly2 = cy - (cx_x2 * math.sin(theta)) + (cy_y2 * math.cos(theta))
	
	return lx1, ly1, lx2, ly2
end

function findRotation(x1,y1,x2,y2)
 
  local t = -math.deg(math.atan2(x2-x1,y2-y1))
  if t < 0 then t = t + 360 end;
  return t;
 
end

function makeMatrix(x, y, z, rx, ry, rz )
	rx, ry, rz = math.rad(rx), math.rad(ry), math.rad(rz)
	local matrix = {}
	matrix[1] = {}
	matrix[1][1] = math.cos(rz)*math.cos(ry) - math.sin(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][2] = math.cos(ry)*math.sin(rz) + math.cos(rz)*math.sin(rx)*math.sin(ry)
	matrix[1][3] = -math.cos(rx)*math.sin(ry)
	matrix[1][4] = 0
 
	matrix[2] = {}
	matrix[2][1] = -math.cos(rx)*math.sin(rz)
	matrix[2][2] = math.cos(rz)*math.cos(rx)
	matrix[2][3] = math.sin(rx)
	matrix[2][4] = 0
 
	matrix[3] = {}
	matrix[3][1] = math.cos(rz)*math.sin(ry) + math.cos(ry)*math.sin(rz)*math.sin(rx)
	matrix[3][2] = math.sin(rz)*math.sin(ry) - math.cos(rz)*math.cos(ry)*math.sin(rx)
	matrix[3][3] = math.cos(rx)*math.cos(ry)
	matrix[3][4] = 0
 
	matrix[4] = {}
	matrix[4][1], matrix[4][2], matrix[4][3] = x, y, z
	matrix[4][4] = 1
 
	return matrix
end

function getPositionFromElementOffset(element,offX,offY,offZ)
	local m = getElementMatrix ( element )  -- Get the matrix
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z                               -- Return the transformed point
end