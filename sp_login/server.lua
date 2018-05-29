xrLogin = { 

}

local QUERY_CHARCHECK = 0
local QUERY_CHARNEW = 1
local QUERY_CHARSGET = 3

function xrLogin.init ( self )
	self.db = dbConnect ( "sqlite", "data.db" )
	
	dbExec ( self.db, [[CREATE TABLE IF NOT EXISTS characters (
		id INTEGER PRIMARY KEY, account TEXT, name TEXT, health INTEGER, armor INTEGER, faction INTEGER, rank INTEGER, reputation INTEGER, bio TEXT, icon INTEGER
	)]] )
end

-- Главный обработчик основных SQL запросов
function xrLogin.queryHandler ( qh, queryType, ... )
	local result, numRows, lastId = dbPoll ( qh, 0 )
	if not result then
		outputConsole ( "dbPoll failed. Error code: " .. tostring ( numRows ) .. "  Error message: " .. tostring ( lastId ) )
		return
	end
	local args = { ... }
	
	-- Запрос на проверку персонажа с именем charName
	if queryType == QUERY_CHARCHECK then
		local player, charName, factionIndex = unpack ( args )
		
		-- Если персонаж с таким именем уже существует
		if table.getn ( result ) > 0 then
			outputDebugString ( "Уже есть" )
			triggerClientEvent ( player, "onClientXrCharacterPacket", resourceRoot )
		else
			local account = getPlayerAccount ( player )
			local accountName = getAccountName ( account )
		
			dbQuery ( 
				xrLogin.queryHandler, { QUERY_CHARNEW, player, charName, factionIndex }, xrLogin.db, 
				[[INSERT INTO characters (account, name, health, armor, faction, rank, reputation, bio, icon)
				  VALUES (?,?,?,?,?,?,?,?,?)]]
				, accountName, charName, 100, 0, factionIndex, 0, 0, "", 0 
			)
		end
	
	-- Запрос на создание персонажа
	elseif queryType == QUERY_CHARNEW then
		local player, charName, factionIndex = unpack ( args )
		
		if numRows > 0 then
			triggerClientEvent ( player, "onClientXrCharacterPacket", resourceRoot, lastId )
		end
		
	-- Запрос на получение всех персонажей игрока
	elseif queryType == QUERY_CHARSGET then
		local player = unpack ( args )
		local packed = { }
		
		for _, row in ipairs ( result ) do
			local id = tonumber ( row.id )
			if not id then
				outputDebugString ( "Не был найден id для персонажа", 2 )
				return
			end
			local health = tonumber ( row.health ) or 0
			local armor = tonumber ( row.armor ) or 0
			local faction = tonumber ( row.faction ) or 0
			local rank = tonumber ( row.rank ) or 0
			local reputation = tonumber ( row.reputation ) or 0
			local icon = tonumber ( row.icon ) or 1
			table.insert ( packed, {
				id, row.name, health, armor, faction, rank, reputation, row.bio, icon
			} )
		end
		
		triggerClientEvent ( player, "onClientXrStartPacket", resourceRoot, packed )
	end
end

function xrLogin.setupPlayer ( self, player )
	local account = getPlayerAccount ( player )
	if isGuestAccount ( account ) then
		outputDebugString ( "Игрок должен быть авторизован", 2 )
		return
	end
	local accountName = getAccountName ( account )

	dbQuery ( self.queryHandler, { QUERY_CHARSGET, player }, self.db, "SELECT * FROM characters WHERE account=?", accountName )
end

addEvent ( "onXrLogin", true )
addEventHandler ( "onXrLogin", resourceRoot,
	function ( name, pass )
		if utfLen ( pass ) < 4 then
			return
		end
		
		local account = getAccount ( name, pass )
		if account then
			if isGuestAccount ( account ) then
				logIn ( client, account, pass )
			end
		else
			outputDebugString ( "Логин или пароль указан неправильно" )
			return
		end
		
		triggerClientEvent ( client, "onClientXrLoginSuccess", resourceRoot )
	end
, false )

addEvent ( "onXrCharacterNew", true )
addEventHandler ( "onXrCharacterNew", resourceRoot,
	function ( charName, factionIndex )
		local account = getPlayerAccount ( client )
		if isGuestAccount ( account ) then
			outputDebugString ( "Игрок должен быть авторизован", 2 )
			return
		end
	
		dbQuery ( xrLogin.queryHandler, { QUERY_CHARCHECK, client, charName, factionIndex }, xrLogin.db, "SELECT id FROM characters WHERE name=?", charName )
	end
, false )

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		xrLogin:init ( )
		
		setTimer (
			function ( )
				for _, player in ipairs ( getElementsByType ( "player" ) ) do
					xrLogin:setupPlayer ( player )
				end
			end
		, 1000, 1 )
	end
, false )

addEventHandler ( "onPlayerLogin", root,
	function ( _, account )
		xrLogin:setupPlayer ( source )
	end
)

addEvent ( "onCharacterJoin", true )
addEventHandler ( "onCharacterJoin", resourceRoot,
	function ( )
		-- Join the game!
	end
, false )