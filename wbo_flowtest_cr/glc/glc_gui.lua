local sw, sh = guiGetScreenSize ( )

NENodeList = {
	x = 10, y = sh * 0.25, width = 200, height = 500,
	
	nOffset = 3,
	
	backgrndColor = tocolor ( 55, 60, 70, 230 ),
	nColor = tocolor ( 50, 50, 50, 255 ),
	textColor = tocolor ( 255, 255, 255, 255 ),
	selTextColor = tocolor ( 255, 100, 0, 255 ),
	sepColor = tocolor ( 45, 55, 60, 255 ),
	nFrameColor = tocolor ( 0, 0, 0, 255 )
}

local _drawRectangle = dxDrawRectangle
local _drawText = dxDrawText
local _drawLine = dxDrawLine

local serviceItems = {
	--"Add Entity",
	
}

function NENodeList.create ( serviceFn, nodeFn )
	if NENodeList.visible then
		return
	end
	
	NENodeList.callbackServiceFn = serviceFn
	NENodeList.callbackNodeFn = nodeFn
	
	NENodeList.gHeight = NENodeList.height / 20
	NENodeList.nWidth = NENodeList.width - NENodeList.nOffset*2
	NENodeList.nHeight = NENodeList.gHeight * 1.2
	NENodeList.currentGroup = 1

	addEventHandler ( "onClientRender", root, NENodeList.onRender, false )
	addEventHandler ( "onClientCursorMove", root, NENodeList.onCursorMove, false )
	addEventHandler ( "onClientClick", root, NENodeList.onClick, false )
	
	NENodeList.visible = true
	
	NENodeList.settingWnd = guiCreateWindow ( NENodeList.x, NENodeList.y - 115 - 10, NENodeList.width, 115, "Settings", false )
	--guiWindowSetSizable ( NENodeList.settingWnd, false )
	
	NENodeList.publicCB = guiCreateCheckBox ( 10, 10, 150, 50, _L"GlcPubAcc", true, false, NENodeList.settingWnd )
	NENodeList.resetBtn = guiCreateButton ( 10, 55, 150, 20, _L"GlcReset", false, NENodeList.settingWnd )
	addEventHandler ( "onClientGUIClick", NENodeList.resetBtn,
		function ( )
			NENodeEditor.resetCenter ( )
		end
	, false, "low" )
	--[[NENodeList.publicBtn = guiCreateButton ( 10, 80, 150, 20, "Разместить", false, NENodeList.settingWnd )
	addEventHandler ( "onClientGUIClick", NENodeList.publicBtn,
		function ( )
			NEWorkspace.resetCenter ( )
		end
	, false, "low" )]]
	
	NENodeList.modeBtn = guiCreateButton ( sw / 2 - 50, sh * 0.1, 100, 30, "Node editor", false )
	addEventHandler ( "onClientGUIClick", NENodeList.modeBtn,
		function ( )
			local mode = NEWorkspace.mode
			guiSetText ( NENodeList.modeBtn, mode == "node" and "GUI editor" or "Node editor" )
			NEWorkspace.setEditMode ( mode == "node" and "gui" or "node" )
		end
	, false )
end

function NENodeList.destroy ( )
	if NENodeList.visible then
		NENodeList.callbackFn = nil
		
		removeEventHandler ( "onClientRender", root, NENodeList.onRender )
		removeEventHandler ( "onClientCursorMove", root, NENodeList.onCursorMove )
		removeEventHandler ( "onClientClick", root, NENodeList.onClick )
		
		NENodeList.visible = false
		
		destroyElement ( NENodeList.settingWnd )
		destroyElement ( NENodeList.modeBtn )
	end
end

