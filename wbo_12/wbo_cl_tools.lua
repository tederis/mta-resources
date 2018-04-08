--------------------------------------
-- Default tool
--------------------------------------
toolDefault = {
	name = "Default",
	
	--The flag for the creation of hidden tools
	hidden = true
}

function toolDefault:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	triggerServerEvent ( "onCreateTCTObject", resourceRoot, getElementModel ( element ), x, y, z, g_entityOffset.calcRotation ( ) )
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
}

local grabTranslation

function toolGrab:onAccept ( element )
	grabTranslation = { 
		{ getElementPosition ( element ) },
		{ getElementRotation ( element ) },
		getElementAlpha ( element ),
		isElementDoubleSided ( element ) 
	}
	
	setEditorTarget ( element )
end

function toolGrab:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	triggerServerEvent ( "onPlaceTCTElement", element, x, y, z, g_entityOffset.calcRotation ( ) )
	
	setElementAlpha ( element, grabTranslation [ 3 ] )
	setElementDoubleSided ( element, grabTranslation [ 4 ] )
	
	setEditorTarget ( )

	grabTranslation = nil
end

function toolGrab:onCancel ( element )
	if not element then
		return
	end

	setElementPosition ( element, unpack ( grabTranslation [ 1 ] ) )
	setElementRotation ( element, unpack ( grabTranslation [ 2 ] ) )
	setElementAlpha ( element, grabTranslation [ 3 ] )
	setElementDoubleSided ( element, grabTranslation [ 4 ] )
						
	grabTranslation = nil
end

