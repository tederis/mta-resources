WorldTexture = { 
	items = { }
}

function WorldTexture.setObjectShader ( object, shader )
	if WorldTexture.items [ object ] then
		engineRemoveShaderFromWorldTexture ( WorldTexture.items [ object ], "*", object )
	end
	
	if shader then
		engineApplyShaderToWorldTexture ( shader, "*", object )
		
		WorldTexture.items [ object ] = shader
	end
end

---------------------------------
-- Object text
---------------------------------
ModelText = { 
	items = { }
}
ModelText.models = {
	[ 1744 ] = {
		width = 32,
		height = 32,
		textScale = 1.8,
		textureName = "mahmutil_sam_mon_01",
		getData = function ( element )
			local data = getElementData ( element, "value" )
			
			return util.unpack ( data )
		end
	},
	[ 1778 ] = {
		width = 64,
		height = 64,
		textScale = 0.9,
		textureName = "ht",
		getData = function ( element )
			return getElementData ( element, "txt" )
		end
	}
}

function ModelText.add ( element, modelData )
	local modelText = {
		rt = dxCreateRenderTarget ( modelData.width, modelData.height ),
		shader = dxCreateShader ( "shaders/add.fx" ),
		modelData = modelData 
	}
	dxSetShaderValue ( modelText.shader, "Tex", modelText.rt )
	engineApplyShaderToWorldTexture ( modelText.shader, modelData.textureName, element )
	
	ModelText.items [ element ] = modelText
end

function ModelText.remove ( element )
	local modelText = ModelText.items [ element ]
	
	if modelText then
		engineRemoveShaderFromWorldTexture ( modelText.shader, "*", element )
		destroyElement ( modelText.shader )
		destroyElement ( modelText.rt )
	
		ModelText.items [ element ] = nil
	end
end

addEventHandler ( "onClientRender", root,
	function ( )
		for element, item in pairs ( ModelText.items ) do
			local elementData = item.modelData.getData ( element )
			
			if elementData ~= item.text then
				item.text = elementData
				
				dxSetRenderTarget ( item.rt, true )
				dxDrawRectangle ( 0, 0, item.modelData.width, item.modelData.height, item.modelData.backColor or color.black )
				dxDrawText ( type ( item.text ) == "string" and item.text or "", 
					0, 0, item.modelData.width, item.modelData.height, 
					item.modelData.textColor or color.white, item.modelData.textScale, 
					"default", "center", "center", false, true 
				)
				dxSetRenderTarget ( )
			end
		end
	end
, false )

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
		if didClearRenderTargets then
			--Восстанавливаем все RT
			for _, item in pairs ( ModelText.items ) do
				item.text = nil
			end
		end
	end
, false )

addEventHandler ( "onClientElementStreamOut", resourceRoot,
    function ( )
		if not ModelText.items [ source ] then
			return
		end
		
		ModelText.remove ( source )
    end
)

addEventHandler ( "onClientElementDestroy", resourceRoot,
	function ( )
		if not ModelText.items [ source ] then
			return
		end
		
		ModelText.remove ( source )
	end
)