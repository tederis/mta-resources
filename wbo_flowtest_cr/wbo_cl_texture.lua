local loadedTextures = { }
local loadedMaterials = { }

TextureReplacer = { 
	items = { }
}

local fileMaterials = { }

--[[
	modelTextureIndex - индекс текстуры модели(например текстура наружной отделки и внутренней)
	templ - элемент материала(содержит данные о нем)
]]
function TextureReplacer.setObjectMaterial ( object, modelTextureIndex, templ )
	local objectModel = getElementModel ( object )
	local materialName = modelMaterials [ objectModel ] and modelMaterials [ objectModel ] [ modelTextureIndex ] or "*"

	-- Удаляем материал с объекта перед применением нового
	local itemTempl = TextureReplacer.items [ object ]
	if itemTempl then
		local material = itemTempl [ modelTextureIndex ]
		if material then
			engineRemoveShaderFromWorldTexture ( material.shader, materialName, object )
		end
		TextureReplacer.items [ object ] [ modelTextureIndex ] = nil
	end
	
	-- Применяем новый материал к объекту
	if isElement ( templ ) then
		local material = findOrCreateMaterial ( templ )
		if material then
			engineApplyShaderToWorldTexture ( material.shader, materialName, object )
		
			if not TextureReplacer.items [ object ] then
				TextureReplacer.items [ object ] = { }
			end
			TextureReplacer.items [ object ] [ modelTextureIndex ] = material
		end
	end
end

