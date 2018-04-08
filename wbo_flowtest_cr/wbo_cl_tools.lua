local _resetTarget = function ( )
	Editor.setTarget ( )
end


--------------------------------------
-- Default tool
--------------------------------------
toolDefault = {
	name = "Default",
	
	--The flag for the creation of hidden tools
	hidden = true,
	
	controls = {
		{
			"checkbox",
			
			id = "rand_z",
			text = _LD"MF_SRandZ",
			selected = false
		},
		{
			"checkbox",
			
			id = "scale",
			text = _LD"MF_SRandScale",
			selected = false
		}
	},
	
	onCancel = _resetTarget
}

function toolDefault:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	--x, y, z = EntitySnap:getPosition ( )
	-- Округляем до сотых и переводим в строку для сохранения допустимых значений при передачи на сервер
	x, y, z = math.round ( x, 3 ), math.round ( y, 3 ), math.round ( z, 3 )
	x, y, z = tostring ( x ), tostring ( y ), tostring ( z )
	
	--local rx, ry, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
	local rx, ry, rz = getElementRotation ( element )
	if self:getControl ( "rand_z" ):getData ( ) then
		rz = rz + math.random ( 0, 360 )
	end
	rx, ry, rz = math.round ( rx, 3 ), math.round ( ry, 3 ), math.round ( rz, 3 )
	rx, ry, rz = tostring ( rx ), tostring ( ry ), tostring ( rz )
	
	local sx, sy, sz = g_entityOffset.calcScale ( )
	local scale = math.max ( sz, 0.1 )
	if self:getControl ( "scale" ):getData ( ) then
		scale = 0.3 + math.random ( 0, 200 ) / 100
	end
	scale = tostring ( math.round ( scale, 3 ) )
	
	triggerServerEvent ( "onCreateTCTObject", resourceRoot, getElementModel ( element ), x, y, z, rx, ry, rz, scale )
end

function toolDefault:onChangeOffset ( element )
	if getElementType ( element ) == "object" then
		local sx, sy, sz = g_entityOffset.calcScale ( )
		local scale = math.max ( sz, 0.1 )
		
		setObjectScale ( element, scale )
	end
end

--------------------------------------
-- World group
--------------------------------------
groupWorld = {
	name = "World"
}

--------------------------------------
-- Grab tool
--------------------------------------
toolGrab = {
	name = "Grab",
	desc = "Для того чтобы взять объект, прицельтесь на него и нажмите [num3]. Для размещения объекта, нажмите [num5].",
	group = groupWorld,
	uninterrupted = true -- Защита от блокировки по времени( см. Editor.onKey )
}

local grabTranslation

local function restoreObject ( element )
	if grabTranslation then
		setElementPosition ( element, unpack ( grabTranslation [ 1 ] ) )
		setElementRotation ( element, unpack ( grabTranslation [ 2 ] ) )
		local elementType = getElementType ( element )
		if elementType == "object" then
			setElementAlpha ( element, grabTranslation [ 3 ] )
			setElementDoubleSided ( element, grabTranslation [ 4 ] )
		end
		
		setElementCollisionsEnabled ( element, true )
		
		grabTranslation = nil
	end
end

function toolGrab:onAccept ( element )
	if Editor.isElementOwner ( element, true ) ~= true then
		outputChatBox ( _LD"MEPermission", 255, 0, 0 )
		return
	end
	
	if GameManager.isElementEntity ( element ) then
		outputChatBox ( _LD"MEGrabBl", 255, 255, 0 )
		return
	end

	grabTranslation = { 
		{ getElementPosition ( element ) },
		{ getElementRotation ( element ) },
		getElementAlpha ( element ),
		isElementDoubleSided ( element ) 
	}
	
	Editor.setTarget ( element )
end

function toolGrab:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
	restoreObject ( element )

	triggerServerEvent ( "onPlaceTCTElement", element, x, y, z, rx, ry, rz )
	
	_resetTarget ( )
end

function toolGrab:onCancel ( element )
	if not element then return end;

	restoreObject ( element )
	
	_resetTarget ( )
end

--------------------------------------
-- Remove tool
--------------------------------------
toolRemove = {
	name = "Remove",
	desc = "Для удаления объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
		
	controls = {
		{
			"checkbox",
			
			id = "onl_athd",
			text = _LD"TRemove_OA",
			selected = false
		}
	}
}

function toolRemove:onAccept ( element )
	triggerServerEvent ( "onDestroyTCTElement", element, self:getControl ( "onl_athd" ):getData ( ) )
end

--------------------------------------
-- Alpha tool
--------------------------------------
toolAlpha = {
	name = "Alpha",
	desc = "Чтобы изменить прозрачность объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
	
	controls = {
		{
			"scrollbar",
			
			id = "a_lvl",
			text = _LD"TAlpha_Trans",
			value = { 
				150,
				min = 0,
				max = 255
			}
		}
	}
}

function toolAlpha:onAccept ( element )
	triggerServerEvent ( "onChangeTCTAlpha", element, self:getControl ( "a_lvl" ):getData ( ) )
end

--------------------------------------
-- Double sided tool
--------------------------------------
toolDoubleSided = {
	name = "Double sided",
	desc = "Чтобы дублировать стороны объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
}

function toolDoubleSided:onAccept ( element )
	if getElementType ( element ) ~= "object" then
		outputChatBox ( _LD"TMsgWorksObjOnly", 255, 0, 0 )
		
		return 
	end
	
	triggerServerEvent ( "onSidedTCTElement", element )
end

--------------------------------------
-- Freeze tool
--------------------------------------
toolFreeze = { 
	name = "Freeze",
	desc = "Чтобы заморозить объект, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
}

function toolFreeze:onAccept ( element )
	local elementType = getElementType ( element )
		
	if elementType ~= "object" and elementType ~= "vehicle" then
		outputChatBox ( _LD"TMsgWorksObjVehOnly", 255, 0, 0 )
		
		return
	end

	triggerServerEvent ( "onFreezeTCTElement", element )
end

--------------------------------------
-- Attach tool
--------------------------------------
local attachTable

toolAttach = {
	name = "Attach",
	desc = "Чтобы склеить между собой два объекта, вы должны сначала прицелиться на тот, которой хотите прикрепить к другому и нажать [num3]. Затем прицелиться на второй и снова [num3].",
	group = groupWorld,
	controls = {
		{
			"edit",
			
			id = "offs",
			text = _LD"TAction_Off",
			value = "0,0,0"
		},
		{
			"checkbox",
			
			id = "manual",
			selected = false,
			text = "Manual"
		}
	}
}

function toolAttach:onAccept ( element )
	local offset = { }
	if self:getControl ( "manual" ):getData ( ) then
		local offsetStr = self:getControl ( "offs" ):getData ( )
		local offsetValues = split ( offsetStr, 44 )
	
		if #offsetValues ~= 3 then
			outputChatBox ( _LD"TActionMsg_Warn3", 255, 0, 0 )
			return
		end

		for i, value in ipairs ( offsetValues ) do
			value = tonumber ( value )
			if not value then
				outputChatBox ( _LD"TActionMsg_Warn4", 255, 0, 0 )
				return
			end
		
			offset [ i ] = value
		end
	end

	if not attachTable then
		attachTable = { 
			element = element
		}
	elseif isElement ( attachTable.element ) then
		if attachTable.element == element then
			return
		end

		triggerServerEvent ( "onAttachTCTElement", attachTable.element, element, unpack ( offset ) )

		attachTable = nil
	end
