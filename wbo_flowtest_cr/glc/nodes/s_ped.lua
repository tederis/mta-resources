--------------------------
-- Ped группа           --
-- Работа с педами      --
--------------------------

--[[
	Ped:Ped
]]
NodeRef "Ped:Ped" {
	events = {
		target = "ped",
		outputs = {
			{ "onWasted", "any" }
		}
	}
}

addEventHandler ( "onPedWasted", resourceRoot,
	function ( totalAmmo, killer, killerWeapon, bodypart, stealth )
		EventManager.triggerEvent ( source, "Ped:Ped", 1 )
	end
)

--[[
	Ped:Animation
]]
NodeRef "Ped:Animation" {
	doSet = function ( self )
		local vars = self.vars
		if vars.target then
			if vars.Loop == true then
				setPedAnimation ( vars.target, vars.Block, vars.Anim, 1, true, true, true, true )
			else
				setPedAnimation ( vars.target, vars.Block, vars.Anim, 1, false, false, true, true )
			end
		end
	end,
	
	doStop = function ( self )
		local vars = self.vars
		if vars.target then setPedAnimation ( vars.target, false ) end;
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "doStop", "any" },
			{ "Block", "string" },
			{ "Anim", "string" },
			{ "Loop", "bool" }
		},
		outputs = {
			{ "onStop", "any" }
		}
	}
}

--[[
	Ped:Weapon
]]
-- Список обязательно дублируется на клиенте
local _weapons = {
	1, 2, 3, 4, 5, 6, 7, 8, 9, 22, 23, 24, 25, 26, 27, 28, 29, 32, 30, 31, 33, 34, 35, 36, 37, 38, 16, 17, 18, 39, 41, 42, 43, 10, 11, 12, 14, 15, 44, 45, 46, 40 
}

NodeRef "Ped:Weapon" { 
	doGive = function ( self )
		local vars = self.vars
		local weaponId = _weapons [ tonumber ( vars.Weapon ) ]
		if weaponId then
			giveWeapon ( vars.target, weaponId, vars.AmmoAmount, vars.SetAsCurrent )
		end
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doGive", "any" },
			{ "Weapon", "_weapon" },
			{ "AmmoAmount", "number" },
			{ "SetAsCurrent", "bool" }
		}
	}
}

--[[
	Ped:Armor
]]
NodeRef "Ped:Armor" {
	doSet = function ( self )
		local vars = self.vars
		if vars.target then setPedArmor ( vars.target, vars.Armor ) end;
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "Armor", "number" }
		}
	}
}

--[[
	Ped:Headless
]]
NodeRef "Ped:Headless" {
	doSet = function ( self )
		local vars = self.vars
		if vars.target then setPedHeadless  ( vars.target, vars.Headless ) end;
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "Headless", "bool" }
		}
	}
}

--[[
	Ped:OnFire
]]
NodeRef "Ped:OnFire" {
	doSet = function ( self )
		local vars = self.vars
		if vars.target then setPedOnFire ( vars.target, vars.OnFire ) end;
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "OnFire", "bool" }
		}
	}
}

--[[
	Ped:InVehicle
]]
NodeRef "Ped:InVehicle" {
	doCheck = function ( self, value )
		local vars = self.vars
		local vehicle = getPedOccupiedVehicle ( vars.target )
		if vehicle then
			if isElement ( vars.Vehicle ) then
				self:triggerOutput ( vehicle == vars.Vehicle and 1 or 2, value )
				return
			end
			self:triggerOutput ( 1, value )
		else
			self:triggerOutput ( 2, value )
		end
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doCheck", "any" },
			{ "Vehicle", "vehicle" }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Ped:OccupiedVehicle
]]
NodeRef "Ped:OccupiedVehicle" {
	doGet = function ( self, value )
		local vars = self.vars
		local vehicle = getPedOccupiedVehicle ( vars.target )
		if vehicle then
			local seat = getPedOccupiedVehicleSeat ( vars.target )
			self:triggerOutput ( 4, seat )
			self:triggerOutput ( 3, vehicle )
			self:triggerOutput ( 1, vehicle )
		else
			self:triggerOutput ( 2, value )
		end
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doGet", "any" }
		},
		outputs = {
			{ "onTrue", "vehicle" },
			{ "onFalse", "any" },
			{ "Vehicle", "vehicle" },
			{ "Seat", "number" }
		}
	}
}

--[[
	Ped:Warp
]]
local warpPending = { }

NodeRef "Ped:Warp" {
	doWarp = function ( self )
		local vars = self.vars
		if _isElementPed ( vars.target ) then
			local x, y, z = vars.Position.x, vars.Position.y, vars.Position.z
			if x and z then
				if getElementType ( vars.target ) == "player" then
					--fadeCamera ( client, false, 1, 0, 0, 0 )
			
					setTimer ( 
						function ( player, posX, posY, posZ, dimension )
							--setElementDimension ( player, dimension )
							setElementPosition ( player, posX, posY, posZ + 1.5, true )
							--fadeCamera ( player, true, 1 )
						end
					, 1000, 1, vars.target, x, y, z )
				else
					setElementPosition ( vars.target, x, y, z + 1.5, true )
				end
			end
		end
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doWarp", "any" },
			{ "Position", "Vector3D" },
		}
	}
}

--[[
	Ped:Skin
]]
NodeRef "Ped:Skin" {
	doSet = function ( self )
		local vars = self.vars
		local skin = tonumber ( vars.Skin )
		if vars.target and isValidSkin ( skin ) then 
			setElementModel ( vars.target, skin ) 
		end
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "Skin", "number" }
		}
	}
}

--[[
	Ped:WalkingStyle
]]
-- Список обязательно дублируется на сервере
local _wstyle = {
	0,
	54,
	55,
	56,
	57,
	58,
	59,
	60,
	61,
	62,
	63,
	64,
	65,
	66,
	67,
	68,
	69,
	70,
	118,
	119,
	120,
	121,
	122,
	123,
	124,
	125,
	126,
	127,
	128,
	129,
	130,
	131,
	132,
	133,
	134,
	135,
	136,
	137,
	138
}
local function getPedInternalWalkingStyle ( ped )
	local style = getPedWalkingStyle ( ped )
	for i = 1, #_wstyle do
		if _wstyle [ i ] == style then
			return i
		end
	end
	return 1
end

NodeRef "Ped:WalkingStyle" {
	_target = function ( self, value )
		local style = getPedInternalWalkingStyle ( value )
		self:triggerOutput ( 1, style )
	end,
	doSet = function ( self )
		local vars = self.vars
		local style = _wstyle [ tonumber ( vars.Style ) ]
		
		setPedWalkingStyle ( vars.target, style or 0 )
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doSet", "any" },
			{ "Style", "_wstyle" }
		},
		outputs = {
			{ "Style", "_wstyle" }
		}
	}
}

--[[
	Ped:JetPack
]]
NodeRef "Ped:JetPack" {
	doGive = function ( self )
		givePedJetPack ( self.vars.target )
	end,
	doRemove = function ( self )
		removePedJetPack ( self.vars.target )
	end,
	
	events = {
		target = "ped",
		inputs = {
			{ "doGive", "any" },
			{ "doRemove", "any" }
		}
	}
}