function TextureReplacer.removeAll ( )
	--[[for object, materials in pairs ( TextureReplacer.items ) do
		for index, material in pairs ( materials ) do
			
		end
	end]]
	
	for object, sides in pairs ( TextureReplacer.items ) do
		local objectModel = getElementModel ( object )
		for side, material in pairs ( sides ) do
			local materialName = modelMaterials [ objectModel ] and modelMaterials [ objectModel ] [ side ] or "*"
			engineRemoveShaderFromWorldTexture ( material.shader, materialName, object )
		end
	end
	
	for _, material in ipairs ( loadedMaterials ) do
		material:destroy ( )
	end
	for _, texture in ipairs ( loadedTextures ) do
		destroyElement ( texture )
	end
	
	outputDebugString ( "Выгружено " .. #loadedMaterials .. " материалов и " .. #loadedTextures .. " текстур" )
	TextureReplacer.items = { }
	loadedMaterials = { }
	loadedTextures = { }
	
	fileMaterials = { }
end

Material = { }
Material.__index = Material

function Material.new ( id, u, v )
	local texture = loadedTextures [ tonumber ( id ) ]
	if not texture then return end;
	
	local shader = dxCreateShader ( "shaders/add.fx", 0, 200, false, "object" )
	dxSetShaderValue ( shader, "Tex", texture )
	dxSetShaderValue ( shader, "UVScale", tonumber ( u ), tonumber ( v ) )
	
	local material = {
		texture = texture,
		shader = shader,
		u = tonumber ( u ) or 1,
		v = tonumber ( v ) or 1,
		tag = id .. "+" .. u .. "+" .. v
	}
	
	outputDebugString ( "Новый материал" )
	
	return setmetatable ( material, Material )
end

function Material:destroy ( )
	destroyElement ( self.shader )
end


function hasMaterialFor ( str )
	for i = 1, #loadedMaterials do
		if loadedMaterials [ i ].tag == str then
			return loadedMaterials [ i ]
		end
	end
end

function findOrCreateMaterial ( element )
	local id = getElementData ( element, "_id", false )
	if id == false then return end;
	local u, v = getElementData ( element, "u", false ), getElementData ( element, "v", false )
	
	local material = hasMaterialFor ( id .. "+" .. u .. "+" .. v )
	if material then
		return material
	end
	
	material = Material.new ( id, u, v )
	if material then
		table.insert ( loadedMaterials, material )
	end
	return material
end

addEvent ( "onClientElementMaterialChange", true )
addEventHandler ( "onClientElementMaterialChange", resourceRoot,
	function ( modelTextureIndex, templ )
		if isElement ( templ ) ~= true then
			TextureReplacer.setObjectMaterial ( source, tonumber ( modelTextureIndex ) )
			return
		end
	
		local id = tonumber ( getElementData ( templ, "_id", false ) )
		if id then
			-- Текстура уже загружена?
			if loadedTextures [ id ] then
				TextureReplacer.setObjectMaterial ( source, tonumber ( modelTextureIndex ), templ )
				
			-- Добавляем материал в пул для применения при загрузке файла
			else
				if fileMaterials [ id ] then
					-- Если материал уже есть в пуле, выходим
					for _, _templ in ipairs ( fileMaterials [ id ] ) do
						if _templ == templ then
							return
						end
					end

					table.insert ( fileMaterials [ id ], templ )
				else
					fileMaterials [ id ] = { templ }
				end
			end
		end
	end
)

local function setupElementMaterials ( object )
	local templates = getElementChildren ( object, "material" )
	for _, templ in ipairs ( templates ) do
		local id = tonumber ( getElementData ( templ, "_id", false ) )
		if id then
			if fileMaterials [ id ] then
				table.insert ( fileMaterials [ id ], templ )
			else
				fileMaterials [ id ] = { templ }
			end
		end
	end
end

addEvent ( "onClientPlayerRoomJoin", true )
addEventHandler ( "onClientPlayerRoomJoin", localPlayer,
	function ( room )
		local objects = getElementsByType ( "object", resourceRoot )
		for _, object in ipairs ( objects ) do
			if isElementInRoom ( object, room ) then
				setupElementMaterials ( object )
			end
		end
		
		outputDebugString ( "Загружено " .. #loadedMaterials .. " материалов и " .. #loadedTextures .. " текстур" )
	end
)

addEvent ( "onClientPlayerRoomQuit", true )
addEventHandler ( "onClientPlayerRoomQuit", localPlayer,
	function ( room )
		-- Выгружаем все материалы и текстуры
		TextureReplacer.removeAll ( )
	end
)

addModFileHandler ( 
	function ( fileType, fileId, fileName, fileChecksum )
		local element = dxCreateTexture ( ":wbo_modmanager/modfiles/" .. fileChecksum, "dxt1", false )
		if isElement ( element ) ~= true then
			outputDebugString ( "TCT: Ошибка при создании текстуры", 2 )
			return
		end
		fileId = tonumber ( fileId )
		loadedTextures [ fileId ] = element
	
		local templates = fileMaterials [ fileId ]
		if templates then
			for _, templ in ipairs ( templates ) do
				if isElement ( templ ) then
					local object = getElementParent ( templ )
					local side = getElementData ( templ, "side", false )
					TextureReplacer.setObjectMaterial ( object, tonumber ( side ), templ )
				end
			end
			
			outputDebugString ( "Загружен " .. fileName .. " для " .. #templates .. " материалов" )
		end
	end
, "dds"--[[, "jpg"]] )

---------------------------------
-- Object text
---------------------------------
ModelText = { 
	items = { },
	refs = 0,
	lastTicks = getTickCount ( )
}
ModelText.models = {
	[ 3337 ] = {
		width = 256,
		height = 128,
		textScale = 1.5,
		textureName = "roadsback01_la",
		getData = function ( element )
			return getElementData ( element, "txt" )
		end,
		update = function ( element, modelData, text )
			for i = 1, 2 do
				local y = modelData.height * ( i - 1 )

				dxDrawText ( text, 
					0, y, modelData.width, modelData.height / 2, 
					modelData.textColor or color.white, modelData.textScale, 
					"default", "center", "center", false, true 
				)
			end
		end
	}
}

function ModelText.onRender ( )
	local now = getTickCount ( )
	if now - ModelText.lastTicks < 1000 then return end;
	ModelText.lastTicks = now

	for element, item in pairs ( ModelText.items ) do
		local elementData = item.modelData.getData ( element )
			
		if elementData ~= item.text then
			item.text = elementData
				
			dxSetRenderTarget ( item.rt, true )
			dxDrawRectangle ( 0, 0, item.modelData.width, item.modelData.height, item.modelData.backColor or color.black )
				
			local text = type ( item.text ) == "string" and item.text or ""
				
			if item.modelData.update then
				item.modelData.update ( element, item.modelData, text )
			else
				dxDrawText ( text, 
					0, 0, item.modelData.width, item.modelData.height, 
					item.modelData.textColor or color.white, item.modelData.textScale, 
					"default", "center", "center", false, true 
				)
			end
			dxSetRenderTarget ( )
		end
	end
end

function ModelText.add ( element, modelData )
	local modelText = {
		rt = dxCreateRenderTarget ( modelData.width, modelData.height ),
		shader = dxCreateShader ( "shaders/add.fx" ),
		modelData = modelData 
	}
	dxSetShaderValue ( modelText.shader, "Tex", modelText.rt )
	dxSetShaderValue ( modelText.shader, "UVScale", 1, 1 )
	engineApplyShaderToWorldTexture ( modelText.shader, modelData.textureName, element )
	
	ModelText.items [ element ] = modelText
	ModelText.refs = ModelText.refs + 1
	
	if ModelText.refs == 1 then
		addEventHandler ( "onClientRender", root, ModelText.onRender, false, "low" )
		outputDebugString ( "TCT: ModelText added onClientRender" )
	end
end

function ModelText.remove ( element )
	local modelText = ModelText.items [ element ]
	
	if modelText then
		engineRemoveShaderFromWorldTexture ( modelText.shader, "*", element )
		destroyElement ( modelText.shader )
		destroyElement ( modelText.rt )
	
		ModelText.items [ element ] = nil
		ModelText.refs = ModelText.refs - 1
		
		if ModelText.refs == 0 then
			removeEventHandler ( "onClientRender", root, ModelText.onRender )
			outputDebugString ( "TCT: ModelText removed onClientRender" )
		end
	end
end

addEventHandler ( "onClientElementStreamIn", resourceRoot,
	function ( )
		local modelData = ModelText.models [ getElementModel ( source ) ]
		
		if modelData then
			ModelText.add ( source, modelData )
		end
    end
)

addEventHandler ( "onClientRestore", root,
	function ( didClearRenderTargets )
		if ModelText.refs > 0 and didClearRenderTargets then
			--Восстанавливаем все RT
			for _, item in pairs ( ModelText.items ) do
				item.text = nil
			end
		end
	end
, false )

addEventHandler ( "onClientElementStreamOut", resourceRoot,
    function ( )
		if ModelText.refs > 0 and ModelText.items [ source ] then
			ModelText.remove ( source )
		end
    end
)

addEventHandler ( "onClientElementDestroy", resourceRoot,
	function ( )
		if ModelText.refs > 0 and ModelText.items [ source ] then
			ModelText.remove ( source )
		end
	end
)

--[[
	Material browser
]]
MaterialBrowser = { 
	width = 300, 
	height = 500,
	itemsNum = 8
}
MaterialBrowser.x = ( sw / 2 ) - ( MaterialBrowser.width / 2 )
MaterialBrowser.y = ( sh / 2 ) - ( MaterialBrowser.height / 2 )

function MaterialBrowser.show ( callback )
	local this = MaterialBrowser
	if this.visible ~= true then
		this.wnd = guiCreateWindow ( this.x, this.y, this.width, this.height, "Material browser", false )
		this.searchBox = guiCreateEdit ( 5, 25, this.width - 10, 20, "", false, this.wnd )
		this.matList = {
			x = 5, y = 50,
			width = this.width - 10, height = 400,
			bias = 4
		}
		this.matList.itemHeight = this.matList.height / this.itemsNum
		this.btn = guiCreateButton ( 5, 460, this.width - 10, 30, "Cancel", false, this.wnd )
		this.items = { }
		this.scrollPosition = 1
	
		addEventHandler ( "onClientRender", root, MaterialBrowser.onRender, false )
		addEventHandler ( "onClientCursorMove", root, MaterialBrowser.onCursorMove, false )
		addEventHandler ( "onClientGUIClick", this.wnd, MaterialBrowser.onClick )
		addEventHandler ( "onClientKey", root, MaterialBrowser.onKey, false )
		
		this.callback = callback
	
		showCursor ( true )
	end
	this.visible = true
end

function MaterialBrowser.hide ( )
	local this = MaterialBrowser
	if this.visible then
		removeEventHandler ( "onClientRender", root, MaterialBrowser.onRender )
		removeEventHandler ( "onClientCursorMove", root, MaterialBrowser.onCursorMove )
		removeEventHandler ( "onClientGUIClick", this.wnd, MaterialBrowser.onClick )
		removeEventHandler ( "onClientKey", root, MaterialBrowser.onKey )
		destroyElement ( this.wnd )
		for _, item in ipairs ( this.items ) do
			if isElement ( item.texture ) then
				destroyElement ( item.texture )
			end
		end
		this.items = nil
		showCursor ( false )
	end
	this.visible = nil
end

function MaterialBrowser.insertMaterial ( filePath, fileName, ... )
	if MaterialBrowser.visible ~= true then
		return
	end

	local item = {
		name = fileName,
		args = { ... }
	}
	if filePath then
		item.texture = dxCreateTexture ( filePath, "dxt1", false )
	end
	table.insert ( MaterialBrowser.items, item )
end

function MaterialBrowser.onRender ( )
	local this = MaterialBrowser
	local _list = this.matList
	local px, py = guiGetPosition ( this.wnd, false )
	
	local x = px + _list.x
	local y = py + _list.y
	dxDrawRectangle ( x, y, _list.width, _list.height, tocolor ( 20, 20, 20, 200 ), true )
	
	local bias = _list.bias
	local doubleBias = bias * 2
	local imgSize = _list.itemHeight - doubleBias
	for i = 1, this.itemsNum do
		local itemIndex = ( i - 1 ) + this.scrollPosition
		local item = this.items [ itemIndex ]
		if item then
			local _y = y + ( _list.itemHeight * ( i - 1 ) )
			if i == this.selectedItem then
				dxDrawRectangle ( x, _y, _list.width, _list.itemHeight, tocolor ( 70, 70, 70, 200 ), true )
			end
			local _x = x + bias
			if item.texture then
				dxDrawImage ( _x, _y + bias, imgSize, imgSize, item.texture, 0, 0, 0, tocolor ( 255, 255, 255, 255 ), true )
			end
			_x = _x + imgSize + bias
			dxDrawLine ( _x, y, _x, y + _list.height, tocolor ( 80, 80, 80, 100 ), 1, true )
			_x = _x + bias
			dxDrawText ( tostring ( item.name ), _x, _y, 0, _y + _list.itemHeight, tocolor ( 230, 230, 230, 255 ), 1, "default", "left", "center", false, false, true )
		end
	end
end

function MaterialBrowser.onCursorMove ( _, _, cx, cy )
	local this = MaterialBrowser
	local _list = this.matList
	local px, py = guiGetPosition ( this.wnd, false )
	
	local x = px + _list.x
	local y = py + _list.y
	if isPointInRectangle ( cx, cy, x, y, _list.width, _list.height ) ~= true then
		return
	end
	
	local itemIndex = math.floor ( ( cy - y ) / _list.itemHeight ) + 1
	this.selectedItem = itemIndex
end

function MaterialBrowser.onClick ( button, state, cx, cy )
	local this = MaterialBrowser
	if source == this.btn then
		MaterialBrowser.hide ( )
	elseif source == this.wnd then
		local _list = this.matList
		local px, py = guiGetPosition ( source, false )
	
		local x = px + _list.x
		local y = py + _list.y
		if isPointInRectangle ( cx, cy, x, y, _list.width, _list.height ) ~= true then
			return
		end
		
		local itemIndex = ( this.selectedItem - 1 ) + this.scrollPosition
		local item = this.items [ itemIndex ]
		if item then
			this.callback ( item.name, unpack ( item.args ) )
			MaterialBrowser.hide ( )
		end
	end
end

function MaterialBrowser.onKey ( button, pressed )
	local this = MaterialBrowser
	if not pressed then return end;
		
	if button == "mouse_wheel_up" then
		this.scrollPosition = math.max ( this.scrollPosition - 1, 1 )
	elseif button == "mouse_wheel_down" then
		if this.scrollPosition + this.itemsNum <= #this.items then
			this.scrollPosition = math.min ( this.scrollPosition + 1, #this.items )
		end
	end
end