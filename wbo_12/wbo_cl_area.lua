xrAreaMenu = {
	width = 480,
	height = 300
}

function xrAreaMenu:show ( area )
	if xrAreaMenu.visible then		
		return
	end

	local ownerName = getElementData ( area, "owner", false )
	local inviteNamesStr = getElementData ( area, "invited", false )
	local inviteNames
	if type ( inviteNamesStr ) == "string" then
		inviteNames = split ( inviteNamesStr, 44 )
	end
	local price = tonumber ( getElementData ( area, "price", false ) )

	local sw, sh = guiGetScreenSize ( )
	self.wnd = guiCreateWindow ( ( sw - self.width ) / 2, ( sh - self.height ) / 2, self.width, self.height, "Area", false )
	if ownerName == getPlayerName ( localPlayer ) then
		guiCreateLabel ( 10, 30, self.width - 20, 20, "Добро пожаловать домой. Что вы хотите сделать с участком?", false, self.wnd )
		-- Продажа
		if price then
			xrAreaMenu.sellBtn = guiCreateButton ( 10, 60, 150, 30, "Отменить продажу", false, self.wnd )
			setElementData ( xrAreaMenu.sellBtn, "sellMode", true )
		else
			xrAreaMenu.sellBtn = guiCreateButton ( 10, 60, 100, 30, "Продать за ", false, self.wnd )
			xrAreaMenu.sellEdt = guiCreateEdit ( 120, 60, 50, 30, "0", false, self.wnd )
			guiCreateLabel ( 180, 65, 10, 20, "$", false, self.wnd )
		end
		-- Инвайт
		xrAreaMenu.inviteBtn = guiCreateButton ( 10, 100, 100, 30, "Пригласить", false, self.wnd )
 		xrAreaMenu.inviteCmb = guiCreateComboBox ( 120, 100, 100, 200, "Игрока", false, self.wnd )
		for _, player in ipairs ( getElementsByType ( "player" ) ) do
			guiComboBoxAddItem ( xrAreaMenu.inviteCmb, getPlayerName ( player ) )
		end
		guiComboBoxSetSelected ( xrAreaMenu.inviteCmb, 0 )
		xrAreaMenu.kickBtn = guiCreateButton ( 230, 100, 100, 30, "Выгнать", false, self.wnd )
		xrAreaMenu.kickCmb = guiCreateComboBox ( 340, 100, 100, 200, "Игрока", false, self.wnd )
		if inviteNames then
			for _, name in ipairs ( inviteNames ) do
				guiComboBoxAddItem ( xrAreaMenu.kickCmb, name )
			end		
			guiComboBoxSetSelected ( xrAreaMenu.kickCmb, 0 )
		end
	else
		guiCreateLabel ( 10, 40, self.width - 20, 20, "Вы находитесь на участке игрока " .. ownerName .. ". Что вы хотите сделать с участком?", false, self.wnd )
		
		if price then
			xrAreaMenu.buyBtn = guiCreateButton ( 10, 60, 100, 30, "Купить за ", false, self.wnd )
			guiCreateLabel ( 120, 60, 50, 30, tostring ( price ) .. "$", false, self.wnd )
		end			
	end
	
	setElementData ( self.wnd, "area", area, false )
	
	addEventHandler ( "onClientGUIClick", self.wnd, xrAreaMenu.onClick )
	
	showCursor ( true )
	
	xrAreaMenu.visible = true
end

function xrAreaMenu:hide ( )
	if xrAreaMenu.visible then
		destroyElement ( self.wnd )
	
		showCursor ( false )
	end
	xrAreaMenu.visible = nil
end

function xrAreaMenu:update ( area )
	xrAreaMenu:hide ( )
	xrAreaMenu:show ( area )
end

function xrAreaMenu.onClick ( )
	local area = getElementData ( source, "area" )
	
	-- Продать
	if source == xrAreaMenu.sellBtn then
		if getElementData ( source, "sellMode", false ) then
			triggerServerEvent ( "onAreaSell", area, false )

			xrAreaMenu:update ( area )
			return
		end
		
		local price = tonumber ( guiGetText ( xrAreaMenu.sellEdt ) )
		if price then
			price = math.floor ( price )
			if price < 0 then
				outputChatBox ( "Цена не может быть отрицательной!", 255, 0, 0, true )
				return
			end
			
			triggerServerEvent ( "onAreaSell", area, price )
		else
			outputChatBox ( "Цена должна быть числом", 255, 0, 0, true )
		end
	-- Купить
	elseif source == xrAreaMenu.buyBtn then
		local price = tonumber ( getElementData ( area, "price", false ) )
		if price then
			triggerServerEvent ( "onAreaBuy", area )
		else
			outputChatBox ( "Участок уже не продается!", 255, 0, 0, true )
		end
		
	-- Пригласить
	elseif source == xrAreaMenu.inviteBtn then
		local index = guiComboBoxGetSelected ( xrAreaMenu.inviteCmb )
		if index > -1 then
			local name = guiComboBoxGetItemText ( xrAreaMenu.inviteCmb, index )
			local player = getPlayerFromName ( name )
			if player then
				triggerServerEvent ( "onAreaInvite", area, player )
			end
		else
			outputChatBox ( "Вы должны выбрать игрока" )
		end
	
	-- Выгнать
	elseif source == xrAreaMenu.kickBtn then
		local index = guiComboBoxGetSelected ( xrAreaMenu.kickCmb )
		if index > -1 then
			local name = guiComboBoxGetItemText ( xrAreaMenu.kickCmb, index )
			local player = getPlayerFromName ( name )
			if player then
				triggerServerEvent ( "onAreaKick", area, player )
			end
		else
			outputChatBox ( "Вы должны выбрать игрока" )
		end
	end
	
	xrAreaMenu:update ( area )
end

local function insideBox ( x, y, bx, by, bw, bh )
	return ( x > bx ) and ( x <= bx + bw ) and ( y > by ) and ( y <= by + bh )
end

local function onAreaKey ( _, state )
	if xrAreaMenu.visible then
		xrAreaMenu:hide ( )
		
		return
	end


	local px, py = getElementPosition ( localPlayer )
	for _, area in ipairs ( getElementsByType ( "area", resourceRoot) ) do
		local x, y = getElementPosition ( area )
		local width = tonumber (
			getElementData ( area, "sizeX", false )
		)
		local depth = tonumber (
			getElementData ( area, "sizeY", false )
		)
		
		if insideBox ( px, py, x - width/2, y - depth/2, width, depth ) then
			xrAreaMenu:show ( area )
		end
	end
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		bindKey ( "q", "down", onAreaKey )
	end
, false )

