--------------------------
-- Gui группа           --
-- Интерфейс            --
--------------------------

--[[
	GUI:GUI
]]
local function packArray ( array )
	local outpack = { }
	if type ( array ) == "table" then
		for i = 1, #array do
			outpack [ #outpack + 1 ] = tostring ( array [ i ] [ 2 ] )
		end
	end
	return outpack
end
local function unpackVector2D ( vector )
	if type ( vector ) == "table" then
		return vector.x or 0, vector.y or 0
	end
	return 0, 0
end
local packGUINode = function ( node )
	local guiType = node.abstr.gui
	local vars = node.vars
	
	local x, y = unpackVector2D ( vars.Position )
	local width, height = unpackVector2D ( vars.Size )
	
	local outpack = {
		guiType,
		node.id,
		x, y,
		width, height
	}
	if guiType == "btn" then
		outpack [ 7 ] = tostring ( vars.Text )
	elseif guiType == "checkbox" then
		outpack [ 7 ] = tostring ( vars.Text )
		outpack [ 8 ] = vars.Selected == true
	elseif guiType == "combobox" then
		outpack [ 7 ] = tostring ( vars.Caption )
		outpack [ 8 ] = packArray ( vars.Items )
	elseif guiType == "edit" then
		outpack [ 7 ] = tostring ( vars.Text )
	elseif guiType == "lbl" then
		outpack [ 7 ] = tostring ( vars.Text )
	end
	
	return outpack
end
local packGraphGUI = function ( graph )
	local outpack = { 
		graph.id
	}
	for id, node in pairs ( graph.nodes ) do
		if node.abstr.gui then
			outpack [ #outpack + 1 ] = packGUINode ( node )
		end
	end
	return outpack
end

local nodeCallInterface = { 
	btn = function ( self, player )
		self:triggerOutput ( 2, player )
		self:triggerOutput ( 1 )
	end,
	checkbox = function ( self, player, selected )
		self:triggerOutput ( 4, player )
		self:triggerOutput ( 1, selected )
		self:triggerOutput ( selected == true and 2 or 3 )
		self.vars.Selected = selected == true
	end,
	combobox = function ( self, player, selectedItem )
		self:triggerOutput ( 5, player )
		self:triggerOutput ( 1 )
		self:triggerOutput ( 4, selectedItem )
		
		local vars = self.vars
		local items = vars.Items
		if type ( items ) == "table" and #items > 0 then
			self:triggerOutput ( 2, items [ selectedItem ] [ 1 ] )
			self:triggerOutput ( 3, items [ selectedItem ] [ 2 ] )
		end
	end,
	edit = function ( self, player, text )
		self:triggerOutput ( 3, player )
		self:triggerOutput ( 1, text )
		self:triggerOutput ( 2, text )
		self.vars.Text = text
	end
}
addEvent ( "onGraphGUIAction", true )
addEventHandler ( "onGraphGUIAction", resourceRoot,
	function ( graphId, nodeId, ... )
		local playerGui = getPlayerGUI ( client )
		if playerGui then
			local graph = playerGui:getWindowByID ( graphId )
			if graph then
				local node = graph.nodes [ nodeId ]
				if node then
					local guiType = node.abstr.gui
					nodeCallInterface [ guiType ] ( node, client, ... )
				end
			end
		end
	end
, false )

PlayerGUI = { }
PlayerGUI.__index = PlayerGUI

function PlayerGUI.new ( player )
	local interface = {
		player = player,
		windows = { 
		
		}
	}
	
	return setmetatable ( interface, PlayerGUI )
end

function PlayerGUI:attachWindow ( graph )
	if self.windows [ graph.id ] ~= nil then
		return
	end
	
	self.windows [ graph.id ] = graph
	local packedGUI = packGraphGUI ( graph )
	triggerClientEvent ( self.player, "onClientGUIReceive", resourceRoot, packedGUI )
end

function PlayerGUI:detachWindow ( graph )
	if self.windows [ graph.id ] ~= nil then
		self.windows [ graph.id ] = nil
		triggerClientEvent ( self.player, "onClientGUIHide", resourceRoot, graph.id )
	end
end

function PlayerGUI:detachAll ( )
	self.windows = { }
end

function PlayerGUI:isWindowAttached ( graph )
	return self.windows [ graph.id ] ~= nil
end

function PlayerGUI:getWindowByID ( graphId )
	return self.windows [ graphId ]
end

-- Helper functions
local playerGUIs = { }
local function attachWindowToPlayer ( graph, player )
	local playerGui = playerGUIs [ player ]
	if playerGui then
		playerGui:attachWindow ( graph )
	else
		playerGUIs [ player ] = PlayerGUI.new ( player )
		playerGUIs [ player ]:attachWindow ( graph )
	end
end
local function detachWindowFromPlayer ( graph, player )
	local playerGui = playerGUIs [ player ]
	if playerGui then
		playerGui:detachWindow ( graph )
	end
end
local function detachAllWindowsFromPlayer ( player )
	local playerGui = playerGUIs [ player ]
	if playerGui then
		playerGui:detachAll ( )
	end
end
function getPlayerGUI ( player )
	return playerGUIs [ player ]
end

addEvent ( "onGraphGUIHide", true )
addEventHandler ( "onGraphGUIHide", resourceRoot,
	function ( )
		detachAllWindowsFromPlayer ( client )
	end
, false )


NodeRef "GUI:GUI" {
	doToggle = function ( self )
		--[[local vars = self.vars
		local graph = self.graph
		local interface = getPlayerInterface ( vars.target )
		if interface then
			if interface.graphs [ graph.id ] then
				gNodeRefs [ "GUI:GUI" ].doHide ( self )
			else
				gNodeRefs [ "GUI:GUI" ].doShow ( self )
			end
		else
			gNodeRefs [ "GUI:GUI" ].doShow ( self )
		end]]
	end,
	doShow = function ( self )
		local vars = self.vars
		local graph = self.graph
		attachWindowToPlayer ( graph, vars.target )
		
		
		--[[local interface = findOrCreatePlayerInterface ( vars.target )
		if interface.graphs [ graph.id ] == nil then
			local packedGUI = packGraphGUI ( graph )
			triggerClientEvent ( vars.target, "onClientGUIReceive", resourceRoot, packedGUI )
			interface.graphs [ graph.id ] = true
		end]]
	end,
	doHide = function ( self )
		local vars = self.vars
		local graph = self.graph
		detachWindowFromPlayer ( graph, vars.target )
		
		--[[local interface = getPlayerInterface ( vars.target )
		if interface then
			local graph = self.graph
			if interface.graphs [ graph.id ] then
				triggerClientEvent ( vars.target, "onClientGUIHide", resourceRoot, graph.id )
			end
			interface.graphs [ graph.id ] = nil
		end]]
	end,
	doSetText = function ( self )
		
	end,

	events = {
		target = "player",
		inputs = {
			{ "doToggle", "any" },
			{ "doShow", "any" },
			{ "doHide", "any" },
			{ "doSetText", "any" },
			{ "Text", "string" }
		}
	}
}

--[[
	GUI:Button
]]
NodeRef "GUI:Button" {
	gui = "btn",
	doSetText = function ( self )
		
	end,

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onPressed", "any" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:CheckBox
]]
NodeRef "GUI:CheckBox" {
	gui = "checkbox",
	doSetText = function ( self )
		
	end,

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" },
			{ "Selected", "bool" }
		},
		outputs = {
			{ "onChange", "bool" },
			{ "onSelected", "any" },
			{ "onUnselected", "any" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:ComboBox
]]
NodeRef "GUI:ComboBox" {
	gui = "combobox",

	events = {
		inputs = {
			{ "Caption", "string" },
			{ "Items", "array" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onSelect", "any" },
			{ "Key", "string" },
			{ "Value", "string" },
			{ "Index", "number" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:Edit
]]
NodeRef "GUI:Edit" {
	gui = "edit",
	
	doSetText = function ( self )
		local vars = self.vars
		
	end,
	
	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onChange", "string" },
			{ "Text", "string" },
			{ "Player", "player" }
		}
	}
}

--[[
	GUI:Label
]]
NodeRef "GUI:Label" {
	gui = "lbl",

	events = {
		inputs = {
			{ "doSetText", "any" },
			{ "Text", "string" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		}
	}
}

--[[
	GUI:GridList
]]
NodeRef "GUI:GridList" {
	gui = "list",

	events = {
		inputs = {
			{ "Columns", "_array" },
			{ "Items", "array" },
			{ "Position", "Vector2D" },
			{ "Size", "Vector2D" }
		},
		outputs = {
			{ "onSelect", "any" },
			{ "Key", "string" },
			{ "Value", "string" },
			{ "Index", "number" },
			{ "Player", "player" }
		}
	}
}