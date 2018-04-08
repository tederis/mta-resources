sw, sh = guiGetScreenSize ( )

RoomCatalog = { }

local loadedRooms = { 
	-- [room1] = itemIndex
}

local creatorPage
local mainPage
local adminPage
local settingsPage
local graphsPage
local scriptsPage

---------------------------------
-- Creator page
---------------------------------
creatorPage = {
	controls = {
		{ "btn",
			text = _LD"RCCBack",
			onClick = function ( )
				RoomCatalog.pageControl:setPage ( mainPage )
			end
		},
		{ "lbl",
			text = _LD"RCCText"
		},
		{ "edit",
			text = _LD"TFEditorNm",
			id = "name"
		},
		{ "btn",
			text = _LD"RCCCont",
			onClick = function ( )
				local name = guiGetText ( creatorPage._controls [ "name" ].element )
				if utfLen ( name ) < 3 then
					outputChatBox ( _L"RCCWarn", 255, 0, 0 )
					return
				end
				
				RoomCatalog.createRoom ( name )
				RoomCatalog.pageControl:setPage ( mainPage )
			end
		}
	}
}

---------------------------------
-- Main page
---------------------------------
local function searchRoomsWithName ( searchStr )
	if utfLen ( searchStr ) > 0 then
		searchStr = string.upper ( searchStr )
		local control = mainPage._controls [ "rooms" ]
		guiGridListClear ( control.element )
		for _, room in ipairs ( loadedRooms ) do
			if string.find ( string.upper ( room [ 1 ] ), searchStr, 1, true ) then
				local row = guiGridListAddRow ( control.element )
				guiGridListSetItemText ( control.element, row, 1, tostring ( room [ 1 ] ), false, false )
				local players = getPlayersInRoom ( room [ 4 ] )
				guiGridListSetItemText ( control.element, row, 2, players ~= nil and tostring ( #players ) or "0", false, false )
				guiGridListSetItemText ( control.element, row, 3, tostring ( room [ 2 ] ), false, false )
				guiGridListSetItemData ( control.element, row, 1, room [ 4 ] )
			
				-- Возвращаем выбор комнаты
				if room [ 4 ] == mainPage.selectedRoom then
					guiGridListSetSelectedItem ( control.element, row, 1, true )
				end
			end
		end
	else
		mainPage:updateList ( )
	end
end

mainPage = {
	controls = {
		{ "btn", 
			text = _LD"RCMCreate",
			onClick = function ( )
				RoomCatalog.pageControl:setPage ( creatorPage )
			end
		},
		{ "edit",
			atp = true,
			width = 100,
			id = "search",
			onChange = function ( )
				local control = mainPage._controls [ "search" ]
				local searchStr = guiGetText ( control.element )
				searchRoomsWithName ( searchStr )
			end
		},
		{ "lbl",
			text = _LD"RCMRooms"
		},
		{ "gridlist",
			id = "rooms",
			width = 365,
			columns = {
				{ name = "Name", width = 0.6 },
				{ name = "Players", width = 0.15 },
				{ name = "Onwer", width = 0.2 },
			},
			onClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem > -1 then 
					mainPage.selectedRoom = guiGridListGetItemData ( control.element, selectedItem, 1 )
				end
			end,
			onDoubleClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem > -1 then
					local room = guiGridListGetItemData ( control.element, selectedItem, 1 )
					if getElementData ( room, "pass", false ) then
						RoomPassword.create ( RoomCatalog.onRoomPassword, room )
					else
						triggerServerEvent ( "doWarpPlayerToRoom", room )
					end
					
					guiSetVisible ( editorForm.wnd, false )
					showCursor ( false )
					guiSetInputEnabled ( false )
				end
			end
		},
		{ "btn",
			text = _LD"RCMAdmin",
			onClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCMWarn", 0, 200, 0 )
					return
				end
				
				local room = guiGridListGetItemData ( control.element, selectedItem, 1 )
				adminPage.room = room
				RoomCatalog.pageControl:setPage ( adminPage )
			end
		},
		{ "btn",
			text = _LD"RCMSett",
			atp = true,
			onClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCMWarn", 0, 200, 0 )
					return
				end
				
				local room = guiGridListGetItemData ( control.element, selectedItem, 1 )
				settingsPage.room = room
				RoomCatalog.pageControl:setPage ( settingsPage )
			end
		},
		{ "btn",
			text = _LD"MF_TGraphs",
			atp = true,
			onClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCMWarn", 0, 200, 0 )
					return
				end
				
				local room = guiGridListGetItemData ( control.element, selectedItem, 1 )
				graphsPage.room = room
				RoomCatalog.pageControl:setPage ( graphsPage )
			end
		},
		{ "btn",
			text = _LD"RCMRemove",
			atp = true,
			onClick = function ( )
				local control = mainPage._controls [ "rooms" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCMWarn", 0, 200, 0 )
					return
				end
				
				local room = guiGridListGetItemData ( control.element, selectedItem, 1 )
				if isElement ( room ) then
					RoomDestroyDialog.create ( room )
				end
			end
		}
	},
	onCreate = function ( self )
		self:updateList ( )
	end,
	updateList = function ( self )
		local control = self._controls [ "rooms" ]
		guiGridListClear ( control.element )
		table.sort ( loadedRooms, 
			function ( a, b ) 
				local aIndex = a [ 2 ] == "Console" and 0 or 1
				local bIndex = b [ 2 ] == "Console" and 0 or 1
				return aIndex < bIndex
			end
		)
		for _, room in ipairs ( loadedRooms ) do
			local row = guiGridListAddRow ( control.element )
			guiGridListSetItemText ( control.element, row, 1, tostring ( room [ 1 ] ), false, false )
			local players = getPlayersInRoom ( room [ 4 ] )
			guiGridListSetItemText ( control.element, row, 2, players ~= nil and tostring ( #players ) or "0", false, false )
			guiGridListSetItemText ( control.element, row, 3, tostring ( room [ 2 ] ), false, false )
			guiGridListSetItemData ( control.element, row, 1, room [ 4 ] )
			
			-- Возвращаем выбор комнаты
			if room [ 4 ] == self.selectedRoom then
				guiGridListSetSelectedItem ( control.element, row, 1, true )
			end
		end
	end
}

local function updateRoomList ( )
	if mainPage.active then
		local control = mainPage._controls [ "search" ]
		local searchStr = guiGetText ( control.element )
		searchRoomsWithName ( searchStr )
		--mainPage:updateList ( )
	end
	if adminPage.active then
		adminPage:updateList ( )
	end
end
-- Обновление списка комнат
setTimer (
	function ( )
		updateRoomList ( )
	end
, 5000, 0 )

---------------------------------
-- Admin page
---------------------------------
adminPage = {
	controls = {
		{ "btn",
			text = _LD"RCCBack",
			onClick = function ( )
				RoomCatalog.pageControl:setPage ( mainPage )
			end
		},
		{ "lbl",
			text = _LD"RCALbl"
		},
		{ "gridlist",
			id = "players",
			columns = { 
				{ name = "Player", width = 0.7 } 
			},
			width = 150,
			onClick = function ( )
				local control = adminPage._controls [ "players" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem > -1 then
					local playerName = guiGridListGetItemText ( control.element, selectedItem, 1 )
					adminPage.player = getPlayerFromName ( playerName )
					if adminPage.player then
						triggerServerEvent ( "onRoomGetPlayerACL", adminPage.room, adminPage.player )
					end
				end
			end
		},		
		{ "btn",
			text = "Kick",
			x = 270, y = 70,
			onClick = function ( )
				if adminPage.player then
					triggerServerEvent ( "onRoomAdminAction", adminPage.room, adminPage.player, 0 )
				end
			end
		},
		{ "btn",
			text = "Ban",
			x = 320, y = 70,
			onClick = function ( )
				if adminPage.player then
					triggerServerEvent ( "onRoomAdminAction", adminPage.room, adminPage.player, 1 )
				end
			end
		},
		{ "btn",
			text = "Mute",
			x = 270, y = 100,
			onClick = function ( )
				if adminPage.player then
					triggerServerEvent ( "onRoomAdminAction", adminPage.room, adminPage.player, 2 )
				end
			end
		},
		{ "combobox",
			id = "acl",
			text = "ACL",
			x = 270, y = 200,
			onAccepted = function ( )
				local selectedItem = guiComboBoxGetSelected ( source )
				if selectedItem > -1 then
					local aclName = guiComboBoxGetItemText ( source, selectedItem )
					triggerServerEvent ( "onRoomAdminAction", adminPage.room, adminPage.player, 3, aclName )
				end
			end
		}
	},
	onCreate = function ( self )
		self.player = nil
	
		if isElement ( self.room ) ~= true then
			return
		end
		
		-- Загружаем список игроков
		self:updateList ( )
		
		-- Загружаем список ACL'ов
		local control = self._controls [ "acl" ]
		local acls = getRoomACLs ( )
		for i, aclName in ipairs ( acls ) do
			guiComboBoxAddItem ( control.element, aclName )
		end
	end,
	updateList = function ( self )
		local control = self._controls [ "players" ]
		guiGridListClear ( control.element )
		
		local players = getPlayersInRoom ( self.room )
		if players then
			for _, player in ipairs ( players ) do
				local row = guiGridListAddRow ( control.element )
				guiGridListSetItemText ( control.element, row, 1, getPlayerName ( player ), false, false )
				
				-- Возвращаем выбор игрока
				if player == self.player then
					guiGridListSetSelectedItem ( control.element, row, 1, true )
				end
			end
		end
	end
}

addEvent ( "onClientRoomPlayerACL", true )
addEventHandler ( "onClientRoomPlayerACL", resourceRoot,
	function ( player, playerACL )
		if adminPage.room ~= source or adminPage.player ~= player then
			return
		end
		
		local aclCtrl = adminPage._controls [ "acl" ]
		local acls = getRoomACLs ( )
		for i, aclName in ipairs ( acls ) do
			if playerACL == aclName then
				guiComboBoxSetSelected ( aclCtrl.element, i - 1 )
				break
			end
		end
		outputDebugString ( "TCT Debug: TCT: Получен ACL для игрока " .. getPlayerName ( player ) .. "(" .. playerACL .. ")", 0 )
	end
)

---------------------------------
-- Settings page
---------------------------------
settingsPage = {
	controls = {
		{ "btn",
			text = _LD"RCCBack",
			onClick = function ( )
				RoomCatalog.pageControl:setPage ( mainPage )
			end
		},
		{ "lbl",
			text = _LD"RCSLbl"
		},
		{ "edit",
			text = _LD"RCSPass",
			id = "pass",
			onBlur = function ( )
				local newPass = guiGetText ( source )
				triggerServerEvent ( "onRoomSettingAction", settingsPage.room, 0, newPass )
			end
		},
		{ "checkbox",
			text = _LD"RCSNoObj",
			onClick = function ( )
				local noObjs = guiCheckBoxGetSelected ( source )
				triggerServerEvent ( "onRoomSettingAction", settingsPage.room, 1, noObjs )
			end
		},
		{
			"checkbox",
			text = _LD"RCSClear",
			onClick = function ( )
				local noWorldModels = guiCheckBoxGetSelected ( source )
				triggerServerEvent ( "onRoomSettingAction", settingsPage.room, 2, noWorldModels )
			end
		}
	}
}

---------------------------------
-- Graphs page
---------------------------------
addEventHandler ( "onClientGUITabSwitched", resourceRoot,
	function ( )
		if source ~= editorForm.graphTab then
			PICK_GRAPH = nil
		end
	end
)

graphsPage = {
	controls = {
		{ "btn",
			text = _LD"RCCBack",
			onClick = function ( )
				RoomCatalog.pageControl:setPage ( mainPage )
			end
		},
		{ "btn",
			text = _LD"RCGAddGr",
			atp = true,
			onClick = function ( )
				guiSetSelectedTab ( editorForm.leftPanel, editorForm.graphTab )
				PICK_GRAPH = true
				outputChatBox ( _L"RCGMsg", 0, 200, 0 )
			end
		},
		{ "lbl",
			text = _LD"RCGLbl"
		},
		{ "gridlist",
			id = "graphs",
			width = 365,
			columns = {
				{ name = "Name", width = 0.9 }
			}
		},
		{ "btn",
			text = _LD"RCMRemove",
			onClick = function ( )
				local control = graphsPage._controls [ "graphs" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCGWarn", 0, 200, 0 )
					return
				end
				
				local graphId = guiGridListGetItemData ( control.element, selectedItem, 1 )
				triggerServerEvent ( "doRemoveRoomGraph", graphsPage.room, graphId )
			end
		}
	},
	onCreate = function ( self )
		if isElement ( self.room ) ~= true then
			return
		end
		
		local control = self._controls [ "graphs" ]
		local graphs = getElementsByType ( "graph", self.room )
		for _, graph in ipairs ( graphs ) do
			local graphId = getElementData ( graph, "id", false )
			local row = guiGridListAddRow ( control.element )
			guiGridListSetItemText ( control.element, row, 1, graphId, false, false )
			guiGridListSetItemData ( control.element, row, 1, tostring ( graphId ) )
		end
	end
}

function RoomCatalog.create ( guitab )
	RoomCatalog.gui = guitab

	RoomCatalog.pageControl = PageGUI.attach ( guitab )
	RoomCatalog.pageControl:setPage ( mainPage )
end

function RoomCatalog.onRoomPassword ( pass, room )
	triggerServerEvent ( "doWarpPlayerToRoom", room, pass )
end

function RoomCatalog.addGraph ( graphId )
	if isElement ( graphsPage.room ) then
		triggerServerEvent ( "doAddRoomGraph", graphsPage.room, graphId )
	end
end

function RoomCatalog.addScript ( scriptId )
	if isElement ( scriptsPage.room ) then
		triggerServerEvent ( "doAddRoomScript", scriptsPage.room, scriptId )
	end
end

--[[
	Mods
]]
function addModToRoom ( modId, room )
	triggerServerEvent ( "doRoomAddMod", room, modId )
end

function removeModFromRoom ( modId, room )
	triggerServerEvent ( "doRoomRemoveMod", room, modId )
end

--[[
	Create room
]]
function RoomCatalog.createRoom ( name )
	triggerServerEvent ( "doCreateRoom", resourceRoot, name )
end

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local rooms = getElementsByType ( "room", resourceRoot )
		for _, room in ipairs ( rooms ) do
			local name = getElementData ( room, "name", false )
			local owner = getElementData ( room, "owner", false )
			local id = getElementData ( room, "id", false )
			local pass = getElementData ( room, "pass", false )

			local roomRef = {
				name,
				owner,
				id,
				room,
				pass or ""
			}
			table.insert ( loadedRooms, roomRef )
		end
	end
, false )

addEvent ( "onClientRoomCreate", true )
addEventHandler ( "onClientRoomCreate", resourceRoot, 
	function ( )
		local name = getElementData ( source, "name", false )
		local owner = getElementData ( source, "owner", false )
		local id = getElementData ( source, "id", false )
		local pass = getElementData ( source, "pass", false ) or ""
		
		--[[if mainPage.active then
			local control = mainPage._controls [ "rooms" ]
			local item = list:addItem ( name )
			item.owner = owner
			item.id = id
			item.element = source
			item.pass = pass
		end]]
		
		local roomRef = {
			name,
			owner,
			id,
			source,
			pass
		}
		table.insert ( loadedRooms, roomRef )
	end
)

addEvent ( "onClientRoomDestroy", true )
addEventHandler ( "onClientRoomDestroy", resourceRoot,
	function ( )
		local id = getElementData ( source, "id", false )
	
		for i, roomRef in ipairs ( loadedRooms ) do
			if roomRef [ 3 ] == id then
				table.remove ( loadedRooms, i )
				break
			end
		end
	end
)

function isPointInRectangle ( x, y, rx, ry, rwidth, rheight )
	return ( x > rx and x < rx + rwidth ) and ( y > ry and y < ry + rheight )
end

RoomPassword = { }

function RoomPassword.create ( callbackFn, ... )
	if RoomPassword.visible == nil then
		RoomPassword.fn = callbackFn
		RoomPassword.args = { ... }
		RoomPassword.width = 300
		RoomPassword.height = 130
		RoomPassword.x = sw / 2 - RoomPassword.width / 2
		RoomPassword.y = sh / 2 - RoomPassword.height / 2
		RoomPassword.pass = ""

		addEventHandler ( "onClientRender", root, RoomPassword.onRender, false, "high" )
		addEventHandler ( "onClientKey", root, RoomPassword.onKey, false )
		addEventHandler ( "onClientCharacter", root, RoomPassword.onCharacter, false )
		
		RoomPassword.visible = true
	end
end

function RoomPassword.destroy ( )
	if RoomPassword.visible then
		removeEventHandler ( "onClientRender", root, RoomPassword.onRender )
		removeEventHandler ( "onClientKey", root, RoomPassword.onKey )
		removeEventHandler ( "onClientCharacter", root, RoomPassword.onCharacter )
	end
	RoomPassword.visible = nil
end

function RoomPassword.onRender ( )
	local this = RoomPassword
	dxDrawRectangle ( this.x, this.y, this.width, this.height, tocolor ( 0, 0, 0, 200 ), true )
	dxDrawText ( getLStr ( _L"RCPassLbl" ), this.x + 20, this.y + 20, this.x + 20 + this.width - 40, 0, tocolor ( 200, 200, 200, 255 ), 1.2, "default", "center", "top", false, true, true )
	dxDrawRectangle ( this.x + 20, this.y + 70, this.width - 40, 40, tocolor ( 80, 80, 80, 255 ), true )
	local text = ""; for i = 1, utfLen ( this.pass ) do text = text .. "*" end;
	dxDrawText ( text, this.x + 40, this.y + 70, 0, this.y + 70 + 40, tocolor ( 200, 200, 200, 255 ), 1.2, "default", "left", "center", false, true, true )
end

function RoomPassword.onKey ( button, pressed )
	if pressed then
		if button == "mouse1" or button == "mouse2" then
			if type ( RoomPassword.fn ) == "function" then RoomPassword.fn ( RoomPassword.pass, unpack ( RoomPassword.args ) ) end;
			RoomPassword.destroy ( )
		elseif button == "backspace" then
			local len = utfLen ( RoomPassword.pass )
			if len > 0 then
				RoomPassword.pass = utfSub ( RoomPassword.pass, 1, len-1 )
			end
		end
	end
end

function RoomPassword.onCharacter ( char )
	RoomPassword.pass = RoomPassword.pass .. char
end

--[[
	Room functions
]]
local playerRoom = { }

addEventHandler ( "onClientElementDataChange", root,
	function ( dataName, _, newValue )
		if getElementType ( source ) == "player" and dataName == "room" then
			playerRoom [ source ] = newValue
		end
	end
)
addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local players = getElementsByType ( "player" )
		for _, player in ipairs ( players ) do
			local room = getElementData ( player, "room", false )
			playerRoom [ player ] = room
		end
	end
, false )

addEventHandler ( "onClientPlayerQuit", root,
	function ( )
		playerRoom [ source ] = nil
	end
, false )

function getPlayersInRoom ( room )
	local playersInRoom = { }
	for player, _room in pairs ( playerRoom ) do
		if isElement ( player ) then
			if _room == room then
				table.insert ( playersInRoom, player )
			end
		end
	end
	return playersInRoom
end

function isElementInRoom ( element, room )
	local dimension = tonumber ( getElementData ( room, "dimension", false ) )
	return getElementDimension ( element ) == dimension
end

-- Список ACL для комнат
local roomAcls = { }
function getRoomACLs ( ) return roomAcls; end;

EditorStartPacket "Start_ACLs" {
	handler = function ( acls )
		roomAcls = acls
	end
}

RoomDestroyDialog = { }

function RoomDestroyDialog.create ( room )
	local this = RoomDestroyDialog
	if this.visible ~= nil then
		return
	end
	
	local width, height = 400, 115
	local x, y = sw / 2 - width / 2, sh / 2 - height / 2
	this.wnd = guiCreateWindow ( x, y, width, height, "Удаление комнаты", false )
	this.lbl = guiCreateLabel ( 10, 20, width - 20, height - 30, "Вы действительно хотите удалить комнату? При удалении будут уничтожены все объекты внутри комнаты и прикрепленные к ней схемы.", false, this.wnd )
	guiLabelSetHorizontalAlign ( this.lbl, "left", true )
	this.btnOK = guiCreateButton ( 10, 70, 185, 30, "Удалить", false, this.wnd )
	addEventHandler ( "onClientGUIClick", this.btnOK,
		function ( )
			if isElement ( RoomDestroyDialog.room ) then
				triggerServerEvent ( "doRemoveRoom", RoomDestroyDialog.room )
			end
			RoomDestroyDialog.destroy ( )
		end
	, false )
	this.btnCancel = guiCreateButton ( 205, 70, 185, 30, "Отмена", false, this.wnd )
	addEventHandler ( "onClientGUIClick", this.btnCancel,
		function ( )
			RoomDestroyDialog.destroy ( )
		end
	, false )
	
	showCursor ( true )
	this.room = room
	this.visible = true
end

function RoomDestroyDialog.destroy ( )
	if RoomDestroyDialog.visible then
		destroyElement ( RoomDestroyDialog.wnd )
	end
	showCursor ( false )
	RoomDestroyDialog.room = nil
	RoomDestroyDialog.visible = nil
end