--------------------------------------
-- Remove tool
--------------------------------------
toolRemove = {
	name = "Remove",
	desc = "Для удаления объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
		
	controls = {
		[ "onl_athd" ] = {
			"checkbox",
			
			text = "Только приклеенные",
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
		[ "a_lvl" ] = {
			"scrollbar",
			
			text = "Прозрачность",
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
-- Scale tool
--------------------------------------
toolScale = {
	name = "Scale",
	desc = "Чтобы изменить размер объекта, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
	
	controls = {
		[ "scale" ] = {
			"scrollbar",
			
			text = "Размер",
			value = { 
				2,
				min = 0.5,
				max = 5
			}
		}
	}
}

function toolScale:onAccept ( element )
	if getElementType ( element ) ~= "object" then
		return
	end

	triggerServerEvent ( "onChangeTCTScale", element, self:getControl ( "scale" ):getData ( ) )
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
		outputChatBox ( "WBO: Этот инструмент работает только с объектами.", 255, 0, 0 )
		
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
		outputChatBox ( "WBO: Этот инстумент работает только с объектами и транспортными средствами.", 255, 0, 0 )
		
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
}

function toolAttach:onAccept ( element )
	if not attachTable then
		attachTable = { 
			element = element
		}
	elseif isElement ( attachTable.element ) then
		if attachTable.element == element then
			return
		end

		triggerServerEvent ( "onAttachTCTElement", attachTable.element, element )

		attachTable = nil
	end
end

function toolAttach:onCancel ( ) 
	attachTable = nil 
end


--------------------------------------
-- Sign
--------------------------------------
local SIGN_MODEL = 1778

toolSign = {
	name = "Sign",
	desc = "Для того чтобы создать табличку, введите текст, выберите место и нажмите [num5] для ее создания.",
	group = groupWorld,
	
	controls = {
		[ "txt" ] = {
			"edit",
			
			text = "Текст"
		}
	},
	
	onCancel = setEditorTarget
}

function toolSign:onSelected ( )
	local monitor = createObject ( SIGN_MODEL, g_entityOffset.calcPosition ( ) )
	if monitor then
		setEditorTarget ( monitor )
	end
end

function toolSign:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )
	
	local text = self:getControl ( "txt" ):getData ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
													{ "txt", text } )
end

--------------------------------------
-- Blueprint tool
--------------------------------------
toolBlueprint = {
	name = "Blueprint",
	group = groupWorld,
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
	local elementRadius = getElementRadius ( element )
	if elementRadius > 25 and editorForm.permission ~= true then
		outputChatBox ( "WBO: Вы не можете скопировать этот объект", 255, 0, 0 )
		
		return
	end

	local x, y, z = getElementPosition ( element )
	
	triggerServerEvent ( "onCreateTCTObject", resourceRoot, getElementModel ( element ), x, y, z, g_entityOffset.calcRotation ( ) )
end

function toolBlueprint.createObject ( model )
	local object = createObject ( model, g_entityOffset.calcPosition ( ) )
	if object then
		setEditorTarget ( object )
	end
end

--------------------------------------
-- Lock tool
--------------------------------------
toolLock = {
	name = "Lock",
	desc = "Для защиты объекта паролем, прицельтесь на него и нажмите [num3].",
	group = groupWorld,
		
	controls = {
		[ "pass" ] = {
			"edit",
			
			text = "Пароль"
		}
	}
}

function toolLock:onAccept ( element )
	local pass = self:getControl ( "pass" ):getData ( )
	
	if utfLen ( pass ) > 10 then
		outputChatBox ( "WBO: Пароль должен содержать в себе не больше 10 символов", 255, 0, 0 )
		
		return
	end	

	triggerServerEvent ( "onLockTCTElement", element, pass )
end

--------------------------------------
-- Area tool
--------------------------------------
local _areaShader
local AREA_HEIGHT = 2
local boxSides = {
	{ -1, 0 },
	{ 1, 0 },
	{ 0, -1 },
	{ 0, 1 }
}
local _drawSide = dxDrawMaterialSectionLine3D

local function _getDistSqrt ( x0, y0, x1, y1 )
	return (x1-x0)*(x1-x0) + (y1-y0)*(y1-y0)
end
local function _drawArea(area)
	local _, _, z = getElementPosition(localPlayer)
	local x, y = getElementPosition ( area )
	local width = tonumber (
		getElementData ( area, "sizeX", false )
	)
	local depth = tonumber (
		getElementData ( area, "sizeY", false )
	)

	local halfWidth, halfDepth, halfHeight = width/2, depth/2, AREA_HEIGHT/2
	z = z - halfHeight
	
	for i, side in ipairs ( boxSides ) do
		local nextSide = i < 4 and boxSides [ i + 1 ] or boxSides [ 1 ]
		
		_drawSide ( 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z - halfHeight, 
			x + halfWidth*side [ 1 ], y + halfDepth*side [ 2 ], z + halfHeight,
			1, 1, 256 * ( i > 2 and width or depth ), 256,
			_areaShader, i > 2 and width or depth, tocolor(255, 255, 255, 255), x, y, z
		)
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		_areaShader = dxCreateShader("shaders/area.fx")
		dxSetShaderValue ( _areaShader, "Color", 0, 0.6, 0, 0.1 )
	end
, false )


addEventHandler ( "onClientPreRender", root,
	function ( )	
		if Tool.selected.name == "Area" and isElement ( Tool.entity ) then
			local x, y = getElementPositionByOffset ( localPlayer, g_entityOffset.x, g_entityOffset.y, g_entityOffset.z )
			setElementPosition ( Tool.entity, x, y, 0 )
		end
		
		-- Если игрок предпочел не рисовать все участки, то мы будем рисовать только вновь создаваемый
		if getSettingByID ( "s_area" ):getData ( ) ~= true then
			if Tool.selected.name == "Area" and isElement ( Tool.entity ) and getElementType ( Tool.entity ) == "area" then
				_drawArea ( Tool.entity )
			end
		else
			local cx, cy = getCameraMatrix ( )		
			local dimension = getElementDimension ( localPlayer )
			local interior = getCameraInterior ( )
		
			local areas = getElementsByType ( "area", resourceRoot )
			for _, area in ipairs ( areas ) do
				local x, y = getElementPosition ( area )
				local areaDim = tonumber (
					getElementData ( area, "dimension", false )
				)
				local areaInt = tonumber (
					getElementData ( area, "interior", false )
				)
				if _getDistSqrt ( cx, cy, x, y ) < 6400 and areaDim == dimension and areaInt == interior then -- 6400 = 80 метров в квадрате
					_drawArea ( area )
				end
			end
		end
	end 
)

toolArea = {
	name = "Area",
	group = groupWorld,
	
	controls = {
		[ "r" ] = {
			"scrollbar",
			
			text = "Красный",
			value = {
				255,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		[ "g" ] = {
			"scrollbar",
			
			text = "Зеленый",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		[ "b" ] = {
			"scrollbar",
			
			text = "Синий",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		[ "price" ] = {
			"edit",
			value = "100",
			text = "Цена"
		}		
	},

	onCancel = setEditorTarget
}

function toolArea:onAffect ( key, super )
	local altState = getKeyState ( "lalt" ) or getKeyState ( "ralt" )
	if altState then
		local step = math.clamp ( getSettingByID ( "s_step" ):getData ( ), -100, 100 )
		if step then
			local width = tonumber (
				getElementData ( Tool.entity, "sizeX", false )
			)
			local depth = tonumber (
				getElementData ( Tool.entity, "sizeY", false )
			)		
		
			if key == editorSettings.key_forward then
				depth = math.clamp ( 1, depth + step, 100 )
			elseif key == editorSettings.key_backward then
				depth = math.clamp ( 1, depth - step, 100 )
			elseif key == editorSettings.key_right then
				width = math.clamp ( 1, width + step, 100 )
			elseif key == editorSettings.key_left then
				width = math.clamp ( 1, width - step, 100 )
			end
			
			setElementData ( Tool.entity, "sizeX", tostring ( width ) )
			setElementData ( Tool.entity, "sizeY", tostring ( depth ) )
		end
	else
		super ( key )
	end
end

function toolArea:onSelected ( )
	local x, y = g_entityOffset.calcPosition ( )
	local r = tonumber ( self:getControl ( "r" ):getData ( ) ) or 255
	local g = tonumber ( self:getControl ( "g" ):getData ( ) ) or 0
	local b = tonumber ( self:getControl ( "b" ):getData ( ) ) or 0
	local area = createElement("area")
	
	if area then
		setElementData ( area, "sizeX", "5" )
		setElementData ( area, "sizeY", "5" )
		setElementData ( area, "dimension", "0" )
		setElementData ( area, "interior", "0" )
	
		setEditorTarget ( area )
	end
end

function toolArea:onPlace ( element )
	local x, y = getElementPosition ( element )
	
	local width = tonumber (
		getElementData ( element, "sizeX", false )
	)
	local depth = tonumber (
		getElementData ( element, "sizeY", false )
	)	
	
	local r = self:getControl ( "r" ):getData ( )
	local g = self:getControl ( "g" ):getData ( )
	local b = self:getControl ( "b" ):getData ( )
	
	local price = tonumber ( self:getControl ( "price" ):getData ( ) ) or 0
	if price >= 0 then
		triggerServerEvent ( "onCreateTCTArea", root, x, y, width, depth, r, g, b, price )
	else
		outputChatBox ( "WBO: Цена не может быть отрицательной!")
	end
end

--------------------------------------
-- Wire group
--------------------------------------
groupWire = {
	name = "Wire"
}

--------------------------------------
-- Wire tool
-- Проводное соединение компонентов
--------------------------------------
--TODO: "accept-element"

toolWire = {
	name = "Wire",
	desc = "Для создания проводной связи между объектами прицельтесь на вход компонента который вы подключаете и нажмите [num3]. Тоже самое повторите с выходом компонента, к которому подключаете.",
	group = groupWire,
	
	controls = {
		[ "hid" ] = {
			"checkbox",
			
			text = "Скрытый",
			selected = false
		}
	},
}

function toolWire:onAccept ( element )
	if not getElementData ( element, "tag" ) then
		return
	end
	
	local hidden = self:getControl ( "hid" ):getData ( )

	wireLink ( element, hidden )
end

function toolWire:onWorldAccept ( )
	wireLink ( )
end

--------------------------------------
-- Button tool
--------------------------------------
local BUTTON_MODEL = 2886

toolButton = {
	name = "Button",
	group = groupWire,
	
	controls = {
		[ "itms" ] = {
			"edit",
			
			text = "Действия(через запятую)",
			value = "Активировать"
		},
		[ "tgl" ] = {
			"checkbox",
			
			text = "Переключать",
			selected = false
		},
		--[[ "on_val" ] = {
			"scrollbar",
			
			text = "Значение нажатия",
			value = {
				1,
				min = 0,
				max = 10
			}
		},
		[ "off_val" ] = {
			"scrollbar",
			
			text = "Значения отпускания",
			value = {
				0,
				min = 0,
				max = 10
			}
		}]]
	},
	
	onCancel = setEditorTarget
}

function toolButton:onSelected ( )
	local object = createObject ( BUTTON_MODEL, g_entityOffset.calcPosition ( ) )
	if object then
		setEditorTarget ( object )
	end
end

function toolButton:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rotx, roty, rotz = g_entityOffset.calcRotation ( )
	
	--Считываем и проверям правильно ли игрок заполнил поле Действия
	local itemsStr = self:getControl ( "itms" ):getData ( )
	local items = split ( itemsStr, 44 )
	
	if #items < 1 or #items > 10 then
		outputChatBox ( "WBO: Вы должны добавить не менее одного и не более 10 действий" )
		
		return
	end
	
	for _, item in ipairs ( items ) do
		if utfLen  ( item ) > 12 then
			outputChatBox ( "WBO: Название действия не может быть длиннее 12 символов" )
			
			return
		end
	end
	
	--Считываем и переводим значение поля Переключать
	local toggle = self:getControl ( "tgl" ):getData ( ) and "1" or "0"
	
	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
													x, y, z,
													rotx, roty, rotz,
													{ "itms", itemsStr },
													{ "tgl", toggle },
													--{ "onv", tostring ( self:getControl ( "on_val" ):getData ( ) ) },
													--{ "offv", tostring ( self:getControl ( "off_val" ):getData ( ) ) },
													--Назначаем wire-тег кнопке
													{ "tag", "sbutton" } )
end

--------------------------------------
-- Magnet tool
-------------------------------------
local MAGNET_MODEL = 3053

toolMagnet = {
	name = "Magnet",
	group = groupWire,
	
	onCancel = setEditorTarget
}

function toolMagnet:onSelected ( )
	local magnet = createObject ( MAGNET_MODEL, g_entityOffset.calcPosition ( ) )
	if magnet then
		setEditorTarget ( magnet )
	end
end

function toolMagnet:onPlace ( element )
	triggerServerEvent ( "onCreateWBOMagnet", root, getElementPosition ( element ) )
end

--------------------------------------
-- Portal
--------------------------------------
local PORTAL_MODEL = 2978
local portalTable

toolPortal = {
	name = "Portal",
	group = groupWire,
}

function toolPortal:onSelected ( )
	local portal = createObject ( PORTAL_MODEL, g_entityOffset.calcPosition ( ) )
	
	if portal then
		setEditorTarget ( portal )
	end
end

function toolPortal:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rotx, roty, rotz = g_entityOffset.calcRotation ( )
		
	if not portalTable then
		portalTable = { x, y, z, rotx, roty, rotz, getElementDimension ( localPlayer ) }
    
		outputChatBox ( "Первый портал установлен", 255, 255, 0 )
	else
		triggerServerEvent ( "onCreateWBOPortal", root, { x, y, z, rotx, roty, rotz, getElementDimension ( localPlayer ), unpack ( portalTable ) } )
    
		portalTable = nil
	end
end

	
function toolPortal:onCancel ( ) 
	setEditorTarget ( ) 
	portalTable = nil 
end

--------------------------------------
-- Marker tool
--------------------------------------
local MARKER_ALPHA = 240
local CONTROL_MODEL = 2969
local markerTable

function markerChange ( )
	if isElement ( Tool.entity ) ~= true or getElementType ( Tool.entity ) ~= "marker" then
		return
	end
	
	setMarkerColor ( Tool.entity, toolMarker:getControl ( "r" ):getData ( ), 
                                  toolMarker:getControl ( "g" ):getData ( ), 
                                  toolMarker:getControl ( "b" ):getData ( ), MARKER_ALPHA )
	setMarkerSize ( Tool.entity, toolMarker:getControl ( "size" ):getData ( ) )
	
	local markerType = Tool.getControl ( toolMarker, "type" ):getData ( ) > 0 and "arrow" or "cylinder"
	setMarkerType ( Tool.entity, markerType )
end

toolMarker = { 
	name = "Marker",
	group = groupWire,
	
	controls = {
		[ "r" ] = {
			"scrollbar",
			
			text = "Красный",
			value = {
				255,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		[ "g" ] = {
			"scrollbar",
			
			text = "Зеленый",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},
		[ "b" ] = {
			"scrollbar",
			
			text = "Синий",
			value = {
				0,
				min = 0,
				max = 255
			},
			onScroll = markerChange
		},		
		[ "size" ] = {
			"scrollbar",
			
			text = "Размер",
			value = {
				2,
				min = 1,
				max = 6
			},
			onScroll = markerChange
		},		
		[ "type" ] = {
			"combobox",
			
			text = "Тип",
			items = { 
				{ "cylinder" }, 
				{ "arrow" }
			},
			onAccepted = markerChange
		}
	}
}

function toolMarker:onSelected ( )
	local x, y, z = g_entityOffset.calcPosition ( )
	
	local markerType = self:getControl ( "type" ):getData ( ) > 0 and "arrow" or "cylinder"

	local marker = createMarker ( x, y, z, 
		markerType, 
		self:getControl ( "size" ):getData ( ), 
		self:getControl ( "r" ):getData ( ), self:getControl ( "g" ):getData ( ), self:getControl ( "b" ):getData ( ), 
		MARKER_ALPHA )
	
	if marker then
		setEditorTarget ( marker )
	end
end

function toolMarker:onPlace ( element )
	if getElementType ( element ) == "marker" then
		markerTable = { tempPosition = { getElementPosition ( element ) } }
   
		local block = createObject ( CONTROL_MODEL, g_entityOffset.calcPosition ( ) )
		if block then
			setEditorTarget ( block )
		end
	else
		local x, y, z = getElementPosition ( element )
		local rx, ry, rz = g_entityOffset.calcRotation ( )
		
		local markerType = self:getControl ( "type" ):getData ( ) > 0 and "arrow" or "cylinder"
		
		triggerServerEvent ( "onCreateWBOMarker", root, 
			{ markerTable.tempPosition [ 1 ], --Положение маркера
			  markerTable.tempPosition [ 2 ], 
			  markerTable.tempPosition [ 3 ],
			  markerType, --Тип маркера
			  self:getControl ( "size" ):getData ( ), --Размер маркера
			  self:getControl ( "r" ):getData ( ), --Цвет маркера
			  self:getControl ( "g" ):getData ( ),
			  self:getControl ( "b" ):getData ( ),
			  x, --Положение блока контроля
			  y,
			  z,
			  rx, --Вращение блока контроля
			  ry, 
			  rz 
			} 
		)
		
		markerTable = nil
   end
end

function toolMarker:onCancel ( ) 
	markerTable = nil 
end

--------------------------------------
-- Laser tool
--------------------------------------
local LASER_MODEL = 1213
local laserState = { }

addEventHandler ( "onClientPreRender", root,
	function ( )
		local objects = getElementsByType ( "object", resourceRoot, true )
		for _, laser in ipairs ( objects ) do
			--Если мы нашли лазер
			if getElementModel ( laser ) == LASER_MODEL then
				local isLaserLocal = isElementLocal ( laser )
				
				--Конвертим из number в bool
				local chkBlds = tonumber ( getElementData ( laser, "chkBlds" ) ) == 1
				local chkVhls = tonumber ( getElementData ( laser, "chkVhls" ) ) == 1
				local chkPlrs = tonumber ( getElementData ( laser, "chkPlrs" ) ) == 1
				local chkObjs = tonumber ( getElementData ( laser, "chkObjs" ) ) == 1
				
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
						
						changeLaserState ( laser, isCollide )
					end
     
					dxDrawLine3D ( lX, lY, lZ, fX, fY, fZ, lColor, 1 )
				end
			end
		end
	end 
)

function changeLaserState ( laser, state )
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
		triggerServerEvent ( "onLasetStateChange", laser, state )
	end
end

toolLaser = {
	name = "Laser",
	group = groupWire,
	
	controls = {
		[ "lnh" ] = {
			"scrollbar",
			
			text = "Длина луча",
			value = { 
				40,
				min = 1,
				max = 40
			},
			
			
			onScroll = function ( )
				setElementData ( Tool.entity, "lnh", 
					Tool.getControl ( toolLaser, "lnh" ):getData ( ) 
				)
			end
		},
		[ "chk_build" ] = {
			"checkbox",
			
			text = "Проверять постройки",
			selected = false
		},		
		[ "chk_vehs" ] = {
			"checkbox",
			
			text = "Проверять транспорт",
			selected = true
		},		
		[ "chk_player" ] = {
			"checkbox",
			
			text = "Проверять игроков",
			id = "chk_player",
			selected = true
		},
		[ "chk_objs" ] = {
			"checkbox",
			
			text = "Проверять объекты",
			selected = false
		},
	},

	onCancel = setEditorTarget
}

function toolLaser:onSelected ( )
	local laser = createObject ( LASER_MODEL, g_entityOffset.calcPosition ( ) )
	
	if laser then
		setElementData ( laser, "lnh", self:getControl ( "lnh" ):getData ( ) )
   
		setEditorTarget ( laser )
	end
end

function toolLaser:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )
	
	--Конвертим bool настройки в number и виде строки для сохранения
	local chkBlds = self:getControl ( "chk_build" ):getData ( ) and "1" or "0"
	local chkVhls = self:getControl ( "chk_vehs" ):getData ( ) and "1" or "0"
	local chkPlrs = self:getControl ( "chk_player" ):getData ( ) and "1" or "0"
	local chkObjs = self:getControl ( "chk_objs" ):getData ( ) and "1" or "0"

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                   x, y, z,
                                                   rx, ry, rz,
 												   { "chkBlds", chkBlds },
												   { "chkVhls", chkVhls },
												   { "chkPlrs", chkPlrs },
                                                   { "chkObjs", chkObjs },
                                                   { "lnh", tostring ( self:getControl ( "lnh" ):getData ( ) ) },
                                                   { "tag", "laser" } )
end

--------------------------------------
-- Dynamite
-- Создание динамита
--------------------------------------
local DYNAMITE_MODEL = 1654

toolDynamite = {
	name = "Dynamite",
	group = groupWire,
	
	onCancel = setEditorTarget
}

function toolDynamite:onSelected ( )
	local dynamite = createObject ( DYNAMITE_MODEL, g_entityOffset.calcPosition ( ) )
	if dynamite then
		setEditorTarget ( dynamite )
	end
end

function toolDynamite:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rotx, roty, rotz = g_entityOffset.calcRotation ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
													rotx, roty, rotz,
                                                    { "tag", "dynamite" } )
end

--------------------------------------
-- Track tool
-- Треки
--------------------------------------
local TRACK_CONTROL = 10245

local trackTable

function createTrack ( )
	if type ( trackTable ) == "table" then
		if #trackTable.nodes < 1 then
			outputChatBox ( "Для создания нового пути вы должны указать не менее одного узла", 255, 0, 0 )
			
			return
		end
			
		local block = createObject ( TRACK_CONTROL, g_entityOffset.calcPosition ( ) )
		setEditorTarget ( block )
			
		unbindKey ( "e", "down", createTrack )
	end
end

toolTrack = {
	name = "Track",
	group = groupWire,
	
	controls = {
		[ "spd" ] = {
			"scrollbar",
			
			text = "Время движения",
			value = {
				2000,
				min = 1000,
				max = 60000
			}
		}
	}
}

function toolTrack:onAccept ( element )
	if getElementType ( element ) ~= "object" then
		outputChatBox ( "Вы можете применить трек только к объекту", 255, 0, 0 )
		
		return
	end

	trackTable = { 
		element = element,
		nodes = { } 
	}
			
	local entity = createObject ( getElementModel ( element ), g_entityOffset.calcPosition ( ) )
	if entity then
		setEditorTarget ( entity )
			
		bindKey ( "e", "down", createTrack )
		outputChatBox ( "Нажмите 'e' для завершения трека", 255, 255, 0 )
	end
end

function toolTrack:onPlace ( element )
	if type ( trackTable ) == "table" and isElement ( trackTable.element ) then
		local trackModel = getElementModel ( element )
			
		if trackModel ~= TRACK_CONTROL then
			if #trackTable.nodes > 9 then
				outputChatBox ( "Вы не можете создать свыше 10-ти узлов для одного пути", 255, 0, 0 )
				
				return
			end
				
			local tOX, tOY, tOZ = getElementPosition ( element )
			local trackObject = createObject ( trackModel, tOX, tOY, tOZ, g_entityOffset.calcRotation ( ) )
			setElementData ( trackObject, "spd", self:getControl ( "spd" ):getData ( ), false )
			setElementCollisionsEnabled ( trackObject, false )
			setElementAlpha ( trackObject, 210 )
				
			table.insert ( trackTable.nodes, trackObject )
		else
			if #trackTable.nodes < 11 then
				local broadcastTable = { }
					
				for _, nodeObject in ipairs ( trackTable.nodes ) do
					local nOX, nOY, nOZ = getElementPosition ( nodeObject )
					local speed = getElementData ( nodeObject, "spd" )
					
					table.insert ( broadcastTable, { speed, nOX, nOY, nOZ } )
				
					destroyElement ( nodeObject )
				end
                    
				local x, y, z = getElementPosition ( element )

				triggerServerEvent ( "onCreateWBOTrack", trackTable.element, broadcastTable, {
					x, y, z, g_entityOffset.calcRotation ( ) } )
			else
				outputChatBox ( "Вы не можете создать свыше 10-ти узлов для одного пути", 255, 0, 0 )
			end
				
			setEditorTarget ( )
			trackTable = nil
		end
	end
end

function toolTrack:onCancel ( element )
	if not element then
		return
	end

	for _, nodeObject in ipairs ( trackTable.nodes ) do
		destroyElement ( nodeObject )
	end
	
	setEditorTarget ( )
	trackTable = nil
	unbindKey ( "e", "down", createTrack )
end

--------------------------------------
-- Effect tool
-- Эффекты
--------------------------------------
local EMITTER_MODEL = 2344

local effects = {
	{ "blood" }, 
	{ "bulletImpact" },
	{ "bulletSplash" },
	{ "debris" },
	{ "footSplash" },
	{ "glass" },
	{ "gunshot" },
	{ "punchImpact" },
	{ "sparks" },
	{ "tankFire" },
	{ "tyreBurst" },
	{ "waterSplash" },
	{ "wood" }
}

addEventHandler ( "onClientRender", root,
	function ( )
		local objects = getElementsByType ( "object" )
		for _, emitter in ipairs ( objects ) do
			if getElementModel ( emitter ) == EMITTER_MODEL then
				local isEmit = tonumber ( getElementData ( emitter, "emit" ) ) == 1
				
				if isEmit then
					local effectIndex =  tonumber ( 
						getElementData ( emitter, "fx" )
					)
					local effectName = effects [ effectIndex ] [ 1 ]
					
					if Effect [ effectName ] then
						Effect [ effectName ].render ( emitter, 1 )
					end
				end
			end
 		end
	end
)

toolEffect = { 
	name = "Effect",
	group = groupWire,
	
	controls = {
		[ "fx" ] = {
			"combobox",
			
			text = "Эффект",
			items = effects
		}
	},
	
	onCancel = setEditorTarget
}

function toolEffect:onSelected ( )
	local emitter = createObject ( EMITTER_MODEL, g_entityOffset.calcPosition ( ) )
	
	if emitter then
		setEditorTarget ( emitter )
	end
end

function toolEffect:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )
	
	local effectIndex = self:getControl ( "fx" ):getData ( ) + 1
	
	triggerServerEvent ( "onCreateWBOObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
                                                    { "tag", "fxemitter" },
													{ "fx", tostring ( effectIndex ) } )
end

--------------------------------------
-- Sound tool
-- Звуки
--------------------------------------
local SOUND_MODEL = 10104

toolSound = { 
	name = "Sound",
	group = groupWire,
	
	controls = {
		[ "snd" ] = {
			"combobox",
			
			text = "Звук",
			items = { 
				{ "siren2" },
				{ "door_bell" },
				{ "CB_Clap.wav" },
				{ "CB_Hat.wav" },
				{ "CB_Kick.wav" },
				{ "CB_Snare.wav" },
				{ "Clap Basic.wav" },
				{ "Hat Basic.wav" },
				{ "Kick Basic.wav" },
				{ "Snare Basic.wav" }
			}
		},
		[ "lpd" ] = {
			"checkbox",
			
			text = "Зациклить",
			selected = false
		}
	},
	
	onCancel = setEditorTarget
}

function toolSound:onSelected ( )
	local emitter = createObject ( SOUND_MODEL, g_entityOffset.calcPosition ( ) )
	
	if emitter then
		setEditorTarget ( emitter )
	end
end

function toolSound:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )
	local soundIndex = tostring ( 
		self:getControl ( "snd" ):getData ( ) + 1
	)
	local looped = tostring ( 
		self:getControl ( "lpd" ):getData ( ) and 1 or 0 
	)
	
	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
													{ "snd", soundIndex },
													{ "lpd", looped },
                                                    { "tag", "sound" } )
