--[[
	Pizza Stack:
		SELLER_MODEL = 155
		JFUD_LOW_FOOD_MODEL = -376 
		JFUD_MED_FOOD_MODEL = -377 
		JFUD_HIGH_FOOD_MODEL = -57 
		JFUD_HEALTHY_FOOD_MODEL = -378 
		
		JFUD_X_OFFSET = 0.0 
		JFUD_Y_OFFSET = 0.0 
		JFUD_Z_OFFSET = 0.0 
	Cluckin' Bell:
		SELLER_MODEL = 167
		JFUD_LOW_FOOD_MODEL = -379 
		JFUD_MED_FOOD_MODEL = -380 
		JFUD_HIGH_FOOD_MODEL = -381 
		JFUD_HEALTHY_FOOD_MODEL = -382 
		
		JFUD_X_OFFSET = -5.211 
		JFUD_Y_OFFSET = 112.784 
		JFUD_Z_OFFSET = 0.3 
	Burger Shot:
		SELLER_MODEL = 205
		JFUD_LOW_FOOD_MODEL = -383 
		JFUD_MED_FOOD_MODEL = -384 
		JFUD_HIGH_FOOD_MODEL = -60 
		JFUD_HEALTHY_FOOD_MODEL = -385 
		
		JFUD_X_OFFSET = 1.566 
		JFUD_Y_OFFSET = 51.419 
		JFUD_Z_OFFSET = 0.01 
]]

local sw, sh = guiGetScreenSize ( )

local traderWindow

local foods = {
	[ 5 ] = {
		{ "Buster", 2, 2218 },
		{ "Double D-Luxe", 5, 2219 },
		{ "Full Rack", 10, 2220 },
		{ "Salad Meal", 10, 2355 }
	},
	[ 9 ] = {
		{ "Cluckin' Little Meal", 2, 2215 },
		{ "Cluckin' Big Meal", 5, 2216 },
		{ "Cluckin' Huge Meal", 10, 2217 },
		{ "Salad Meal", 10, 2353 }
	},
	[ 10 ] = {
		{ "Moo Kids Meal", 2, 2213 },
		{ "Beef Tower", 5, 2214 },
		{ "Meat Stack", 10, 2212 },
		{ "Salad Meal", 5, 2354 }
	}
}

function createTraderWindow ( )
	if traderWindow then
		outputDebugString ( "Меню уже создано" )
		
		return
	end

	traderWindow = {
		wnd = guiCreateWindow ( sw * 0.04, sh * 0.3, 250, 400, "Торговец", false )
	}
	traderWindow.lstItems = guiCreateGridList ( 0.02, 0.13, 0.96, 0.76, true, traderWindow.wnd )
	guiGridListSetSortingEnabled ( traderWindow.lstItems, false )
	guiGridListAddColumn ( traderWindow.lstItems, "Meal", 0.5 )
	guiGridListAddColumn ( traderWindow.lstItems, "Cost", 0.4 )

	local interior = getElementInterior ( localPlayer )
	for _, meal in ipairs ( foods [ interior ] ) do
		local row = guiGridListAddRow ( traderWindow.lstItems )
		guiGridListSetItemText ( traderWindow.lstItems, row, 1, meal [ 1 ], false, false )
		guiGridListSetItemText ( traderWindow.lstItems, row, 2, tostring ( meal [ 2 ] ), false, false )
	end
	
	traderWindow.btnCancel = guiCreateButton ( 0.02, 0.9, 0.46, 0.07, "Назад", true, traderWindow.wnd )
	traderWindow.btnBuy = guiCreateButton ( 0.5, 0.9, 0.46, 0.07, "Купить", true, traderWindow.wnd )
	
	addEventHandler ( "onClientGUIClick", traderWindow.wnd, traderClick )
	
	showCursor ( true )
	guiSetInputEnabled ( true )
end

function traderClick ( )
	if source == traderWindow.lstItems then
		local selectedMeal = guiGridListGetSelectedItem ( traderWindow.lstItems )
		if selectedMeal < 0 then
			return
		end
		
		local interior = getElementInterior ( localPlayer )
		local model = foods [ interior ] [ selectedMeal + 1 ] [ 3 ]
		
		if traderWindow.object then
			ClientTaskFoodShop.start ( traderWindow.ped, traderWindow.object, "TO_CHANGE", model )
		else
			traderWindow.object = createObject ( model, getElementPosition ( traderWindow.ped ) )
			
			local interior = getElementInterior ( traderWindow.ped )
			setElementInterior ( traderWindow.object, interior )
			local dimension = getElementDimension ( traderWindow.ped )
			setElementDimension ( traderWindow.object, dimension )
			
			ClientTaskFoodShop.start ( traderWindow.ped, traderWindow.object, "TO_GRAB" )
		end
	elseif source == traderWindow.btnCancel then
		if traderWindow.object then
			ClientTaskFoodShop.start ( traderWindow.ped, traderWindow.object, "TO_DROP" )
			traderWindow.object = nil
		end
	
		destroyElement ( traderWindow.wnd )
		traderWindow = nil
		showCursor ( false )
		guiSetInputEnabled ( false )
	elseif source == traderWindow.btnBuy then
		local selectedMeal = guiGridListGetSelectedItem ( traderWindow.lstItems )
		if selectedMeal < 0 then
			return
		end
		
		triggerServerEvent ( "onMealBuy", resourceRoot, selectedMeal + 1 )
	end
end

addEventHandler ( "onClientMarkerHit", resourceRoot,
	function ( player, matchingDimension )
		if not matchingDimension then
			return
		end
		
		--Получаем продавца
		local seller = getElementParent ( source )
		
		createTraderWindow ( )
		traderWindow.ped = seller
	end
)

addEventHandler ( "onClientPedDamage", resourceRoot,
	function ( )
		cancelEvent ( )
	end
)