--------------------------
-- Player группа        --
-- Работа с игроками    --
--------------------------

--[[
	Player:Player
]]
NodeRef "Player:Player" {
	_target = function ( self, value )
		local playerName = "Guest"
		local account = getPlayerAccount ( value )
		if isGuestAccount ( account ) ~= true then
			playerName = getAccountName ( account )
		end
	
		self:triggerOutput ( 1, playerName )
		
		local team = getPlayerTeam ( value )
		self:triggerOutput ( 2, team and getTeamName ( team ) or "Guest" )
	end,

	events = {
		target = "player",
		outputs = {
			{ "Name", "string" },
			{ "TeamName", "string" },
			{ "onJoin", "any" },
			{ "onWasted", "any" },
			{ "onKill", "any" },
			{ "onStartSpawn", "any" },
			{ "onVehicleEnter", "stream" },
			{ "onVehicleExit", "stream" },
			
		}
	}
}

addEventHandler ( "onPlayerWasted", root,
	function ( totalAmmo, killer, killerWeapon, bodypart, stealth )
		--EventManager.triggerEvent ( source, "Player:Player", 4 )
		--EventManager.triggerEvent ( killer, "Player:Player", 5 )
	end
)

addEventHandler ( "onPlayerVehicleEnter", root,
	function ( vehicle, seat, jacked )
		local out = ArgStream:new ( vehicle, seat, jacked )
		EventManager.triggerEvent ( source, "Player:Player", 7, out ) -- onVehicleEnter
		
		
		
		EventManager.triggerEvent ( source, "Player:Player", 5 )
	end
)

addEventHandler ( "onPlayerVehicleExit", root,
	function ( vehicle, seat, jacker )
		local out = ArgStream:new ( vehicle, seat, jacker )
		EventManager.triggerEvent ( source, "Player:Player", 8, out ) -- onVehicleExit
	end
)

--[[
	Player:WantedLevel
]]
NodeRef "Player:WantedLevel" {
	doSet = function ( self )
		local vars = self.vars
		local stars = tonumber ( vars.Stars )
		if stars then
			setPlayerWantedLevel ( vars.target, math.clamp ( 0, stars, 6 ) )
		end
	end,
	doGiveStar = function ( self )
		local vars = self.vars
		local stars = getPlayerWantedLevel ( vars.target )
		setPlayerWantedLevel ( vars.target, math.min ( stars + 1, 6 ) )
	end,
	doTakeStar = function ( self )
		local vars = self.vars
		local stars = getPlayerWantedLevel ( vars.target )
		setPlayerWantedLevel ( vars.target, math.max ( stars - 1, 0 ) )
	end,

	events = {
		target = "player",
		inputs = {
			{ "doSet", "any" },
			{ "doGiveStar", "any" },
			{ "doTakeStar", "any" },
			{ "Stars", "number" }
		}
	}
}

--[[
	Player:InArea
]]
NodeRef "Player:InArea" {
	doCheck = function ( self )
		local vars = self.vars
		if isElement ( vars.Area ) then
			self:triggerOutput ( isPlayerWithinArea ( vars.target, vars.Area ) == true and 1 or 2 )
			return
		end
		self:triggerOutput ( 2 )
	end,

	events = {
		target = "player",
		inputs = {
			{ "doCheck", "any" },
			{ "Area", "wbo:area" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Player:OccupiedArea
]]
NodeRef "Player:OccupiedArea" {
	doGet = function ( self, value )
		local vars = self.vars
		local area = getPlayerArea ( vars.target )
		if area then
			self:triggerOutput ( 3, area )
			self:triggerOutput ( 1, area )
		else
			self:triggerOutput ( 2, value )
		end
	end,
	
	events = {
		target = "player",
		inputs = {
			{ "doGet", "any" }
		},
		outputs = {
			{ "onTrue", "wbo:area" },
			{ "onFalse", "any" },
			{ "Area", "wbo:area" }
		}
	}
}

--[[
	Player:Money
]]
NodeRef "Player:Money" {
	doGive = function ( self, value )
		
	end,
	doTake = function ( self, value )
		local vars = self.vars
		local account = getPlayerAccount ( vars.target )
		if isGuestAccount ( account ) ~= true then
			local amount = tonumber ( vars.Amount ) or 0
			local money = tonumber ( getAccountData ( account, "tct:money" ) ) or 0
			if money > 0 then
				setPlayerMoney ( vars.target, money - amount )
				setAccountData ( account, "tct:money", tostring ( money - amount ) )
				self:triggerOutput ( 1 )
				return
			end
		end
		self:triggerOutput ( 2 )
	end,
	doSet = function ( self, value )
		local vars = self.vars
		local account = getPlayerAccount ( vars.target )
		if isGuestAccount ( account ) ~= true then
			local amount = tonumber ( vars.Amount ) or 0
			if amount >= 0 then
				setPlayerMoney ( vars.target, amount )
				setAccountData ( account, "tct:money", tostring ( amount ) )
				self:triggerOutput ( 1 )
				return
			end
		end
		self:triggerOutput ( 2 )
	end,
	
	events = {
		target = "player",
		inputs = {
			{ "doGive", "any", "$arg0=setPlayerMoney(@target, @Amount); if($arg)then [@onSuccess] else [@onFail] end;" },
			{ "doTake", "any" },
			{ "doSet", "any" },
			{ "Amount", "number" }
		},
		outputs = {
			{ "onSuccess", "any" },
			{ "onFail", "any" }
		}
	}
}