end

function toolAttach:onCancel ( ) 
	attachTable = nil 
end

--------------------------------------
-- Material tool
--------------------------------------
local newModelRef = { "_Blinds_", "Blinds_C" }
modelMaterials = {
	[ 1799 ] = {
		"port", "port2"
	 },
	[ 2118 ] = {
		"port", "port2"
	},
	[ 3037 ] = {
		"garage_docks", "garage_docks2"
	},
	[ 1717 ] = {
		"LoadingDoorClean", "LoadingDoorClean2"
	},
	[ 4374 ] = {
		"drvin_front", "drvin_front2"
	},
	[ 3095 ] = {
		"sam_camo", "bonyrd_skin2"
	},
	
	[ 10008 ] = newModelRef,
	[ 10009 ] = newModelRef,
	[ 10010 ] = newModelRef,
	[ 10011 ] = newModelRef,
	[ 10012 ] = newModelRef,
	[ 10013 ] = newModelRef,
}

local _onMaterialSelect = function ( name, id )
	--if getFileByID ( id ) ~= nil then
		Tool.getControl ( toolMaterial, "mat" ):setData ( name )
		toolMaterial.materialId = id
	--end
end

toolMaterial = {
	name = "Material",
	desc = "Для того чтобы изменить материал, прицельтесь на объект и нажмите [num3].",
	group = groupWorld,
	
	controls = {
		{
			"button",
			
			id = "mat",
			text = _LD"TMaterial_Mat",
			onClick = function ( )
				local loadedMaterials = getLoadedFiles ( "dds"--[[, "jpg"]] )
				if #loadedMaterials < 1 then
					outputChatBox ( "TCT: No loaded textures", 200, 200, 0 )
					return 
				end
			
				MaterialBrowser.show ( _onMaterialSelect )
				MaterialBrowser.insertMaterial ( nil, "Default", false )
				for _, file in ipairs ( loadedMaterials ) do
					MaterialBrowser.insertMaterial ( ":wbo_modmanager/modfiles/" .. file.checksum, file.name, file.id )
				end
			end
		},
		{
			"scrollbar",
			
			id = "u",
			text = _LD"TMaterial_U",
			value = { 
				1,
				min = 1,
				max = 10
			}
		},
		{
			"scrollbar",
			
			id = "v",
			text = _LD"TMaterial_V",
			value = { 
				1,
				min = 1,
				max = 10
			}
		}
	},
	
	onSelected = function ( )
		addEventHandler ( "onClientPlayerTarget", localPlayer, toolMaterial.onPlayerTarget )
		
		local target = getPedTarget ( localPlayer )
		toolMaterial.onPlayerTarget ( target )
	end,
	onCancel = function ( )
		removeEventHandler ( "onClientPlayerTarget", localPlayer, toolMaterial.onPlayerTarget )
		ActionList.setTargetElement ( false )
	end
}

function toolMaterial.onPlayerTarget ( target )
	if not target then
		ActionList.setTargetElement ( false )
		
		return
	end
		
	local materials = modelMaterials [ getElementModel ( target ) ]
	if materials then
		ActionList.setItems ( materials )
		ActionList.setTargetElement ( target )
	else
		ActionList.setTargetElement ( false )
	end
end

function toolMaterial:onAccept ( element )
	if getElementType ( element ) ~= "object" then
		outputChatBox ( _LD"TMsgWorksObjOnly", 255, 0, 0 )
		return
	end	

	-- Получаем выбранную в списке текстуру
	local textureId = tonumber ( self.materialId )
	
	-- Получаем выбранную в меню текстуру модели, которую будем заменять
	local modelTextureIndex = 0
	local elementModel = getElementModel ( element )
	if modelMaterials [ elementModel ] then
		modelTextureIndex = ActionList.getSelectedItem ( )
		if not modelMaterials [ elementModel ] [ modelTextureIndex ] then
			outputDebugString ( "Выбранного материала не существует", 1 )
			return
		end
	end
	
	local uScale = self:getControl ( "u" ):getData ( )
	local vScale = self:getControl ( "v" ):getData ( )
	
	triggerServerEvent ( "onChangeTCTMaterial", element, modelTextureIndex, textureId, uScale, vScale )
end

addEvent ( "onClientPlayerRoomJoin", true )
addEventHandler ( "onClientPlayerRoomJoin", localPlayer,
	function ( room )
		if Editor.started then
			Tool.getControl ( toolMaterial, "mat" ):setData ( "Материал" )
			toolMaterial.materialId = nil
		end
	end
)

--------------------------------------
-- Sign
--------------------------------------
local signModels = {
	{ "Sign", 3337 }
}

toolSign = {
	name = "Sign",
	desc = "Для того чтобы создать табличку, введите текст, выберите место и нажмите [num5] для ее создания.",
	group = groupGraph,
	
	controls = {
		{
			"combobox",
			
			id = "sign",
			text = _LD"TSign_Mdl",
			items = signModels,
			
			onAccepted = function ( )
				local signIndex = Tool.getControl ( toolSign, "sign" ):getData ( )
				local signModel = signModels [ signIndex + 1 ] [ 2 ]
				
				local sign = createObject ( signModel, g_entityOffset.calcPosition ( ) )
				if sign then
					Editor.setTarget ( sign )
				end
			end
		},
		{
			"edit",
			
			id = "txt",
			text = _LD"TSign_Txt"
		}
	},
	
	onCancel = _resetTarget
}

function toolSign:onSelected ( )
	local monitor = createObject ( signModels [ 1 ] [ 2 ], g_entityOffset.calcPosition ( ) )
	if monitor then
		Editor.setTarget ( monitor )
	end
end

function toolSign:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
	
	local text = self:getControl ( "txt" ):getData ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz, 1,
													{ "txt", text },
													{ "tag", "Sign" } )
end

--------------------------------------
-- Blueprint tool
--------------------------------------
toolBlueprint = {
	name = "Blueprint",
	group = groupWorld,
	
	onCancel = _resetTarget
}

function toolBlueprint:onAccept ( element )
	if getElementType ( element ) ~= "object" then
		return
	end
	
	
	toolBlueprint.createObject ( 
		getElementModel ( element ) 
	)
end

function toolBlueprint:onWorldAccept ( )
	local worldModel = getPedWorldTarget ( )
	if worldModel then
		toolBlueprint.createObject ( worldModel )
	end
end

function toolBlueprint:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
	
	triggerServerEvent ( "onCreateTCTObject", resourceRoot, getElementModel ( element ), x, y, z, rx, ry, rz, 1 )
end

function toolBlueprint.createObject ( model )
	local object = createObject ( model, g_entityOffset.calcPosition ( ) )
	if object then
		Editor.setTarget ( object )
	end
end

--------------------------------------
-- Protect tool
--------------------------------------
toolProtect = {
	name = "Protect",
	desc = "Для того чтобы защитить объект от случайных изменений, прицельтесь на него и нажмите [num3].",
	group = groupWorld
}

function toolProtect:onAccept ( element )
	server.toggleEntityProtect ( element )
end

--------------------------------------
-- Water tool
--------------------------------------
toolWater = {
	name = "Water",
	group = groupWorld,
	
	onCancel = function ( )
		WaterEntity.destroyWaterFake ( )
		_resetTarget ( )
	end
}

