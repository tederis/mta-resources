local _textColor = tocolor ( 245, 250, 245, 255 )

function math.lerp ( a, b, t )
	return a + (b-a)*t
end

uiLogos = {
	merc_big        = { x = 1   , y = 1   , width = 249 , height = 194 },
    freedom_big     = { x = 257 , y = 1   , width = 249 , height = 194 },
    stalker_big     = { x = 513 , y = 1   , width = 249 , height = 194 },
    bandit_big      = { x = 769 , y = 1   , width = 249 , height = 194 },
    csky_big        = { x = 1   , y = 202 , width = 249 , height = 194 },
    renegade_big    = { x = 257 , y = 202 , width = 249 , height = 194 },
    dolg_big        = { x = 774   , y = 829   , width = 249 , height = 194 },

    merc_logo        = { x = 579 , y = 513 , width = 244 , height = 238 },
    freedom_logo     = { x = 23  , y = 763 , width = 238 , height = 255 },
    stalker_logo     = { x = 295 , y = 400 , width = 260 , height = 255 },
    bandit_logo      = { x = 286 , y = 658 , width = 280 , height = 366 },
    csky_logo        = { x = 574 , y = 205 , width = 277 , height = 304 },
    renegade_logo    = { x = 12  , y = 402 , width = 276 , height = 356 },
    
	actor_big        = { x = 1023 , y = 1023 , width = 1 , height = 1 },
	actor_logo       = { x = 1023 , y = 1023 , width = 1 , height = 1 },
    logos_big_empty  = { x = 1023 , y = 1023 , width = 1 , height = 1 }
}

uiHud = {
	pre_novice  = { x = 0 , y = 728 , width = 46 , height = 47 },
	novice      = { x = 0 , y = 775 , width = 46 , height = 47 },
    experienced = { x = 0 , y = 822 , width = 46 , height = 47 },
    veteran     = { x = 0 , y = 869 , width = 46 , height = 47 },
    master      = { x = 667 , y = 40 , width = 46 , height = 47 }
}

local baseFactions = {
	{ "merc_big", "Наемники", skin = 30 },
	{ "freedom_big", "Свобода", skin = 31 },
	{ "stalker_big", "Одиночки", skin = 32 },
	{ "bandit_big", "Бандиты", skin = 33 },
	{ "csky_big", "Чистое небо", skin = 34 },
	--{ "renegade_big", "Ренегаты", skin = 35 },
	{ "dolg_big", "Долг", skin = 36 }
}

local charactersInfo = {
	{ geom = "merc", tex = "merc", model = 30 },
	{ geom = "armouredsuit", tex = "freedom", model = 31 },
	{ geom = "armouredsuit", tex = "duty", model = 36 },
	{ geom = "leatherjacket", tex = "leatherjacket", model = 32 },
	{ geom = "bandit", tex = "bandit", model = 33 },
	{ geom = "clearskyhood", tex = "clearskyhood", model = 34 }
}

local sceneInfo = {
	geom = "scene",
	tex = "scene",
	col = "scene",
	model = 1000
}

local characters = { }

local flashAnim = {
	[ 0 ] = { r = 255, g = 0, b = 0 },
	[ 28 ] = { r = 255, g = 255, b = 255 },
	[ 31 ] = { r = 0, g = 0, b = 0 },
	[ 42 ] = { r = 255, g = 255, b = 255 },
	[ 48 ] = { r = 255, g = 255, b = 255 },
	[ 49 ] = { r = 0, g = 0, b = 0 }
}
local animCount = 50
local animFps = 50

local function fillAnim ( startKey, endKey )
	local len = ( endKey - startKey ) - 1
	
	for i = 1, len do
		local r, g, b = interpolateBetween ( 
			flashAnim [ startKey ].r, flashAnim [ startKey ].g, flashAnim [ startKey ].b,
			flashAnim [ endKey ].r, flashAnim [ endKey ].g, flashAnim [ endKey ].b,
			i / len, "Linear"
		)
		flashAnim [ startKey + i ] = { r = r, g = g, b = b }
	end