end

--------------------------------------
-- Gate tool
--------------------------------------
local GATE_MODEL = 3013
local gateList = {
	[ "Logic" ] = {
		"Not", "Or", "And", "Xor", "Xnor", "Nor", "Nand"
	},
	[ "Arithmetic" ] = {
		"Add", "Sub"
	}
}

toolGate = {
	name = "Gate",
	group = groupWire,
	
	controls = {
		[ "gate" ] = {
			"gridlist",
			
			text = "Гейт",
			item = gateList
		}
	},
	
	onCancel = setEditorTarget
}

function toolGate:onSelected ( )
	local gate = createObject ( GATE_MODEL, g_entityOffset.calcPosition ( ) )
	if gate then
		setEditorTarget ( gate )
	end
end

function toolGate:onPlace ( element )
	local gate = self:getControl ( "gate" ):getData ( )
	
	if not gate then
		outputChatBox ( "Вы должны выбрать гейт для его создания", 255, 0, 0 )
		
		return
	end

	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
													{ "gate", gate },
												    { "tag", "gate" } )
end

--------------------------------------
-- Monitor
--------------------------------------
local MONITOR_MODEL = 1744

toolMonitor = {
	name = "Monitor",
	group = groupWire,
	
	onCancel = setEditorTarget
}

function toolMonitor:onSelected ( )
	local monitor = createObject ( MONITOR_MODEL, g_entityOffset.calcPosition ( ) )
	if monitor then
		setEditorTarget ( monitor )
	end