function toolWater:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local sizeX, sizeY = g_entityOffset.calcScale ( )
	--outputChatBox(sizeX .. ", " .. sizeY)
	local water = WaterEntity.createWaterFake ( x, y, z, sizeX, sizeY )
	if water then
		Editor.setTarget ( water )
	end
end

function toolWater:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local sizeX, sizeY = g_entityOffset.calcScale ( )
	--local rotx, roty, rotz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
	
	server.createTCTWater ( x, y, z, sizeX, sizeY )
end

function toolWater:onChangeOffset ( element )
	local sx, sy, sz = g_entityOffset.calcScale ( )
		
	setElementData ( element, "width", sx, false )
	setElementData ( element, "depth", sy, false )
end

--------------------------------------
-- LOD tool
--------------------------------------
toolLOD = {
	name = "LOD",
	--desc = "Чтобы изменить прозрачность объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
	
	controls = {
		{
			"edit",
			
			id = "mdl",
			text = "Model"
		},
		{
			"scrollbar",
			
			id = "dist",
			text = "Distance",
			value = {
				300,
				min = 100,
				max = 1000
			}
		}
	}
}

function toolLOD:onAccept ( element )
	local model = self:getControl ( "mdl" ):getData ( )
	local distance = self:getControl ( "dist" ):getData ( )

	server.setObjectLODModel ( element, model, distance )
end

--------------------------------------
-- Terrain tool
--------------------------------------
toolTerrain = {
	name = "Terrain",
	group = groupWorld,
	desc = "Для того чтобы перейти в режим редактирования ландшафта, нажмите и держите клавишу [X].",
}

--------------------------------------
-- Graph group
--------------------------------------
groupGraph = {
	name = "Graph"
}

--------------------------------------
-- Trigger tool
--------------------------------------
toolTrigger = {
	name = "Trigger",
	group = groupGraph,
	
	controls = {
		{
			"scrollbar",
			
			id = "size",
			text = _LD"TTrigger_Size",
			value = {
				1,
				min = 1,
				max = 10
			},
			
			onScroll = function ( )
				if Editor.target then
					local size = toolTrigger:getControl ( "size" ):getData ( )
					setElementData ( Editor.target, "size", size, false )
				end
			end
		},
		{
			"checkbox",
			
			id = "enbld",
			text = "Enabled",
			selected = true
		}
	},
	
	onCancel = _resetTarget
}

function toolTrigger:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local size = self:getControl ( "size" ):getData ( )
	
	local trigger = GameManager.createEntity ( "wbo:trigger", x, y, z, size )
	if trigger then
		setElementData ( trigger, "dimension", getElementDimension ( localPlayer ), false )
		Editor.setTarget ( trigger )
	end
end

function toolTrigger:onPlace ( element )
	--local x, y, z = g_entityOffset.calcPosition ( )
	local x, y, z = getElementPosition ( element )
	local size = self:getControl ( "size" ):getData ( )
	local enabled = self:getControl ( "enbld" ):getData ( )
	
	server.createTrigger ( x, y, z, size, enabled )
end

--------------------------------------
-- Area tool
--------------------------------------
toolArea = {
	name = "Area",
	group = groupGraph,
	
	onCancel = _resetTarget
}

function toolArea:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local sx, sy = g_entityOffset.calcScale ( )
	
	local area = GameManager.createEntity ( "wbo:area", x, y, z, math.max ( sx, 1 ), math.max ( sy, 1 ), 255, 0, 0 )
	if area then
		setElementData ( area, "dimension", getElementDimension ( localPlayer ), false )
		Editor.setTarget ( area )
	end
end

function toolArea:onPlace ( element )
	--local x, y, z = g_entityOffset.calcPosition ( )
	local x, y, z = getElementPosition ( element )
	local sx, sy = g_entityOffset.calcScale ( )
	
	server.createArea ( x, y, z, math.max ( sx, 1 ), math.max ( sy, 1 ) )
end

function toolArea:onChangeOffset ( element )
	local sx, sy = g_entityOffset.calcScale ( )
	--setElementData ( element, "width", math.max ( sx, 1 ), false )
	--setElementData ( element, "depth", math.max ( sy, 1 ), false )
	AreaEntity.setSize ( element, math.max ( sx, 1 ), math.max ( sy, 1 ) )
end

--------------------------------------
-- Marker tool
--------------------------------------
local MARKER_ALPHA = 240
local CONTROL_MODEL = 2969
local markerTable
local markerTypes = {
	{ "checkpoint" },
	{ "ring" },
	{ "cylinder" }, 
	{ "arrow" },
	{ "corona" }
}

function markerChange ( )
	if isElement ( Editor.target ) ~= true or getElementType ( Editor.target ) ~= "marker" then
		return
	end
	
	setMarkerColor ( Editor.target, toolMarker:getControl ( "r" ):getData ( ), 
                                  toolMarker:getControl ( "g" ):getData ( ), 
                                  toolMarker:getControl ( "b" ):getData ( ), MARKER_ALPHA )
	setMarkerSize ( Editor.target, toolMarker:getControl ( "size" ):getData ( ) )
	
	local typeIndex = Tool.getControl ( toolMarker, "type" ):getData ( )
	setMarkerType ( Editor.target, markerTypes [ typeIndex + 1 ] [ 1 ] )
end