end

local prevKey
for i = 1, animCount do
	local key = flashAnim [ i - 1 ]
	if key then
		if prevKey then
			fillAnim ( prevKey, i - 1 )
		end
		prevKey = i - 1
	end
end

xrInterface = { 
	logoDuration = 5000
}

-- Создает единый интерфейс для управления экранами и меню
function xrInterface.start ( )
	g_Canvas = UICanvas.new ( 0, 0, sw, sh )
	xrInterface.font = dxCreateFont ( "AGLettericaExtraCompressed Roman.ttf", 22 )

	--[[
		Инициализирум сразу же все необходимое для рисования логотипа
	]]
	playSound ( "sounds/8.ogg" )
	
	xrInterface.shader = dxCreateShader ( "logo.fx" )
	xrInterface.logoTex = dxCreateTexture ( "textures/logo.dds" )
	xrInterface.fanTex  = dxCreateTexture ( "textures/FlashLight.bmp" )
	dxSetShaderValue ( xrInterface.shader, "Tex0", xrInterface.logoTex )
	dxSetShaderValue ( xrInterface.shader, "Tex1", xrInterface.fanTex )
	
	xrInterface.logoTime = getTickCount ( )
	xrInterface.logoStage = 0
	
	addEventHandler ( "onClientRender", root, xrInterface.onRender )
	addEventHandler ( "onClientCursorMove", root, xrInterface.onCursorMove )
	addEventHandler ( "onClientClick", root, xrInterface.onClick )
end

function xrInterface.randomThunder ( )
	local rand = math.random ( 1, 3 )
	local sound = playSound ( "sounds/new_thunder" .. rand .. ".ogg", false )
	local soundLen = getSoundLength ( sound ) * 1000
	xrInterface.timer = setTimer ( xrInterface.randomThunder, math.random ( soundLen * 2, soundLen * 5 ), 1 )
end

function xrInterface._initLogin ( )
	xrInterface.setScreen ( xrLoginScreen )
	
	xrInterface.backTexture2 = dxCreateTexture ( "textures/ui_actor_staff_background.dds" )
	xrInterface.backTexture = dxCreateTexture ( "textures/ui_ingame2_back_01.dds" )
	xrInterface.rainTexture = dxCreateTexture ( "textures/raintexture.png" )
	xrInterface.backShader = dxCreateShader ( "shader.fx" )
	dxSetShaderValue ( xrInterface.backShader, "Tex0", xrInterface.backTexture2 )
	dxSetShaderValue ( xrInterface.backShader, "Tex1", xrInterface.backTexture )
	dxSetShaderValue ( xrInterface.backShader, "Tex2", xrInterface.rainTexture )
	
	xrInterface.rainSnd = playSound ( "sounds/new_rain1.ogg", true )
	xrInterface.dropsSnd = playSound ( "sounds/waterdrops2.ogg", true )
	setSoundVolume ( xrInterface.dropsSnd, 0.25 )
	xrInterface.randomThunder ( )
	
	showCursor ( true )
	guiSetInputMode ( "no_binds" )
	
	xrInterface.object = createObject ( sceneInfo.model, 0, 0, 500 )
	setElementAlpha ( xrInterface.object, 0 )
	setCameraMatrix ( 0, 2, 487, 0, 0, 487 )
end

function xrInterface.setScreen ( screen )
	xrInterface.screen = screen
	screen:new ( )
end

