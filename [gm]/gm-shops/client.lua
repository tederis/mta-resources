local sw, sh = guiGetScreenSize ( )

local trade = { }

function loadFromXml ( filepath )
	local xmlfile = xmlLoadFile ( filepath )
	if not xmlfile then
		return false
	end
	
	local items = { }
	
	for i, group in ipairs ( xmlNodeGetChildren ( xmlfile ) ) do
		local groupData = {
			name = xmlNodeGetAttribute ( group, "name" )
		}
			
		table.insert ( items, groupData )
			
		for _, weapon in ipairs ( xmlNodeGetChildren ( group ) ) do
			local weaponData = {
				id = xmlNodeGetAttribute ( weapon, "id" ),
				name = xmlNodeGetAttribute ( weapon, "name" ),
				cost = xmlNodeGetAttribute ( weapon, "cost" ),
				model = xmlNodeGetAttribute ( weapon, "model" )
			}
				
			table.insert ( items [ i ], weaponData )
		end
	end
		
	xmlUnloadFile ( xmlfile )
		
	return items
end

local tradeWeapon = {
	name = "Weapon",
	
	items = loadFromXml ( "weapons.xml" ),
	onSelected = function ( item )
		if trade.object then
			local model = tonumber ( item.model )
		
			if getElementModel ( trade.object ) ~= model then
				ClientTaskManager.start ( ClientTaskWeapon, trade.seller, trade.object, "TO_CHANGE", model )
			end
		else
			trade.object = createObject ( item.model, getElementPosition ( trade.seller ) )
			
			local interior = getElementInterior ( trade.seller )
			setElementInterior ( trade.object, interior )
			local dimension = getElementDimension ( trade.seller )
			setElementDimension ( trade.object, dimension )
			
			ClientTaskManager.start ( ClientTaskWeapon, trade.seller, trade.object, "TO_GRAB" )
		end
	end,
	onApply = function ( item )
		triggerServerEvent ( "onWeaponBuy", resourceRoot, item.id )
	end,
	onCancel = function ( )
		if trade.object then
			ClientTaskManager.start ( ClientTaskWeapon, trade.seller, trade.object, "TO_DROP" )
			trade.object = nil
		end
		
		setCameraTarget ( localPlayer )
	end
}

local tradeMeal = {
	name = "Meal",
	
	onSelected = function ( item )
		if trade.object then
			local model = tonumber ( item.model )
		
			if getElementModel ( trade.object ) ~= model then
				ClientTaskManager.start ( ClientTaskMeal, trade.seller, trade.object, "TO_CHANGE", model )
			end
		else
			trade.object = createObject ( item.model, getElementPosition ( trade.seller ) )
			
			local interior = getElementInterior ( trade.seller )
			setElementInterior ( trade.object, interior )
			local dimension = getElementDimension ( trade.seller )
			setElementDimension ( trade.object, dimension )
			
			ClientTaskManager.start ( ClientTaskMeal, trade.seller, trade.object, "TO_GRAB" )
		end
	end,
	onApply = function ( item )
		triggerServerEvent ( "onMealBuy", resourceRoot, item.model )
	end,
	onCancel = function ( )
		if trade.object then
			ClientTaskManager.start ( ClientTaskMeal, trade.seller, trade.object, "TO_DROP" )
			trade.object = nil
		end
		
		setCameraTarget ( localPlayer )
	end
}

addEventHandler ( "onClientMarkerHit", resourceRoot,
	function ( player, matchingDimension )
		if not matchingDimension then
			return
		end
		
		local name = getElementData ( source, "name" )
		if name == "AMMUN" then
			tradeGUI.create ( tradeWeapon )
		elseif name == "FDPIZA" then
			tradeMeal.items = {
				{
					name = "All",
					
					{ name = "Buster", cost = 2, model = 2218 },
					{ name = "Double D-Luxe", cost = 5, model = 2219 },
					{ name = "Full Rack", cost = 10, model = 2220 },
					{ name = "Salad Meal", cost = 10, model = 2355 }
				}
			}
			
			tradeGUI.create ( tradeMeal )
		elseif name == "FDCHICK" then
			tradeMeal.items = {
				{
					name = "All",
					
					{ name = "Cluckin' Little Meal", cost = 2, model = 2215 },
					{ name = "Cluckin' Big Meal", cost = 5, model = 2216 },
					{ name = "Cluckin' Huge Meal", cost = 10, model = 2217 },
					{ name = "Salad Meal", cost = 10, model = 2353 }
				}
			}
			
			tradeGUI.create ( tradeMeal )
		elseif name == "FDBURG" then
			tradeMeal.items = {
				{
					name = "All",
					
					{ name = "Moo Kids Meal", cost = 2, model = 2213 },
					{ name = "Beef Tower", cost = 5, model = 2214 },
					{ name = "Meat Stack", cost = 10, model = 2212 },
					{ name = "Salad Meal", cost = 5, model = 2354 }
				}
			}
			
			tradeGUI.create ( tradeMeal )
		end
		
		--Получаем продавца
		trade.seller = getElementParent ( source )
		
		local offsetX, offsetY, offsetZ = getElementData ( source, "offsetX" ), 
			getElementData ( source, "offsetY" ), getElementData ( source, "offsetZ" )
			
		setCameraMatrix ( 
			296.585 + offsetX, -38.345 + offsetY, 1002.236 + offsetZ, 
			296.501 + offsetX, -39.298 + offsetY, 1001.943 + offsetZ 
		)
		-- -0.084000000000003, -0.953, -0.29300000000001
	end
)

addEventHandler ( "onClientPedDamage", resourceRoot,
	function ( )
		cancelEvent ( )
	end
)