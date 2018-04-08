Effect = { }

Effect [ "blood" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		local count = 1
		local brightness = 1
		
		fxAddBlood ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ, count, brightness )
	end
}

Effect [ "bulletImpact" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		local smokeSize = 1
		local sparkCount = 1
		local smokeIntensity = 1
		
		fxAddBulletImpact ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ, smokeSize, sparkCount, smokeIntensity )
	end
}

Effect [ "bulletSplash" ] = {
	render = function ( element )
		local pX, pY, pZ = getElementPosition ( element )
		
		fxAddBulletSplash ( pX, pY, pZ )
	end
}

Effect [ "debris" ] = {
	render = function ( element )
		local pX, pY, pZ = getElementPosition ( element )
		
		local colorR, colorG, colorB, colorA = 255, 0, 0, 255
		local scale = 0.1
		local count = 1
		
		fxAddDebris ( pX, pY, pZ, colorR, colorG, colorB, colorA, scale, count )
	end
}

Effect [ "footSplash" ] = {
	render = function ( element )
		local pX, pY, pZ = getElementPosition ( element )
		
		fxAddFootSplash ( pX, pY, pZ )
	end
}

Effect [ "glass" ] = {
	render = function ( element )
		local pX, pY, pZ = getElementPosition ( element )
		
		local colorR, colorG, colorB, colorA = 255, 0, 0, 255
		local scale = 0.05
		local count = 1
		
		fxAddGlass ( pX, pY, pZ, colorR, colorG, colorB, colorA, scale, count )
	end
}

Effect [ "gunshot" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		local includeSparks = true
		
		fxAddGunshot ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ, includeSparks )
	end
}

Effect [ "punchImpact" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		fxAddPunchImpact ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ )
	end
}

Effect [ "sparks" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		local force = 1
		local count = 1
		local acrossLineX, acrossLineY, acrossLineZ = 0, 0, 0
		local blur = false
		local spread = 1
		local life = 1
		
		fxAddSparks ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ, force, count, acrossLineX, acrossLineY, acrossLineZ, blur, spread, life )
	end
}

Effect [ "tankFire" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		fxAddTankFire ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ )
	end
}

Effect [ "tyreBurst" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		fxAddTyreBurst ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ )
	end
}

Effect [ "waterSplash" ] = {
	render = function ( element )
		local pX, pY, pZ = getElementPosition ( element )
		
		fxAddWaterSplash ( pX, pY, pZ )
	end
}

Effect [ "wood" ] = {
	render = function ( element )
		local vel = getElementData ( element, "vel" ) or 1
	
		local pX, pY, pZ = getElementPosition ( element )
		local dX, dY, dZ = getElementPositionByOffset ( element, 0, 0, vel )
		
		local count = 1
		local brightness = 1
		
		fxAddWood ( pX, pY, pZ, dX - pX, dY - pY, dZ - pZ, count, brightness )
	end
}