function xrInterface.onRender ( )
	--[[
		Login stage render
	]]
	-- Если показ логотипа завершен, мы можем рисовать логин панель
	if xrInterface.logoStage == 3 then
		dxDrawImage ( 0, 0, sw, sh, xrInterface.backShader )
		
		g_Canvas:draw ( )
		
		if xrInterface.screen then
			xrInterface.screen:onRender ( )
		end
		
		return
	end

	--[[
		Logo stage render
	]]
	dxDrawRectangle ( 0, 0, sw, sh, tocolor ( 0, 0, 0 ) )
	
	local now = getTickCount ( )

	if xrInterface.logoStage == 0 then
		if xrInterface.logoLight ~= true and now - xrInterface.logoTime > 1000 then
			-- Ждем некоторое время и освещаем логотип со звуком
			xrInterface.logoLight = true
			xrInterface.logoTime = now
			
			playSound ( "sounds/switch_1.ogg" )
			dxSetShaderValue ( xrInterface.shader, "LightColor", 0.976, 1, 0.911 )
		elseif xrInterface.hear ~= true and now - xrInterface.logoTime > 1250 then
			xrInterface.hear = true
			playSound ( "sounds/hear_3.ogg" )
		end
	else
		if xrInterface.coverFire ~= true and now - xrInterface.logoTime > 1000 then
			xrInterface.coverFire = true
			playSound ( "sounds/cover_fire_3.ogg" )
		elseif xrInterface.explode ~= true and now - xrInterface.logoTime > 3000 then
			xrInterface.explode = true
			playSound ( "sounds/f1_explode2.ogg" )
		end
	end
	
	local elapsedTime = now - xrInterface.logoTime
	local progress = elapsedTime / xrInterface.logoDuration

	local maxScreen = math.min ( sw, sh )
	
	if progress > 1 then
		if xrInterface.logoStage == 0 then
			-- Как только показ логотипа завершен, проигрываем звук и ждем его завершения
			xrInterface.logoStage = 1
			xrInterface.logoTime = now
			xrInterface.logoDuration = 6500
			progress = 0
			
			playSound ( "sounds/giant_underground_0.ogg" )
		elseif xrInterface.logoStage == 1 then
			xrInterface.logoStage = 2
			xrInterface.logoTime = now
			xrInterface.logoDuration = 6500
			progress = 0
			
			-- Как только последняя фаза лого завершена, удаляем все его элементы
			destroyElement ( xrInterface.shader )
			destroyElement ( xrInterface.fanTex )
			
		elseif xrInterface.logoStage == 2 then
			destroyElement ( xrInterface.logoTex )
		
			xrInterface.logoStage = 3
			-- Следом за этим, инициализируем все необходимое для логина
			-- и разрешаем ему рисоваться
			xrInterface._initLogin ( )
		end
	end
	
	local size = maxScreen
	if xrInterface.logoStage == 2 then
		size = 0.5*size
		dxDrawImage ( sw / 2 - size/2, sh / 2 - size/2, size, size, xrInterface.logoTex )
	elseif xrInterface.logoStage < 2 then
		if xrInterface.logoStage == 1 then
			progress = 1 - progress
			dxSetShaderValue ( xrInterface.shader, "LightColor", 0.976 * progress, 1 * progress, 0.911 * progress )
		else
			size = math.lerp ( maxScreen * 0.65, maxScreen, progress )
		end
		
		dxDrawImage ( sw / 2 - size/2, sh / 2 - size/2, size, size, xrInterface.shader )
	end
end

function xrInterface.onCursorMove ( _, _, ax, ay )
	g_Canvas:cursor ( ax, ay )
	
	if xrInterface.screen then
		xrInterface.screen:onCursorMove ( _, _, ax, ay )
	end
end

function xrInterface.onClick ( button, state, absoluteX, absoluteY )
	g_Canvas:click ( button, state, absoluteX, absoluteY )
end

--[[
	xrLoginScreen
]]
xrLoginScreen = { }