toolMarker = { 
	name = "Marker",
	group = groupGraph,
	
	controls = {
		{
			"scrollbar",
			
			id = "r",
			text = "Red",
			value = {
				255,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		{
			"scrollbar",
			
			id = "g",
			text = "Green",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		{
			"scrollbar",
			
			id = "b",
			text = "Blue",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},		
		{
			"scrollbar",
			
			id = "size",
			text = "Size",
			value = {
				2,
				min = 1,
				max = 6
			},
			onScroll = markerChange
		},		
		{
			"combobox",
			
			id = "type",
			text = "Тип",
			items = markerTypes,
			onAccepted = markerChange
		}
	}
}

function toolMarker:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	
	local typeIndex = self:getControl ( "type" ):getData ( )
	local markerType = markerTypes [ typeIndex + 1 ] [ 1 ]

	local marker = createMarker ( x, y, z, 
		markerType, 
		self:getControl ( "size" ):getData ( ), 
		self:getControl ( "r" ):getData ( ), self:getControl ( "g" ):getData ( ), self:getControl ( "b" ):getData ( ), 
		MARKER_ALPHA )
	
	if marker then
		Editor.setTarget ( marker )
	end
end

function toolMarker:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
		
	local typeIndex = self:getControl ( "type" ):getData ( )
	local markerType = markerTypes [ typeIndex + 1 ] [ 1 ]
		
	server.createEditorMarker (
		x, y, z, -- Положение маркера
		markerType, --Тип маркера
		self:getControl ( "size" ):getData ( ), --Размер маркера
		self:getControl ( "r" ):getData ( ), --Цвет маркера
		self:getControl ( "g" ):getData ( ),
		self:getControl ( "b" ):getData ( ) 
	)
end

function toolMarker:onCancel ( ) 
	markerTable = nil
	_resetTarget ( )
end

--------------------------------------
-- Laser tool
--------------------------------------
local LASER_MODEL = 1213
local laserState = { }
local streamedInLasers = { }

local function isElementLaser ( element )
	return getElementType ( element ) == "object" and getElementModel ( element ) == LASER_MODEL
end

local function _changeLaserState ( laser, state )
	local lx, ly, lz = getElementPosition ( laser )

	local minDist, minPlayer = 6000, nil
	local players = getElementsByType ( "player" )
	for _, player in ipairs ( players ) do
		local px, py, pz = getElementPosition ( player )
		local dist = getDistanceBetweenPoints3D ( lx, ly, lz, px, py, pz )
		
		if dist < minDist then
			minDist, minPlayer = dist, player
		end
	end
	
	if minPlayer == localPlayer then
		triggerServerEvent ( "onLaserStateChange", laser, state )
	end
end

addEventHandler ( "onClientPreRender", root,
	function ( )
		for laser, _ in pairs ( streamedInLasers ) do
			if isElement ( laser ) then
				local isLaserLocal = isElementLocal ( laser )
				
				--Конвертим из number в bool
				local chkBlds = getElementData ( laser, "chkBlds" ) == "1"
				local chkVhls = getElementData ( laser, "chkVhls" ) == "1"
				local chkPlrs = getElementData ( laser, "chkPlrs" ) == "1"
				local chkObjs = getElementData ( laser, "chkObjs" ) == "1"
				
				local isValid = chkBlds or chkVhls or chkPlrs or chkObjs
				
				--Можем ли мы перейти к обработке и отрисовке
				if isValid or isLaserLocal then
					local lColor = color.green
					local lX, lY, lZ = getElementPosition ( laser )
					local fX, fY, fZ = getElementPositionByOffset ( laser, 
						0, 0, tonumber ( getElementData ( laser, "lnh" ) ) or 1 
					)
					local hit, hX, hY, hZ, hElement = processLineOfSight ( lX, lY, lZ, fX, fY, fZ, chkBlds, chkVhls, chkPlrs, chkObjs )
		
					--Если луч столкнулся с преградой
					local isCollide = hit and ( not hElement or isElementLocal ( hElement ) ~= true ) and isLaserLocal ~= true
					if isCollide then
						fX, fY, fZ = hX, hY, hZ
						lColor = color.red
					end
					
					if laserState [ laser ] ~= isCollide then
						laserState [ laser ] = isCollide
						
						_changeLaserState ( laser, isCollide )
					end
     
					dxDrawLine3D ( lX, lY, lZ, fX, fY, fZ, lColor, 1 )
				end
			end
		end
	end 
)

addEventHandler ( "onClientElementStreamIn", resourceRoot,
	function ( )
		if isElementLaser ( source ) ~= true then return end;
		
		streamedInLasers [ source ] = true
    end
)

addEventHandler ( "onClientElementStreamOut", resourceRoot,
    function ( )
		if isElementLaser ( source ) then
			if streamedInLasers [ source ] then
				streamedInLasers [ source ] = nil
			end
		end
    end
)

addEventHandler ( "onClientElementDestroy", resourceRoot,
	function ( )
		if isElementLaser ( source ) ~= true then
			if streamedInLasers [ source ] then
				streamedInLasers [ source ] = nil
			end
		end
	end
)

toolLaser = {
	name = "Laser",
	group = groupGraph,
	
	controls = {
		{
			"scrollbar",
			
			id = "lnh",
			text = _LD"TLaser_Lnh",
			value = { 
				40,
				min = 1,
				max = 40
			},
			
			
			onScroll = function ( )
				setElementData ( Editor.target, "lnh", 
					Tool.getControl ( toolLaser, "lnh" ):getData ( ) 
				)
			end
		},
		{
			"checkbox",
			
			id = "chk_build",
			text = _LD"TLaser_CBuild",
			selected = false
		},		
		 {
			"checkbox",
			
			id = "chk_vehs",
			text = _LD"TLaser_CVehs",
			selected = true
		},		
		{
			"checkbox",
			
			id = "chk_player",
			text = _LD"TLaser_CPlayer",
			selected = true
		},
		{
			"checkbox",
			
			id = "chk_objs",
			text = _LD"TLaser_CObjs",
			selected = false
		},
	},

	onCancel = _resetTarget
}

function toolLaser:onSelected ( )
	local laser = createObject ( LASER_MODEL, g_entityOffset.calcPosition ( ) )
	
	if laser then
		setElementData ( laser, "lnh", self:getControl ( "lnh" ):getData ( ) )
   
		Editor.setTarget ( laser )
	end
end

function toolLaser:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
	
	--Конвертим bool настройки в number и виде строки для сохранения
	local chkBlds = self:getControl ( "chk_build" ):getData ( ) and "1" or "0"
	local chkVhls = self:getControl ( "chk_vehs" ):getData ( ) and "1" or "0"
	local chkPlrs = self:getControl ( "chk_player" ):getData ( ) and "1" or "0"
	local chkObjs = self:getControl ( "chk_objs" ):getData ( ) and "1" or "0"

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                   x, y, z,
                                                   rx, ry, rz, 1,
 												   { "chkBlds", chkBlds },
												   { "chkVhls", chkVhls },
												   { "chkPlrs", chkPlrs },
                                                   { "chkObjs", chkObjs },
                                                   { "lnh", tostring ( self:getControl ( "lnh" ):getData ( ) ) },
                                                   { "tag", "Laser" } )
end

--------------------------------------
-- Checkpoint
-- Чекпоинты
--------------------------------------
local chkpntTable

function createCheckpoint ( )
	if chkpntTable then
		if #chkpntTable < 1 then
			outputChatBox ( "TCT: To create a track, you must specify at least 1 node", 255, 0, 0 )
			
			return
		end
			
		local broadcastTable = { }
					
		for _, marker in ipairs ( chkpntTable ) do
			local nOX, nOY, nOZ = getElementPosition ( marker )
					
			table.insert ( broadcastTable, { nOX, nOY, nOZ } )
				
			destroyElement ( marker )
		end

		triggerServerEvent ( "onCreateWBOCheckpoint", resourceRoot, broadcastTable )
		
		chkpntTable = nil
			
		unbindKey ( "e", "down", createCheckpoint )
	end
end

toolCheckpoint = {
	name = "Checkpoint",
	desc = "Для создание новой трассы из чекпоинтов последовательно расположите маркеры, для чего вы должны выбрать место и нажать [num5]. Для завершения трассы нажмите [e]."
}

function toolCheckpoint:onSelected ( )
	chkpntTable = { }
		
	local x, y, z = g_entityOffset.calcPosition ( )
	
	local marker = createMarker ( x, y, z, "cylinder", 2 )
	if marker then
		Editor.setTarget ( marker )
			
		bindKey ( "e", "down", createCheckpoint )
		outputChatBox ( "Press [E] to save the track" )
	end
end

function toolCheckpoint:onPlace ( element )
	if #chkpntTable > 40 then
		outputChatBox ( "TCT: You can not specify more than 40 nodes for a one track" )
				
		return
	end
				
	local tOX, tOY, tOZ = getElementPosition ( element )
	local marker = createMarker ( tOX, tOY, tOZ, "cylinder", 2 )
	setElementDimension ( marker,
		getElementDimension ( localPlayer )
	)
				
	table.insert ( chkpntTable, marker )
end

function toolCheckpoint:onCancel ( element )
	for _, marker in ipairs ( chkpntTable ) do
		destroyElement ( marker )
	end
	chkpntTable = nil
	
	_resetTarget ( )
	unbindKey ( "e", "down", createTrack )
end

--Checkpoints
local checkpointImpl = { }

function checkpointImpl.init ( checkpointParent )
	local checkpoint = getElementChild ( checkpointParent, 0 )
	
	checkpointImpl.createCheckpoint ( checkpoint )
end

function checkpointImpl.createCheckpoint ( checkpoint )
	local x, y, z = getElementPosition ( checkpoint )
	
	local marker = createMarker ( x, y, z, "cylinder", 2 )
	
	local dimension = getElementData (
		getElementParent ( checkpoint ), "dimension"
	) or 0
	
	setElementDimension ( marker, dimension )
	
	setElementParent ( marker, checkpoint )
	
	addEventHandler ( "onClientMarkerHit", marker, checkpointImpl.hitEvent )
end

function checkpointImpl.destroyCheckpoint ( checkpoint )
	local marker = getElementChild ( checkpoint, 0 )
	
	removeEventHandler ( "onClientMarkerHit", marker, checkpointImpl.hitEvent )
	
	destroyElement ( marker )
end

function checkpointImpl.hitEvent ( player, matchingDimension )
	if not matchingDimension or player ~= localPlayer then
		return
	end
	
	local checkpoint = getElementParent ( source )
	
	triggerServerEvent ( "onPlayerCheckpointReached", checkpoint )
	checkpointImpl.destroyCheckpoint ( checkpoint )
	
	local nextId = getElementData ( checkpoint, "nextid" )
	if not nextId then
		triggerServerEvent ( "onPlayerCheckpointFinish", checkpoint )
		
		checkpointImpl.init ( getElementParent ( checkpoint ) )
		
		return
	end
	
	local nextCheckpoint = getElementByID ( nextId )
	
	checkpointImpl.createCheckpoint ( nextCheckpoint )
end

--[[addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local checkpoints = getElementsByType ( "checkpoints", resourceRoot )
		for _, checkpointParent in ipairs ( checkpoints ) do
			checkpointImpl.init ( checkpointParent )
		end
	end
, false )]]

addEvent ( "onClientCheckpointCreated", true )
addEventHandler ( "onClientCheckpointCreated", resourceRoot,
	function ( )
		checkpointImpl.init ( source )
	end
)

--------------------------------------
-- Spawnpoint
--------------------------------------
--[[
	Принятые выражения:
		0 : спавн указанной модели
		0-15 : спавн в диапазоне моделей
		0> : спавн любой модели выше или равно указанной
		<0 : спавн любой модели ниже или равно указанной
]]
--[[local specChars = {
	{ "-", function ( a, b ) return tonumber ( a ) ~= nil and tonumber ( b ) ~= nil; end; }, -- '-'
	{ ">", function ( a ) return tonumber ( a ) ~= nil end; }, -- '>'
	{ "<", function ( a ) return tonumber ( a ) ~= nil; end; } -- "<"
}
function checkModelExpression ( model )
	if tonumber ( model ) and tonumber ( model ) >= 0 then return true end;

	for _, char in ipairs ( specChars ) do
		local a = gettok ( model, 1, char [ 1 ] )
		local b = gettok ( model, 2, char [ 1 ] )
		outputChatBox ( "'" .. tostring ( a ) .. "', '" .. tostring ( b ) .. "'" )
		if char [ 2 ] ( a, b ) then
			return true
		end
	end
end

addCommandHandler ( "checkmodel", function ( _, model )
	if checkModelExpression ( model ) then
		outputChatBox ( "Все ОК!" )
	else
		outputChatBox ( "Ошибка!")
	end
end)]]

toolSpawnpoint = {
	name = "Spawnpoint",
	group = groupGraph,
	desc = "Для создание точки спавна выберите место и нажмите [num5].",
	
	controls = {
		{
			"combobox",
			
			id = "type",
			text = "Type",
			items = { "Vehicle", "Ped" }
		},
		{
			"edit",
			
			id = "mdl",
			text = "Model",
			value = ""
		},
		{
			"checkbox",
			
			id = "autospwn",
			text = "Autospawn",
			selected = true
		},
	},
	
	onCancel = _resetTarget
}

function toolSpawnpoint:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local _, _, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
				
	local spawnpoint = GameManager.createEntity ( "wbo:spawnpoint", x, y, z, rz )
	if spawnpoint then
		Editor.setTarget ( spawnpoint )
	end
end

function toolSpawnpoint:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local _, _, rz = g_entityOffset.calcRotation ( getPedRotation ( localPlayer ) )
	
	local model = self:getControl ( "mdl" ):getData ( )
	local type = self:getControl ( "type" ):getData ( )
	local autospwn = self:getControl ( "autospwn" ):getData ( )

	if autospwn ~= true then
		server.createSpawnpoint ( x, y, z, rz )
		return
	end
	
	if utfLen ( model ) > 0 then
		local spType = type > 0 and "ped" or "vehicle"
		local modelType = getModelType ( model )
		if spType ~= modelType then
			outputChatBox ( "TCT: Models with this ID does not exist", 200, 0, 0 )
			return
		end
	end

	server.createSpawnpoint ( x, y, z, rz, model, type )
end

--------------------------------------
-- Path
--------------------------------------
toolTrack = {
	name = "Path",
	desc = "Для создания пути необходимо прицелиться на объект и нажать [num3]. Следом вы должны указать ключевые точки, для этого выберите место и нажмите [num5]. Для завершения трека нажмите [e]. Кроме того вы можете включить вращение.",
	
	controls = {
		{
			"checkbox",
			
			id = "rot",
			text = _LD"TPath_Rot",
			selected = false
		}
	}
}

local function createTrack ( )
	if getElementChildrenCount ( toolTrack.path ) < 1 then
		outputChatBox ( _LD"TPathMsg_NodeCntW", 255, 0, 0 )
			
		return
	end
	
	local broadcastTable = { }
	
	local rotation = Tool.getControl ( toolTrack, "rot" ):getData ( )
	local trackNodes = getElementChildren ( toolTrack.path, "path:node" )
	for _, node in ipairs ( trackNodes ) do
		local nOX, nOY, nOZ = getElementPosition ( node )
		local rx, ry, rz = getElementData ( node, "rotX" ), getElementData ( node, "rotY" ), getElementData ( node, "rotZ" )
		if rotation then
			table.insert ( broadcastTable, { nOX, nOY, nOZ, rx, ry, rz } )
		else
			table.insert ( broadcastTable, { nOX, nOY, nOZ } )
		end
	end
	
	triggerServerEvent ( "onCreateWBOTrack", resourceRoot, broadcastTable )

	setSelectedTool ( toolDefault )
end

function toolTrack:onSelected ( )
	toolTrack.path = createElement ( "path" )
	setElementData ( toolTrack.path, "dimension", getElementDimension ( localPlayer ) )
end

function toolTrack:onAccept ( element )
	local x, y, z = g_entityOffset.calcPosition ( )
	
	local entity = createEntity ( getElementModel ( element ), x, y, z )
	if entity then
		Editor.setTarget ( entity )
			
		bindKey ( "e", "down", createTrack )
		outputChatBox ( _LD"TPathMsg_PressE" )
	end
end

function toolTrack:onPlace ( element )
	local nodesNum = getElementChildrenCount ( toolTrack.path )
	if Editor.permissionStatus ~= true and nodesNum > 40 then
		outputChatBox ( _LD"TPathMsg_NodeCntW2" )
				
		return
	end
				
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = getElementRotation ( element )
	toolTrack.node = GameManager.createEntity ( "path:node", x, y, z )
	--toolTrack.node = PathEntity.create ( x, y, z )
	setElementData ( toolTrack.node, "rotX", rx, false )
	setElementData ( toolTrack.node, "rotY", ry, false )
	setElementData ( toolTrack.node, "rotZ", rz, false )
	setElementData ( toolTrack.node, "index", nodesNum + 1, false )
	setElementData ( toolTrack.node, "nextIndex", nodesNum + 2, false )
	setElementParent ( toolTrack.node, toolTrack.path )
	
	triggerEvent ( "onClientElementCreate", toolTrack.node )
end

function toolTrack:onCancel ( element )
	if element then
		destroyElement ( toolTrack.path )
		unbindKey ( "e", "down", createTrack )
	end
	
	_resetTarget ( )
end

--------------------------------------
-- Pickup tool
--------------------------------------
local pickupIDs = {
	{ "Health", "health" },
	{ "Armor", "armor" },
	{ "[1] Brassknuckle", 1 },
	{ "[2] Golfclub", 2 },
	{ "[3] Nightstick", 3 },
	{ "[4] Knife", 4 },
	{ "[5] Bat", 5 },
	{ "[6] Shovel", 6 },
	{ "[7] Poolstick", 7 },
	{ "[8] Katana", 8 },
	{ "[9] Chainsaw", 9 },
	{ "[10] Dildo 1", 10 },
	{ "[11] Dildo 2", 11 },
	{ "[12] Vibrator 1", 12 },
	{ "[13] Vibrator 2", 13 },
	{ "[14] Flower", 14 },
	{ "[15] Cane", 15 },
	{ "[16] Grenade", 16 },
	{ "[17] Teargas", 17 },
	{ "[18] Molotov", 18 },
	{ "[22] Colt 45", 22 },
	{ "[23] Silenced", 23 },
	{ "[24] Deagle", 24 },
	{ "[25] Shotgun", 25 },
	{ "[26] Sawed-off", 26 },
	{ "[27] Combat Shotgun", 27 },
	{ "[28] Uzi", 28 },
	{ "[29] MP5", 29 },
	{ "[30] AK-47", 30 },
	{ "[31] M4", 31 },
	{ "[32] Tec-9", 32 },
	{ "[33] Rifle", 33 },
	{ "[34] Sniper", 34 },
	{ "[35] Rocket Launcher", 35 },
	{ "[36] Rocket Launcher HS", 36 },
	{ "[37] Flamethrower", 37 },
	{ "[38] Minigun", 38 },
	{ "[39] Satchel", 39 },
	{ "[40] Satchel Detonator", 40 },
	{ "[41] Spraycan", 41 },
	{ "[42] Fire Extinguisher", 42 },
	{ "[43] Camera", 43 },
	{ "[44] Nightvision goggles", 44 },
	{ "[45] Infrared goggles", 45 },
	{ "[46] Parachute", 46 }
}

local function pickupChange ( )
	local pickupIndex = Tool.getControl ( toolPickup, "type" ):getData ( )
	local pickupType = pickupIDs [ pickupIndex + 1 ] [ 2 ]
	local pickupAmount = Tool.getControl ( toolPickup, "amount" ):getData ( )
	--local pickupRespawnTime = self:getControl ( "resptime" ):getData ( )
	
	local pType, pAmount, pAmmo
	if pickupType == "health" then
		pType = 0
		pAmount = pickupAmount
	elseif pickupType == "armor" then
		pType = 1
		pAmount = pickupAmount
	else
		pType = 2
		pAmount = tonumber(pickupType)
		pAmmo = pickupAmount
	end
	
	setPickupType ( Editor.target, pType, pAmount )
end

toolPickup = { 
	name = "Pickup",
	group = groupGraph,
	
	controls = {
		{
			"combobox",
			
			id = "type",
			text = "Type",
			items = pickupIDs,
			onAccepted = pickupChange
		},
		{
			"edit",
			
			id = "amount",
			text = "Amount",
			value = "1"
		},
		{
			"edit",
			
			id = "resptime",
			text = "Time",
			value = "1000"
		},
	},
	
	onCancel = _resetTarget
}

function toolPickup:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	
	local pickupIndex = self:getControl ( "type" ):getData ( )
	local pickupType = pickupIDs [ pickupIndex + 1 ] [ 2 ]
	local pickupAmount = self:getControl ( "amount" ):getData ( )
	local pickupRespawnTime = self:getControl ( "resptime" ):getData ( )
	
	local pType, pAmount, pAmmo
	if pickupType == "health" then
		pType = 0
		pAmount = pickupAmount
	elseif pickupType == "armor" then
		pType = 1
		pAmount = pickupAmount
	else
		pType = 2
		pAmount = tonumber(pickupType)
		pAmmo = pickupAmount
	end
		
	local pickup
	if pAmmo then
		pickup = createPickup(x, y, z, pType, pAmount, pickupRespawnTime, pAmmo)
	else
		pickup = createPickup(x, y, z, pType, pAmount, pickupRespawnTime )
	end
	
	Editor.setTarget ( pickup )
end

function toolPickup:onPlace ( element )
	local x, y, z = g_entityOffset.calcPosition ( )

	local pickupIndex = self:getControl ( "type" ):getData ( )
	local pickupType = pickupIDs [ pickupIndex + 1 ] [ 2 ]
	local pickupAmount = self:getControl ( "amount" ):getData ( )
	local pickupRespawnTime = self:getControl ( "resptime" ):getData ( )
	
	triggerServerEvent ( "createWBOPickup", resourceRoot, x, y, z, pickupType, pickupAmount, pickupRespawnTime )
end

--------------------------------------
-- Empty tool
--------------------------------------
toolEmpty = {
	name = "Empty",
	group = groupGraph,
	
	controls = {
		{
			"edit",
			
			id = "nm",
			text = _LD"TEmpty_Name",
			value = ""
		}
	},
	
	onCancel = _resetTarget
}

function toolEmpty:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local empty = GameManager.createEntity ( "empty", x, y, z )
	if empty then
		setElementData ( empty, "dimension", getElementDimension ( localPlayer ), false )
		Editor.setTarget ( empty )
	end
end

function toolEmpty:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	
	local name = self:getControl ( "nm" ):getData ( )

	server.createEmpty ( x, y, z, name )
end

--------------------------------------
-- Action tool
--------------------------------------
toolAction = {
	name = "Action",
	group = groupGraph,
	
	controls = {
		{
			"edit",
			
			id = "itms",
			text = _LD"TAction_Itms",
			value = "Action 1,Action 2"
		},
		{
			"edit",
			
			id = "offs",
			text = _LD"TAction_Off",
			value = "0,0,0"
		}
	}
}

function toolAction:onAccept ( element )
	--Считываем и проверям правильно ли игрок заполнил поле Действия
	local itemsStr = self:getControl ( "itms" ):getData ( )
	local items = split ( itemsStr, 44 )
	
	if #items < 1 or #items > 10 then
		outputChatBox ( _LD"TActionMsg_Warn1", 255, 0, 0 )
		return
	end
	
	for _, item in ipairs ( items ) do
		if utfLen  ( item ) > 12 then
			outputChatBox ( _LD"TActionMsg_Warn2", 255, 0, 0 )
			return
		end
	end
	
	local offsetStr = self:getControl ( "offs" ):getData ( )
	local offsetValues = split ( offsetStr, 44 )
	
	if #offsetValues ~= 3 then
		outputChatBox ( _LD"TActionMsg_Warn3", 255, 0, 0 )
		return
	end
	
	local offset = { }
	
	for i, value in ipairs ( offsetValues ) do
		value = tonumber ( value )
		if not value then
			outputChatBox ( _LD"TActionMsg_Warn4", 255, 0, 0 )
			return
		end
		
		offset [ i ] = value
	end

	server.setEntityAction ( element, itemsStr, unpack ( offset ) )
end

--------------------------------------
-- Data tool
--------------------------------------
toolData = {
	name = "Data",
	group = groupGraph,
	
	controls = {
		{
			"edit",
			
			id = "key",
			text = "Key",
			value = ""
		},
		{
			"edit",
			
			id = "val",
			text = "Value",
			value = ""
		}
	}
}

local dataChars = { 113, 119, 101, 114, 116, 121, 117, 105, 111, 112, 97, 115, 100, 102, 103, 104, 106, 107, 108, 122, 120, 99, 118, 98, 110, 109, 49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 81, 87, 69, 82, 84, 89, 85, 73, 79, 80, 65, 83, 68, 70, 71, 72, 74, 75, 76, 90, 88, 67, 86, 66, 78, 77 }
local function checkDataStr ( dataStr, isKey )
	if type ( dataStr ) == "string" then
		if utfLen ( dataStr ) < 1 then
			return
		end
	
		-- Если первый символ является числом, выходим из функции
		if isKey and tonumber ( utfSub ( dataStr, 1, 1 ) ) then
			return
		end
	
		-- Если строка содержит недопустимые знаки, выходим из функции
		for i = 1, utfLen ( dataStr ) do
			local char = utfSub ( dataStr, i, i )
			if not table.find ( dataChars, utfCode ( char ) ) then
				return
			end
		end
		
		return true
	end
end

function toolData:onAccept ( element )
	local keyStr = self:getControl ( "key" ):getData ( )
	if checkDataStr ( keyStr, true ) ~= true then
		outputChatBox ( _LD"TDataWarn3", 255, 0, 0 )
		return
	end
	
	local valueStr = self:getControl ( "val" ):getData ( )
	if checkDataStr ( valueStr ) ~= true then
		outputChatBox ( _LD"TDataWarn3", 255, 0, 0 )
		return
	end
	
	server.setEntityData ( element, keyStr, valueStr )
end

--------------------------------------
-- Weapon tool
--------------------------------------
local weaponTypes = {
	{ "colt 45" },
	{ "silenced" },
	{ "deagle" },
	{ "uzi" },
	{ "mp5" },
	{ "ak-47" },
	{ "m4" },
	{ "tec-9" },
	{ "rifle" },
	{ "sniper" },
	{ "rocket launcher" },
	{ "rocket launcher hs" },
	{ "flamethrower" },
	{ "minigun" },
	{ "satchel" },
	{ "bomb" },
	{ "spraycan" },
	{ "fire extinguisher" },
	{ "camera" }
}

local function weaponChange ( )
	local index = Tool.getControl ( toolWeapon, "type" ):getData ( )
	local weaponType = weaponTypes [ index + 1 ]
	if weaponType then
		local x, y, z = g_entityOffset.calcPosition ( )
		local weapon = createWeapon ( weaponType [ 1 ], x, y, z )
		if weapon then
			Editor.setTarget ( weapon )
		end
	end
end

toolWeapon = {
	name = "Weapon",
	group = groupGraph,
	
	controls = {
		{
			"combobox",
			
			id = "type",
			text = _LD"TWeapTp",
			items = weaponTypes,
			onAccepted = weaponChange
		}
	},
	
	onCancel = _resetTarget
}

function toolWeapon:onSelected ( )
	local index = self:getControl ( "type" ):getData ( )
	local weaponType = weaponTypes [ index + 1 ]
	if weaponType then
		local x, y, z = g_entityOffset.calcPosition ( )
		local weapon = createWeapon ( weaponType [ 1 ], x, y, z )
		if weapon then
			Editor.setTarget ( weapon )
		end
	end
end

function toolWeapon:onPlace ( element )
	local index = self:getControl ( "type" ):getData ( )
	local weaponType = weaponTypes [ index + 1 ]
	if weaponType then
		local x, y, z = getElementPosition ( element )
		local rx, ry, rz = getElementRotation ( element )
	
		server.createWeapon ( weaponType [ 1 ], x, y, z, rx, ry, rz )
	end
end

function toolWeapon:onChangeOffset ( element )
	local sx, sy = g_entityOffset.calcScale ( )
	setElementData ( element, "width", math.max ( sx, 1 ), false )
	setElementData ( element, "depth", math.max ( sy, 1 ), false )
end

--------------------------------------
-- Blip tool
--------------------------------------
local _blipicons = {
	{ "Marker" },
	{ "White_square" },
	{ "Centre" },
	{ "Map_here" },
	{ "North" },
	{ "Airyard" },
	{ "Gun" },
	{ "Barbers" },
	{ "Big_smoke" },
	{ "Boatyard" },
	{ "Burgershot" },
	{ "Bulldozer" },
	{ "Cat_pink" },
	{ "Cesar" },
	{ "Chicken" },
	{ "Cj" },
	{ "Crash1" },
	{ "Diner" },
	{ "Emmetgun" },
	{ "Enemyattack" },
	{ "Fire" },
	{ "Girlfriend" },
	{ "Hospital" },
	{ "Loco" },
	{ "Madd Dogg" },
	{ "Mafia" },
	{ "Mcstrap" },
	{ "Mod_garage" },
	{ "Ogloc" },
	{ "Pizza" },
	{ "Police" },
	{ "Property_green" },
	{ "Property_red" },
	{ "Race" },
	{ "Ryder" },
	{ "Savehouse" },
	{ "School" },
	{ "Mystery" },
	{ "Sweet" },
	{ "Tattoo" },
	{ "Truth" },
	{ "Waypoint" },
	{ "Toreno_ranch" },
	{ "Triads" },
	{ "Triads_casino" },
	{ "Tshirt" },
	{ "Woozie" },
	{ "Zero" },
	{ "Date_disco" },
	{ "Date_drink" },
	{ "Date_food" },
	{ "Truck" },
	{ "Cash" },
	{ "Flag" },
	{ "Gym" },
	{ "Impound" },
	{ "Runway_light" },
	{ "Runway" },
	{ "Gang_b" },
	{ "Gang_p" },
	{ "Gang_y" },
	{ "Gang_n" },
	{ "Gang_g" },
	{ "Spray" }
}

toolBlip = {
	name = "Blip",
	group = groupGraph,
	
	controls = {
		{
			"combobox",
			
			id = "icn",
			text = "Icon",
			items = _blipicons
		}
	},
	
	onCancel = _resetTarget
}

function toolBlip:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	local blip = GameManager.createEntity ( "tct-blip", x, y, z )
	if blip then
		setElementData ( blip, "dimension", getElementDimension ( localPlayer ), false )
		Editor.setTarget ( blip )
	end
end

function toolBlip:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local icon = self:getControl ( "icn" ):getData ( )

	server.createEditorBlip ( x, y, z, icon )
end

--------------------------------------
-- FlowEditor
--------------------------------------
toolGraph = {
	name = "FlowEditor",
	desc = "Для того чтобы прикрепить схему к объекту прицельтесь на него и нажмите клавишу действия [num3]. Для того чтобы удалить схему с объекта нажмите [B].",

	onSelected = function ( )
		addEventHandler ( "onClientPlayerTCTTarget", localPlayer, toolGraph.onPlayerTarget )
		bindKey ( "b", "down", toolGraph.onKey )
		
		local target = GameManager.getTargetElement ( )
		toolGraph.onPlayerTarget ( target )
	end,
	onCancel = function ( )
		removeEventHandler ( "onClientPlayerTCTTarget", localPlayer, toolGraph.onPlayerTarget )
		unbindKey ( "b", "down", toolGraph.onKey )
		ActionList.setTargetElement ( false )
		toolGraph.targetGraphs = nil
		Editor.selectGraph = nil
	end
}

function toolGraph:onAccept ( element )
	local graphs = self.targetGraphs
	local selectedItem = ActionList.getSelectedItem ( )
	
	-- Добавить схему
	if selectedItem > #graphs then
		Editor.selectGraph = element
		guiSetVisible ( editorForm.wnd, true )
		showCursor ( true )
		guiSetInputEnabled ( true )
		guiSetSelectedTab ( editorForm.leftPanel, editorForm.graphTab )
		outputChatBox ( "TCT: Select or create a graph to apply it to the object", 0, 200, 0 )
	else
		local now = getTickCount ( )
		if toolGraph.request then
			if now - toolGraph.request [ 3 ] < 1000 then
				outputChatBox ( _LD"TGraphMsh_Info1" )
				return
			end
		end
		
		if isElement ( graphs [ selectedItem ] ) then
			local id = getElementData ( graphs [ selectedItem ], "id", false )
			toolGraph.request = { id, element, now }
			requestGraph ( id, toolGraph.onRequestGraph )
		end
	end
end

function toolGraph.onRequestGraph ( id, packedGraph )
	local requestData = toolGraph.request
	if requestData [ 1 ] == id then
		local graph = EditorGraph.create ( id )
		graph:unpack  ( packedGraph )
		if NEWorkspace.open ( graph ) then
			NEWorkspace.setTarget ( requestData [ 2 ] )
		end
	end
	
	toolGraph.request = nil
end

function toolGraph.onPlayerTarget ( target )
	if not target then
		ActionList.setTargetElement ( false )
		
		return
	end
	
	if getElementType ( target ) == "player" then
		return
	end
	
	local items = { }
	
	toolGraph.targetGraphs = getElementChildren ( target, "graph" )
	for i, graph in ipairs ( toolGraph.targetGraphs ) do
		local id = getElementData ( graph, "id", false )
		local graphStr = --[[id or ]]"Graph " .. i
		items [ i ] = graphStr .. " [B]"
	end
	
	items [ #items + 1 ] = "+Add"
	
	ActionList.setItems ( items )
	ActionList.setTargetElement ( target )
end

function toolGraph.onKey ( )
	local target = getPedTarget ( localPlayer )
	if target then
		local graphs = toolGraph.targetGraphs
		local selectedItem = ActionList.getSelectedItem ( )
	
		if isElement ( graphs [ selectedItem ] ) then
			local id = getElementData ( graphs [ selectedItem ], "id", false )
			triggerServerEvent ( "onElementDetachGraph", target, id )
		end
	end
end


function initTools ( )
	-- World
	createToolGroup ( groupWorld )

	createTool ( toolDefault )
	createTool ( toolGrab )
    createTool ( toolRemove )
    createTool ( toolAlpha )
	createTool ( toolDoubleSided )
	createTool ( toolFreeze )
	createTool ( toolAttach )
	createTool ( toolMaterial )
	createTool ( toolBlueprint )
	createTool ( toolProtect )
	--createTool ( toolWater )
	createTool ( toolLOD )
	createTool ( toolTerrain )
	
	-- Graph
	createToolGroup ( groupGraph )
	
	createTool ( toolTrigger )
	createTool ( toolArea )
	--createTool ( toolMarker )
	createTool ( toolLaser )
	--createTool ( toolMonitor )
	--createTool ( toolCheckpoint )
	createTool ( toolSpawnpoint )
	createTool ( toolTrack )
	--createTool ( toolPickup )
	createTool ( toolEmpty )
	createTool ( toolSign )
	createTool ( toolAction )
	createTool ( toolData )
	createTool ( toolWeapon )
	createTool ( toolBlip )
	createTool ( toolGraph )
	
	--Select the Default tool
	setSelectedTool ( toolDefault )
	
	--Here it is necessary to add a your specific tool
	
	return true
end

Tool = {
	collection = { }
}
Tool.__index = Tool

function createToolGroup ( group )
	group.row = guiGridListAddRow ( editorForm.toolsList )
	guiGridListSetItemText ( editorForm.toolsList, group.row, 1, group.name, true, false )
	
	return group
end

function createTool ( tool )
	--if not tool.hidden then
		tool.gui = guiCreateScrollPane ( 0.44, 0.02, 0.5, 0.96, true, editorForm.toolsTab )
	
		tool.header = guiCreateLabel ( 0.02, 0.02, 0.96, 0.04, tool.name, true, tool.gui )
		guiSetFont ( tool.header , "default-bold-small" )
	
		if not tool.hidden then
			--tool.row = guiGridListAddRow ( editorForm.toolsList )
			tool.row = guiGridListInsertRowAfter ( editorForm.toolsList, 
				tool.group and tool.group.row or guiGridListGetRowCount ( editorForm.toolsList ) 
			)
			guiGridListSetItemText ( editorForm.toolsList, tool.row, 1, tool.name, false, false )
		end
	
		if tool.controls then
			for _, tbl in ipairs ( tool.controls ) do
				tool.controls [ tbl.id ] = createControl ( tbl, tool.gui )
			end
		end
		
		guiSetVisible ( tool.gui, false )
	--end
	
	Tool.collection [ tool.name ] = tool
	setmetatable ( tool, Tool )
	
	return tool
end

function getToolFromName ( name )
	return Tool.collection [ name ]
end

function getSelectedTool ( )
	return Tool.selected
end

-- Export
function getSelectedToolName ( )
	if Tool.selected then
		return Tool.selected.name
	end
	return "Unknown"
end

function setSelectedTool ( tool )
	if Tool.selected then
		Tool.selected:setVisible ( false )
		
		--if Editor.target then
			Tool.selected:call ( "onCancel", Editor.target )
			Editor.setTarget ( )
		--end
	end

	tool:setVisible ( true )
	tool:call ( "onSelected" )
	Tool.selected = tool
	
	if getSettingByID ( "s_thelp" ):getData ( ) and tool.desc then
		createHelpForm ( tool:getName ( ), tool.desc )
	end
end

function Tool:call ( event, ... )
	if type ( self [ event ] ) ~= "function" then
		return false
	end

	local result, err = pcall ( self [ event ], self, ... )
	if not result then
		outputDebugString ( event .. " - " .. err )
		
		return false
	end
	
	return true
end

function Tool:setVisible ( selected )
	--if not self.hidden then
		guiSetVisible ( self.gui, selected )
	--end
end

function Tool:getName ( )
	return self.name
end

function Tool:getControl ( controlId )
	local control = self.controls [ controlId ]
	if control then
		return control
	end
	
	return false
end