end

function toolMonitor:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
												    { "tag", "monitor" } )
end

--------------------------------------
-- Door tool
--------------------------------------
local doors = {
	{ "Door", 1491 },
	{ "Door 2", 1492 },
	{ "Door 3", 1502 },
	{ "Door 4", 2202 },
	{ "Door 5", 3176 },
	{ "Door 6", 10181 },
	{ "Door 7", 5110 },
	{ "Door 8", 8707 },
	{ "Door 9", 2328 },
	{ "Door 10", 1959 },
	{ "Door 11", 1960 },
	{ "Door 12", 1946 },
	{ "Door 13", 1947 },
	{ "Door 14", 1948 },
	{ "Door 15", 1935 },
	{ "Door 16", 1936 },
	{ "Door 17", 1937 },
	{ "Door 18", 2583 },
	{ "Door 19", 1756 },
	{ "Door 20", 2030 },
	{ "Door 21", 10091 },
	{ "Door 22", 10092 },
	{ "Door 23", 10094 },
	{ "Gate", 5111 },
	{ "Gate 2", 4924 },
	{ "Gate 3", 5232 },
	{ "Gate 4", 4958 },
	{ "Gate 5", 4925 },
	{ "Gate 6", 4217 },
	{ "Gate 7", 4218 },
	{ "Gate 8 R", 5551 },
	{ "Gate 8 L", 5550 },
	{ "Gate 9 R", 3448 },
	{ "Gate 9 L", 3447 },
	{ "Gate 10 R", 4990 },
	{ "Gate 10 L", 4989 },
	{ "Gate 11 R", 4866 },
	{ "Gate 11 L", 4865 },
	{ "Gate 12 L", 4438 },
	{ "Gate 12 R", 4439 },
	{ "Gate 13 L", 1719 },
	{ "Gate 13 R", 1720 }
}