function xrLoginScreen.new ( self )
	local width, height = 400, 170
	local x, y = sw/2 - width/2, sh/2 - height/2
	
	xrLoginScreen.wnd = UIWindow.new ( x, y, width, height, "Login by TEDERIs", false )
	UILabel.new ( 30, 40, 100, 100, "Пользователь", false, xrLoginScreen.wnd )
	xrLoginScreen.loginEdt = UIEdit.new ( 130, 35, 240, 0, "Login", false, xrLoginScreen.wnd )
	UILabel.new ( 30, 70, 100, 100, "Пароль", false, xrLoginScreen.wnd )
	xrLoginScreen.passEdt = UIEdit.new ( 130, 65, 240, 0, "Pass", false, xrLoginScreen.wnd )
	xrLoginScreen.passEdt.masked = true
	xrLoginScreen.joinBtn = UIButton.new ( 30, 100, 138, 47, "Sign In", false, xrLoginScreen.wnd )
	xrLoginScreen.joinBtn:addHandler ( "onClick", xrLoginScreen.onButtonClick )
	xrLoginScreen.registerBtn = UIButton.new ( 220, 100, 138, 47, "Sign Up", false, xrLoginScreen.wnd )
	xrLoginScreen.registerBtn:addHandler ( "onClick", xrLoginScreen.onButtonClick )
end

function xrLoginScreen.destroy ( )
	xrLoginScreen.wnd:destroy ( )
end

function xrLoginScreen.onButtonClick ( control, button, state )
	if state ~= "down" then
		return
	end
	
	if control == xrLoginScreen.joinBtn then
		local login = xrLoginScreen.loginEdt.text
		if utfLen ( login ) < 4 then
			outputDebugString ( "Логин должен содержать не меньше 4х символов" )
			return
		end
		local pass = xrLoginScreen.passEdt.text
		if utfLen ( pass ) < 4 then
			outputDebugString ( "Пароль должен содержать не меньше 4х символов" )
			return
		end
	
		triggerServerEvent ( "onXrLogin", resourceRoot, login, pass )
	elseif control == xrLoginScreen.registerBtn then
	
	end
end

function xrLoginScreen.onRender ( self )
end

function xrLoginScreen.onCursorMove ( self )
end

addEvent ( "onClientXrLoginSuccess", true )
addEventHandler ( "onClientXrLoginSuccess", resourceRoot,
	function ( )
		if xrInterface.screen == xrLoginScreen then
			xrLoginScreen.destroy ( )
			xrInterface.setScreen ( xrCharScreen )
		end
	end
, false )

--[[
	xrСharScreen
]]
local CONTENT_CHARSLIST = 0
local CONTENT_CHARNEW = 1

local function getPointFromDistanceRotation ( x, y, dist, angle )
    local a = math.rad(90 - angle)
    local dx = math.cos(a) * dist
    local dy = math.sin(a) * dist
    return x+dx, y+dy
end

xrCharScreen = { }

function xrCharScreen.new ( self )
	self.angle = 0
	self.dist = 2
	self.cursorx = 0

	local width, height = 300, 570
	local x, y = sw - width - 50, sh/2 - height/2
	
	self.charsWnd = UIWindow.new ( x, y, width, height, "Characters", false )
	
	self.content = nil
	self:switchScreenContent ( CONTENT_CHARSLIST )
	
	if table.getn ( characters ) > 0 then
		local x, y, z = 0, 0, 487
		local firstChar = characters [ 1 ]
		local faction = baseFactions [ firstChar.faction ]
		xrCharScreen.ped = createPed ( faction.skin, x, y, z )
		
		self.switchCharacter ( firstChar )
	end
	
	addEventHandler ( "onClientKey", root, xrCharScreen.onKey, false )
end

function xrCharScreen.destroy ( )
	removeEventHandler ( "onClientKey", root, xrCharScreen.onKey )
	
	if isElement ( xrCharScreen.ped ) then
		destroyElement ( xrCharScreen.ped )
	end
	
	xrCharScreen.charsWnd:destroy ( )
	if xrCharScreen.infoWnd then
		xrCharScreen.infoWnd:destroy ( )
	end
	if xrCharScreen.newsWnd then
		xrCharScreen.newsWnd:destroy ( )
	end
	if xrCharScreen.joinBtn then
		xrCharScreen.joinBtn:destroy ( )
	end
