WaterEntity = { }

function WaterEntity.create ( x, y, z, width, depth )
	local x1, y1 = x - width, y - depth
	local x2, y2 = x + width, y - depth
	local x3, y3 = x - width, y + depth
	local x4, y4 = x + width, y + depth
	
	local water = createWater ( x1, y1, z, x2, y2, z, x3, y3, z, x4, y4, z, false )
	
	return water
end

local waterFake
local waterTexture
local _testWater

function WaterEntity.createWaterFake ( x, y, z, width, depth )
	if waterFake == nil then
		waterFake = createElement ( "water-fake" )
		setElementPosition ( waterFake, x, y, z )
		setElementData ( waterFake, "width", width, false )
		setElementData ( waterFake, "depth", depth, false )
		
		waterTexture = dxCreateTexture ( "textures/derevachka.dds" )
		
		addEventHandler ( "onClientPreRender", root, WaterEntity.onRender, false, "low" )
		
		_testWater = WaterEntity.create ( x, y, z, width, depth )
		
		return waterFake
	end
end

function WaterEntity.destroyWaterFake ( )
	if waterFake then 
		removeEventHandler ( "onClientPreRender", root, WaterEntity.onRender )
		destroyElement ( waterFake )
		destroyElement ( waterTexture )
		destroyElement ( _testWater )
		
		waterFake = nil
	end
end

function WaterEntity.onRender ( )
	if waterFake then
		local x, y, z = getElementPosition ( waterFake )
		
		setElementPosition ( _testWater, x, y, z )
		
		local width = getElementData ( waterFake, "width", false )
		local depth = getElementData ( waterFake, "depth", false )
		local halfWidth = width-- * 0.5 
		
		--float fBottom = float ( ( int ) ( vecPosition.fY / m_fRowSize ) ) * m_fRowSize;
		
		--x, y = math.ceil ( math.floor ( x - 0.5 ) + 0.5 ), math.ceil ( y )
		
		--x = math.floor ( x / 2 + 0.5 ) * 2 - 1
		x = math._round(x, 0)
		
		local x1 = x - halfWidth
		local x2 = x + halfWidth
		
		--x1 = math.floor ( x1 / 2 + 0.5 ) * 2 - 1
		--x2 = math.floor ( x2 / 2 + 0.5 ) * 2 - 1
		y = math.floor ( y / 2 ) * 2 + 1
		
		dxDrawMaterialLine3D ( x1, y, z, x2, y, z, waterTexture, depth * 2, tocolor ( 255, 255, 255, 255 ), x, y, z + 1 )
	end
end

function math._round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end