toolDoor = {
	name = "Door",
	group = groupWire,
	
	controls = {
		[ "door" ] = {
			"combobox",
			
			text = "Дверь",
			items = doors,
			
			onAccepted = function ( )
				local doorIndex = Tool.getControl ( toolDoor, "door" ):getData ( )
				local doorModel = doors [ doorIndex + 1 ] [ 2 ]
				
				local door = createObject ( doorModel, g_entityOffset.calcPosition ( ) )
				if door then
					setEditorTarget ( door )
				end
			end
		}
	}
}

function toolDoor:onSelected ( )
	local door = createObject ( doors [ 1 ] [ 2 ], g_entityOffset.calcPosition ( ) )
	if door then
		setEditorTarget ( door )
	end
end

function toolDoor:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rotx, roty, rotz = g_entityOffset.calcRotation ( )

	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
													x, y, z,
													rotx, roty, rotz,
													{ "tag", "door" } )
end

--------------------------------------
-- Lamp tool
--------------------------------------
local LAMP_MODEL = 10161

toolLamp = {
	name = "Lamp",
	group = groupWire,
	
	controls = {
		[ "r" ] = {
			"scrollbar",
			
			text = "Красный",
			value = {
				255,
				min = 0,
				max = 255
			}
		},
		[ "g" ] = {
			"scrollbar",
			
			text = "Зеленый",
			value = {
				0,
				min = 0,
				max = 255
			}
		},
		[ "b" ] = {
			"scrollbar",
			
			text = "Синий",
			value = {
				0,
				min = 0,
				max = 255
			}
		}
	},
	
	onCancel = setEditorTarget
}