function NENodeList.onRender ( )
	local self = NENodeList
	local posy = self.y
	
	for i, item in ipairs ( serviceItems ) do
		local isSelected = self.selectedLst == 0 and i == NENodeList.selectedGroup
	
		local iy = posy + ( NENodeList.gHeight * ( i - 1 ) )
		_drawRectangle ( NENodeList.x, iy, NENodeList.width, NENodeList.gHeight, NENodeList.backgrndColor )
		_drawText ( item, NENodeList.x + 10, iy, NENodeList.x + NENodeList.width, iy + NENodeList.gHeight, isSelected and self.selTextColor or self.textColor, 1, "clear", "left", "center" )
		
		_drawLine ( NENodeList.x, iy + NENodeList.gHeight, NENodeList.x + NENodeList.width, iy + NENodeList.gHeight, NENodeList.sepColor, 1, true )
	end
	
	posy = posy + ( self.gHeight * #serviceItems ) + self.nOffset

	for i, group in ipairs ( gNodeRefGroups ) do
		local isSelected = self.selectedLst == 1 and i == NENodeList.selectedGroup
	
		local iy = posy + ( NENodeList.gHeight * ( i - 1 ) )
		_drawRectangle ( NENodeList.x, iy, NENodeList.width, NENodeList.gHeight, NENodeList.backgrndColor )
		_drawText ( group.name, NENodeList.x + 10, iy, NENodeList.x + NENodeList.width, iy + NENodeList.gHeight, isSelected and self.selTextColor or self.textColor, 1, "clear", "left", "center" )
		
		_drawLine ( NENodeList.x, iy + NENodeList.gHeight, NENodeList.x + NENodeList.width, iy + NENodeList.gHeight, NENodeList.sepColor, 1, true )
		
		if i == NENodeList.currentGroup then
			local groupHeight = NENodeList.nOffset + ( NENodeList.nHeight + NENodeList.nOffset ) * #group
			_drawRectangle ( NENodeList.x, iy + NENodeList.gHeight, NENodeList.width, groupHeight, NENodeList.backgrndColor )
			
			for n, nodeRef in ipairs ( group ) do
				local isNodeSelected = n == self.selectedNode
			
				local nx = NENodeList.x + NENodeList.nOffset
				local ny = iy + NENodeList.gHeight + NENodeList.nOffset + ( ( NENodeList.nHeight + NENodeList.nOffset ) * ( n - 1 ) )
				_drawRectangle ( nx, ny, NENodeList.nWidth, NENodeList.nHeight, NENodeList.nColor )
				_drawText ( nodeRef.name, nx, ny, nx + NENodeList.nWidth, ny + NENodeList.nHeight, isNodeSelected and self.selTextColor or self.textColor, 1, "clear", "center", "center" )
				dxDrawRectangleFrame ( nx, ny, NENodeList.nWidth, NENodeList.nHeight, NENodeList.nFrameColor, 1.1 )
			end
			
			posy = posy + groupHeight
		end
	end
end

function NENodeList.onCursorMove ( _, _, cx, cy )
	local self = NENodeList
	
	NENodeList.selectedGroup = nil
	self.selectedNode = nil

	local selGroupHeight = NENodeList.nOffset + ( ( self.nHeight + self.nOffset ) * #gNodeRefGroups [ self.currentGroup ] )
	local bheight = ( self.gHeight * #gNodeRefGroups ) + selGroupHeight
	
	local serviceHeight = self.gHeight * #serviceItems
	if isPointInBox ( cx, cy, self.x, self.y, self.width, serviceHeight ) then	
		self.selectedLst = 0
		
		local selectedItem = math.floor ( ( cy - self.y ) / self.gHeight ) + 1
		self.selectedGroup = selectedItem
	elseif isPointInBox ( cx, cy, self.x, self.y + serviceHeight + self.nOffset, self.width, bheight ) then
		self.selectedLst = 1
	
		local gy = self.y + serviceHeight + self.nOffset
		local selectedGroup = math.floor ( ( cy - gy ) / self.gHeight ) + 1
		
		if selectedGroup > self.currentGroup then
			local groupy = gy + ( self.gHeight * self.currentGroup )
			local nHeight = self.nHeight + NENodeList.nOffset
			
			local selectedNode = math.floor ( ( cy - groupy ) / nHeight ) + 1
			
			if selectedNode > #gNodeRefGroups [ self.currentGroup ] then
				groupy = groupy + selGroupHeight
				selectedGroup = self.currentGroup + math.floor ( ( cy - groupy ) / self.gHeight ) + 1
				NENodeList.selectedGroup = selectedGroup
				
				return
			end
			
			self.selectedNode = selectedNode
			
			return
		end
		
		NENodeList.selectedGroup = selectedGroup
	end
end

function NENodeList.onClick ( button, state, cx, cy )
	if state ~= "down" or button ~= "left" then
		return
	end
	
	local self = NENodeList
	
	-- Если мы кликнули по первому списку
	if self.selectedLst == 0 then
		if self.callbackServiceFn then pcall ( self.callbackServiceFn, serviceItems [ self.selectedGroup ] ) end;
		
		return
	end
	
	if self.selectedGroup then self.currentGroup = self.selectedGroup return end;
	
	if self.selectedNode then
		local nodeRef = gNodeRefGroups [ self.currentGroup ] [ self.selectedNode ]
	
		if self.callbackNodeFn then pcall ( self.callbackNodeFn, nodeRef ) end;
	end
end

function NENodeList.setPublic ( state )
	guiCheckBoxSetSelected ( NENodeList.publicCB, state )
end

function NENodeList.isPublic ( )
	return guiCheckBoxGetSelected ( NENodeList.publicCB )
end

--------------------------
-- NEDebugForm
--------------------------
NEDebugForm = { }

function NEDebugForm.create ( graph )
	NEDebugForm.graph = graph

	local width, height = 500, 150
	NEDebugForm.wnd = guiCreateWindow ( sw/2 - width/2, sh - height - 50, width, height, "Debug", false )
	NEDebugForm.memo = guiCreateMemo ( 0.02, 0.15, 0.96, 0.75, "TCT GC: FlowEditor", true, NEDebugForm.wnd )
	
end

function NEDebugForm.destroy ( )
	destroyElement ( NEDebugForm.wnd )
	NEDebugForm.graph = nil
end

function NEDebugForm.outputString ( str )
	if NEDebugForm.graph ~= nil then
		local text = guiGetText ( NEDebugForm.memo )
		text = text .. str .. "\n"
		guiSetText ( NEDebugForm.memo, text )
	end
end