end

function xrCharScreen.switchScreenContent ( self, contentType )
	if self.content == contentType then return end;

	for _, child in ipairs ( self.charsWnd:getChildren ( ) ) do
		child:destroy ( )
	end
	
	-- Список персонажей
	if contentType == CONTENT_CHARSLIST then
		self.charLst = UIList.new ( 20, 30, 260, 300, false, self.charsWnd )
		for i, character in ipairs ( characters ) do
			local item = self.charLst:addItem ( character.name )
			item.index = i
		end
		self.charLst:addHandler ( "onClick", xrCharScreen.onCharacterSelect )
		self.charCreateBtn = UIButton.new ( 80, 500, 138, 47, "Add", false, self.charsWnd )
		self.charCreateBtn:addHandler ( "onClick", self.onButtonClick )
	
		-- Кнопка входа в игру
		local width, height = 138 * 1.5, 47 * 1.5
		local x, y = sw/2 - width/2, sh - height - 100
		self.joinBtn = UIButton.new ( x, y, width, height, "В игру!", false )
		self.joinBtn:addHandler ( "onClick", xrCharScreen.onButtonClick )
	
		-- Окно информации слева
		width = 300
		local heightInfo = 270
		local heightNews = 370
		height = heightInfo + heightNews + 50
		
		y = sw/2 - height
		self.infoWnd = UIWindow.new ( 20, y, width, heightInfo, "Information", false )
		
		y = y + heightInfo + 50
		self.newsWnd = UIWindow.new ( 20, y, width, heightNews, "News", false )
	
	-- Форма создания нового персонажа
	elseif contentType == CONTENT_CHARNEW then
		self.joinBtn:destroy ( )
		self.infoWnd:destroy ( )
		self.newsWnd:destroy ( )
	
		self.faction = 1
		local faction = baseFactions [ 1 ]
		local factionUV = uiLogos [ faction [ 1 ] ]
	
		self.factionLbl = UILabel.new ( 0, 20, 300, 0, faction [ 2 ], false, self.charsWnd )
		self.factionLbl.alignment = true
		self.factionImg = UIImage.new ( 75, 40, 150, 150*0.779, "ui_logos", false, self.charsWnd )
		self.factionImg:setSection ( factionUV.x, factionUV.y, factionUV.width, factionUV.height )
		self.factionImg:addHandler ( "onClick", xrCharScreen.onFactionChange )
		self.factionImg.hint = "Click to change a crew"
		UILabel.new ( 0, 175, 300, 0, "Name", false, self.charsWnd ).alignment = true
		self.nameEdt = UIEdit.new ( 75, 200, 150, 0, "", false, self.charsWnd )
		self.nameEdt.maxLength = 20
		self.createBtn = UIButton.new ( 81, 280, 138, 47, "Создать", false, self.charsWnd )
		self.createBtn:addHandler ( "onClick", self.onButtonClick )
		self.cancelBtn = UIButton.new ( 81, 330, 138, 47, "Отмена", false, self.charsWnd )
		self.cancelBtn:addHandler ( "onClick", self.onButtonClick )
	end
	
	self.content = contentType
end