function toolLamp:onSelected ( )
	local monitor = createObject ( LAMP_MODEL, g_entityOffset.calcPosition ( ) )
	if monitor then
		setEditorTarget ( monitor )
	end
end

function toolLamp:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )
	
	local r = tostring ( self:getControl ( "r" ):getData ( ) )
	local g = tostring ( self:getControl ( "g" ):getData ( ) )
	local b = tostring ( self:getControl ( "b" ):getData ( ) )
	
	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
													{ "cr", r },
													{ "cg", g },
													{ "cb", b },
												    { "tag", "lamp" } )
end

--------------------------------------
-- Channel tool
--------------------------------------
local CHANNEL_MODEL = 3013

toolChannel = {
	name = "Channel",
	desc = "Необходим для вызова события по ключу и получения ключа активированного входа(если выбрана опция).",
	group = groupWire,
	
	controls = {
		 [ "re" ] = {
			"checkbox",
			
			text = "Обратно в ключ",
			selected = false
		}
	},
	
	onCancel = setEditorTarget
}

function toolChannel:onSelected ( )
	local channel = createObject ( CHANNEL_MODEL, g_entityOffset.calcPosition ( ) )
	if channel then
		setEditorTarget ( channel )
	end
end

function toolChannel:onPlace ( element )
	local x, y, z = getElementPosition ( element )
	local rx, ry, rz = g_entityOffset.calcRotation ( )

	local isInverse = self:getControl ( "re" ):getData ( )
	local tag = isInverse and "chnelTK" or "kTChnel"
	
	triggerServerEvent ( "onCreateTCTObject", root, getElementModel ( element ),
                                                    x, y, z,
                                                    rx, ry, rz,
												    { "tag", tag } )
