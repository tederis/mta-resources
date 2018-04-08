GraphCatalog = { }
local settings = { 
	tabWidth = 120,
	tabHeight = 40,
	btnWidth = 60
}

g_LoadedGraphs = { }

local creatorPage
local mainPage

---------------------------------
-- Creator page
---------------------------------
creatorPage = {
	controls = {
		{ "btn",
			text = _LD"RCCBack",
			onClick = function ( )
				GraphCatalog.pageControl:setPage ( mainPage )
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
				local graphName = guiGetText ( creatorPage._controls [ "name" ].element )
				GraphCatalog.createGraph ( graphName )
				GraphCatalog.pageControl:setPage ( mainPage )
			end
		}
	}
}

---------------------------------
-- Main page
---------------------------------
local function searchGraphsWithName ( searchStr )
	if utfLen ( searchStr ) > 0 then
		searchStr = string.upper ( searchStr )
		local control = mainPage._controls [ "graphs" ]
		guiGridListClear ( control.element )
		for i, graphRef in ipairs ( g_LoadedGraphs ) do
			if string.find ( string.upper ( graphRef [ 4 ] ), searchStr, 1, true ) then
				local row = guiGridListAddRow ( control.element )
				guiGridListSetItemText ( control.element, row, 1, graphRef [ 4 ], false, false )
				guiGridListSetItemText ( control.element, row, 2, graphRef [ 2 ], false, false )
				guiGridListSetItemData ( control.element, row, 1, tostring ( graphRef [ 1 ] ) )
			end
		end
	else
		mainPage:updateList ( )
	end
end

mainPage = {
	controls = {
		{ "btn",
			text = _LD"GCCreate",
			atp = true,
			onClick = function ( )
				GraphCatalog.pageControl:setPage ( creatorPage )
			end
		},
		{ "edit",
			atp = true,
			width = 100,
			id = "search",
			onChange = function ( )
				local control = mainPage._controls [ "search" ]
				local searchStr = guiGetText ( control.element )
				searchGraphsWithName ( searchStr )
			end
		},
		{ "lbl",
			text = _LD"GCGraphs"
		},
		{ "gridlist",
			id = "graphs",
			width = 365,
			columns = {
				{ name = "Name", width = 0.7 },
				{ name = "Onwer", width = 0.2 },
			},
			onDoubleClick = function ( )
				-- Выбор графа для комнаты(из cl_catalog)
				if PICK_GRAPH then
					local control = mainPage._controls [ "graphs" ]
					local selectedItem = guiGridListGetSelectedItem ( control.element )
					if selectedItem > -1 then
						local graphId = guiGridListGetItemData ( control.element, selectedItem, 1 )
						RoomCatalog.addGraph ( graphId )
						guiSetSelectedTab ( editorForm.leftPanel, editorForm.roomTab )
					end
				end
				PICK_GRAPH = nil
				-- Выбор графа для элемента(из wbo_cl_tools)
				if Editor.selectGraph then
					local control = mainPage._controls [ "graphs" ]
					local selectedItem = guiGridListGetSelectedItem ( control.element )
					if selectedItem > -1 then
						local graphId = guiGridListGetItemData ( control.element, selectedItem, 1 )
						
						GraphCatalog.request = { graphId, Editor.selectGraph }
						requestGraph ( graphId, GraphCatalog.onRequestGraph )
						
						guiSetSelectedTab ( editorForm.leftPanel, editorForm.roomTab )
						guiSetVisible ( editorForm.wnd, false )
					end
				end
				Editor.selectGraph = nil
			end
		},
		{ "btn",
			text = _LD"GCEdit",
			onClick = function ( )
				local control = mainPage._controls [ "graphs" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCGWarn", 0, 200, 0 )
					return
				end
			
				if GraphCatalog.request ~= nil then
					outputChatBox ( _L"GCGrLoad", 0, 255, 0, true )
				else
					local graphId = guiGridListGetItemData ( control.element, selectedItem, 1 )
					GraphCatalog.request = { graphId }
					requestGraph ( graphId, GraphCatalog.onRequestGraph )
					guiSetVisible ( editorForm.wnd, false )
				end
			end
		},
		{ "btn",
			text = _LD"RCMRemove",
			atp = true,
			onClick = function ( )
				local control = mainPage._controls [ "graphs" ]
				local selectedItem = guiGridListGetSelectedItem ( control.element )
				if selectedItem < 0 then
					outputChatBox ( _L"RCGWarn", 0, 200, 0 )
					return
				end
				
				local graphId = guiGridListGetItemData ( control.element, selectedItem, 1 )
			end
		}
	},
	onCreate = function ( self )
		self:updateList ( )
	end,
	updateList = function ( self )
		local control = self._controls [ "graphs" ]
		guiGridListClear ( control.element )
		for i, graphRef in ipairs ( g_LoadedGraphs ) do
			local row = guiGridListAddRow ( control.element )
			guiGridListSetItemText ( control.element, row, 1, graphRef [ 4 ], false, false )
			guiGridListSetItemText ( control.element, row, 2, graphRef [ 2 ], false, false )
			guiGridListSetItemData ( control.element, row, 1, tostring ( graphRef [ 1 ] ) )
		end
	end
}

function GraphCatalog.create ( guitab )
	local x, y = guiGetRealPosition ( guitab )
	local width, height = guiGetSize ( guitab, false )
	settings.x = x + 10
	settings.y = y + 30
	settings.width = width - 20
	settings.height = height - 20
	
	settings.itemHeight = settings.height / 12
	
	
	GraphCatalog.gui = guitab

	GraphCatalog.pageControl = PageGUI.attach ( guitab )
	GraphCatalog.pageControl:setPage ( mainPage )
end

--[[
	Create graph
]]
function GraphCatalog.createGraph ( name )
	if utfLen ( name ) < 5 then
		outputChatBox ( _L"GCWarn" )
		return
	end
	
	local graph = EditorGraph.create ( )
	if NEWorkspace.open ( graph, name ) and isElement ( Editor.selectGraph ) then
		NEWorkspace.setTarget ( Editor.selectGraph )
	end
	
	guiSetVisible ( editorForm.wnd, false )
	
	Editor.selectGraph = nil
end

function GraphCatalog.onRequestGraph ( id, packedGraph )
	local requestData = GraphCatalog.request
	if requestData ~= nil and requestData [ 1 ] == id then
		local graph = EditorGraph.create ( id )
		graph:unpack  ( packedGraph )
		if NEWorkspace.open ( graph ) and isElement ( requestData [ 2 ] ) then
			NEWorkspace.setTarget ( requestData [ 2 ] )
		end
	end
	GraphCatalog.request = nil
end


function isPointInRectangle ( x, y, rx, ry, rwidth, rheight )
	return ( x > rx and x < rx + rwidth ) and ( y > ry and y < ry + rheight )
end


EditorStartPacket "Start_Graphs" {
	handler = function ( graphs )
		for i = 1, #graphs do
			local graph = graphs [ i ]
			
			table.insert ( g_LoadedGraphs, graph )
		end
	end
}

addEvent ( "onClientCatalogAddGraph", true )
addEventHandler ( "onClientCatalogAddGraph", resourceRoot,
	function ( graph )
		table.insert ( g_LoadedGraphs, graph )
		
		if mainPage.active then
			mainPage:updateList ( )
		end
	end
, false )