function xrCharScreen.onButtonClick ( control, button, state )
	if button ~= "left" or state ~= "down" then
		return
	end
	
	-- Список персонажей
	if xrCharScreen.content == CONTENT_CHARSLIST then
		if control == xrCharScreen.charCreateBtn then
			xrCharScreen:switchScreenContent ( CONTENT_CHARNEW )
		
			if isElement ( xrCharScreen.ped ) then
				local faction = baseFactions [ 1 ]
				setElementModel ( xrCharScreen.ped, faction.skin )
			else
				local x, y, z = 0, 0, 487
				local faction = baseFactions [ 1 ]
				xrCharScreen.ped = createPed ( faction.skin, x, y, z )
			end
		
			xrCharScreen.character = nil
		elseif control == xrCharScreen.joinBtn then
			triggerServerEvent ( "onCharacterJoin", resourceRoot )
		end
	
	-- Форма создания нового персонажа
	elseif xrCharScreen.content == CONTENT_CHARNEW then
		if control == xrCharScreen.createBtn then
			local name = xrCharScreen.nameEdt.text
			if utfLen ( name ) < 6 then
				outputDebugString ( "Имя персонжа должно содержать не меньше 6 символов" )
				return
			end
	
			triggerServerEvent ( "onXrCharacterNew", resourceRoot, name, xrCharScreen.faction )
		end
		xrCharScreen:switchScreenContent ( CONTENT_CHARSLIST )
		
		if table.getn ( characters ) > 0 then
			local firstChar = characters [ 1 ]
			local faction = baseFactions [ firstChar.faction ]
			setElementModel ( xrCharScreen.ped, faction.skin )
			
			xrCharScreen.switchCharacter ( firstChar )
		else
			destroyElement ( xrCharScreen.ped )
			xrCharScreen.ped = nil
		end
	end
end

function xrCharScreen.onFactionChange ( control, button, state )
	if state ~= "down" then
		return
	end
	
	xrCharScreen.faction = xrCharScreen.faction + 1
	if xrCharScreen.faction > #baseFactions then
		xrCharScreen.faction = 1
	end
	local faction = baseFactions [ xrCharScreen.faction ]
	xrCharScreen.factionLbl:setText ( faction [ 2 ] )
	local factionUV = uiLogos [ faction [ 1 ] ]
	control:setSection ( factionUV.x, factionUV.y, factionUV.width, factionUV.height )
	
	setElementModel ( xrCharScreen.ped, faction.skin )
end

function xrCharScreen.switchCharacter ( character )
	local faction = baseFactions [ character.faction ]
	setElementModel ( xrCharScreen.ped, faction.skin )
		
	if xrCharScreen.character then
		local factionUV = uiLogos [ faction [ 1 ] ]
		
		xrCharScreen.infoFactionLbl:setText ( faction [ 2 ] )
		xrCharScreen.infoFactionImg:setSection ( factionUV.x, factionUV.y, factionUV.width, factionUV.height )
	else
		local factionUV = uiLogos [ faction [ 1 ] ]
				
		xrCharScreen.infoFactionLbl = UILabel.new ( 0, 20, 300, 0, faction [ 2 ], false, xrCharScreen.infoWnd )
		xrCharScreen.infoFactionLbl.alignment = true
		xrCharScreen.infoFactionImg = UIImage.new ( 75, 40, 150, 150*0.779, "ui_logos", false, xrCharScreen.infoWnd )
		xrCharScreen.infoFactionImg:setSection ( factionUV.x, factionUV.y, factionUV.width, factionUV.height )
		xrCharScreen.infoRankLbl = UILabel.new ( 0, 180, 300, 0, "Rank: 0", false, xrCharScreen.infoWnd )
		xrCharScreen.infoRankLbl.alignment = true
		xrCharScreen.infoRepLbl = UILabel.new ( 0, 200, 300, 0, "Reputation: 0", false, xrCharScreen.infoWnd )
		xrCharScreen.infoRepLbl.alignment = true
	end
	xrCharScreen.character = character
end

function xrCharScreen.onCharacterSelect ( control, button, state )
	if state ~= "down" then
		return
	end
	
	local item = control.item
	if not item then
		return
	end
	
	local character = characters [ item.index ]
	if character and character ~= xrCharScreen.character then
		xrCharScreen.switchCharacter ( character )
	end
end

function xrCharScreen.onKey ( button, press )
	if press ~= true then
		return
	end
	
	if button == "mouse1" then
		local cx, cy = getCursorPosition ( )
		if cx then
			xrCharScreen.cursorx = cx * sw
		end
	elseif button == "mouse_wheel_up" then
		xrCharScreen.dist = math.max ( xrCharScreen.dist - 0.3, 1 )
	elseif button == "mouse_wheel_down" then
		xrCharScreen.dist = math.min ( xrCharScreen.dist + 0.3, 4 )
	end