end

--------------------------------------
-- Rail tool
--------------------------------------
local blipTexture

toolRail = {
	name = "Rail",
	group = groupWorld,
	
	onCancel = function ( ) 
		removeEventHandler ( "onClientRender", root, toolRail.update )
		destroyElement ( blipTexture )
		
		setEditorTarget ( )
	end
}

function toolRail:onSelected ( )
	local node = createElement ( "rail-node" )
	if node then
		setElementPosition ( node, g_entityOffset.calcPosition ( ) )

		setEditorTarget ( node )
	end
	
	blipTexture = dxCreateTexture ( "textures/56.png" )
	addEventHandler ( "onClientRender", root, toolRail.update, false )
end

function toolRail:onPlace ( element )
	--triggerServerEvent ( "onCreateTCTRailNode", )
end

function toolRail.update ( )
	local offx, offy, offz = g_entityOffset.calcPosition ( )
	
	setElementPosition ( Tool.entity, offx, offy, offz )
	
	local railNodes = getElementsByType ( "rail-node", resourceRoot, true )
	for _, node in ipairs ( railNodes ) do
		local x, y, z = getElementPosition ( node )
	
		dxDrawMaterialLine3D ( x, y, z - 0.5, x, y, z + 0.5, blipTexture, 1 )
	end
	
	dxDrawMaterialLine3D ( offx, offy, offz, offx, offy, offz, blipTexture, 0 )
