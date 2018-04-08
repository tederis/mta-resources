--------------------------
-- Weapon группа        --
-- Работа с оружием     --
--------------------------
--[[
	Weapon:Weapon
]]
NodeRef "Weapon:Weapon" {
	doToggle = function ( self )
		local vars = self.vars
		setWeaponState ( vars.target, getWeaponState ( vars.target ) == "ready" and "firing" or "ready" )
	end,
	doSetFire = function ( self )
		local vars = self.vars
		setWeaponState ( vars.target, "firing" )
	end,
	doSetReady = function ( self )
		local vars = self.vars
		setWeaponState ( vars.target, "ready" )
	end,
	Target = function ( self, value )
		local vars = self.vars
		setWeaponTarget ( vars.target, value )
	end,

	events = {
		target = "s_weapon",
		inputs = {
			{ "doToggle", "any" },
			{ "doSetFire", "any" },
			{ "doSetReady", "any" },
			{ "Target", "entity" }
		}
	}
}