end

function xrCharScreen.onCursorMove ( self, _, _, aX )
	if getKeyState ( "mouse1" ) ~= true then
		return
	end

	local x = aX - self.cursorx
	self.cursorx = aX
 
	self.angle = self.angle + x * 0.1745
end

function xrCharScreen.onRender ( self )
	if self.ped == nil then
		return
	end
	
	local x, y, z = 0, 0, 487 + 0.1
	local cx, cy = getPointFromDistanceRotation ( x, y, self.dist, self.angle )
	--setCameraMatrix ( cx, cy, z, x, y, z )
	
	setPedRotation ( self.ped, self.angle )
	
	local headx, heady, headz = getPedBonePosition ( self.ped, 7 )
	
	local character = self.character
	if character then
		local x, y = getScreenFromWorldPosition ( headx, heady, headz + 0.2 )
		if x then
			local textWidth = dxGetTextWidth ( character.name, 1, "default" )
			dxDrawText ( 
				character.name, x - textWidth/2, y, 0, 0, 
				_textColor, 0.55, xrInterface.font
			)
			
			
			local rankUI = uiHud.novice
			dxDrawImageSection ( 
				x - 23, y - 50, 46, 47,
				rankUI.x, rankUI.y, rankUI.width, rankUI.height,
				"textures/ui_hud.dds"
			)
		end
	end
end

addEvent ( "onClientXrCharacterPacket", true )
addEventHandler ( "onClientXrCharacterPacket", resourceRoot,
	function ( id )
		if id then
			xrCharScreen.charLst:addItem ( id )
		end
	end
, false )

addEvent ( "onClientXrStartPacket", true )
addEventHandler ( "onClientXrStartPacket", resourceRoot,
	function ( packed )
		for i, character in ipairs ( packed ) do
			characters [ i ] = {
				id = character [ 1 ],
				name = character [ 2 ],
				health = character [ 3 ],
				armor = character [ 4 ],
				faction = character [ 5 ],
				rank = character [ 6 ],
				reputation = character [ 7 ],
				bio = character [ 8 ],
				icon = character [ 9 ]
			}
		end
	end
, false )

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		-- Load the scene
		do
			local txd = engineLoadTXD ( "models/" .. sceneInfo.tex .. ".txd", true )
			local col = engineLoadCOL ( "models/" .. sceneInfo.col .. ".col" )
			local dff = engineLoadDFF ( "models/" .. sceneInfo.geom .. ".dff", 0 )
			
			if txd and col and dff then
				engineImportTXD ( txd, sceneInfo.model )
				engineReplaceCOL ( col, sceneInfo.model )
				engineReplaceModel ( dff, sceneInfo.model, true )
			else
				outputDebugString ( "Error occurs while scene loading" )
			end
		end
		
		-- Load character models
		for _, info in ipairs ( charactersInfo ) do
			local txd = engineLoadTXD ( "models/" .. info.tex .. ".txd", true )
			local dff = engineLoadDFF ( "models/" .. info.geom .. ".dff", 0 )
			if txd and dff then
				engineImportTXD ( txd, info.model )
				engineReplaceModel ( dff, info.model, true )
			else
				outputDebugString ( "Error occurs while character loading" )
			end
		end
		
		xrInterface.start ( )
		
		setPlayerHudComponentVisible ( "all", false )
		showChat ( false )
	end
, false )

--[[
	State manager
]]
addEventHandler ( "onClientStateSwitch", root,
	function ( stateName )
		if g_XrState then
			g_XrState.stop ( )
		end
		
		local state = _G [ stateName ]
		if type ( state ) ~= "table" then
			return
		end
		
		state.start ( )
		g_XrState = state
	end
, false )