end

function initTools ( )
	--World
	createToolGroup ( groupWorld )

	createTool ( toolDefault )
	createTool ( toolGrab )
    createTool ( toolRemove )
    createTool ( toolAlpha )
	createTool ( toolScale )
	createTool ( toolDoubleSided )
	createTool ( toolFreeze )
	createTool ( toolAttach )
	createTool ( toolSign )
	createTool ( toolBlueprint )
	createTool ( toolLock )
	createTool ( toolArea )
	
	--Wire
	createToolGroup ( groupWire )
	
	createTool ( toolWire )
	createTool ( toolButton )
	createTool ( toolMagnet )
	createTool ( toolPortal )
	createTool ( toolMarker )
	createTool ( toolLaser )
	createTool ( toolDynamite )
	createTool ( toolTrack )
	--createTool ( toolEffect )
	createTool ( toolSound )
	createTool ( toolGate )
	createTool ( toolMonitor )
	createTool ( toolDoor )
	createTool ( toolLamp )
	createTool ( toolChannel )
	
	--createTool ( toolRail )
	
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
	if not tool.hidden then
		tool.gui = guiCreateScrollPane ( 0.44, 0.02, 0.5, 0.96, true, editorForm.toolsTab )
	
		tool.header = guiCreateLabel ( 0.02, 0.02, 0.96, 0.04, tool.name, true, tool.gui )
		guiSetFont ( tool.header , "default-bold-small" )
	
		--tool.row = guiGridListAddRow ( editorForm.toolsList )
		tool.row = guiGridListInsertRowAfter ( editorForm.toolsList, 
			tool.group and tool.group.row or guiGridListGetRowCount ( editorForm.toolsList ) 
		)
		guiGridListSetItemText ( editorForm.toolsList, tool.row, 1, tool.name, false, false )
	
		if tool.controls then
			for id, tbl in pairs ( tool.controls ) do
				tool.controls [ id ] = createControl ( tbl, tool.gui )
			end
		end
		
		guiSetVisible ( tool.gui, false )
	end
	
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

function setSelectedTool ( tool )
	if Tool.selected then
		Tool.selected:setVisible ( false )
		
		--if Tool.entity then
			Tool.selected:call ( "onCancel", Tool.entity )
			setEditorTarget ( )
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
	if not self.hidden then
		guiSetVisible ( self.gui, selected )
	end
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