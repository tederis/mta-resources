--Seat
local seatModels = {
	[ 1746 ] = { 
		offset = { -0.6, 0, 0.6 },
		rotation = 90
	},
	[ 1369 ] = { 
		offset = { 0, -0.4, 0.6 },
		rotation = 180
	},
	[ 1742 ] = { 
		offset = { 0.4, 0.1, 0.6 },
		rotation = -90
	},
	[ 3174 ] = { 
		offset = { 0, -0.5, 0.7 },
		rotation = 180
	},
	[ 10271 ] = {
		offset = { 0, -0.5, 0.6 },
		rotation = 180
	},
	[ 9213 ] = {
		offset = { 0, 0, 1.2 },
		rotation = 180
	},
	[ 1777 ] = {
		offset = { -0.1, 0, 0.8 },
		rotation = -90
	},
	[ 10273 ] = {
		offset = { -0.4, 0, 0.64 },
		rotation = 90
	},
	[ 1663 ] = {
		offset = { 0, -0.45, 0.6 },
		rotation = 180
	},
	[ 1671 ] = {
		offset = { 0, -0.45, 0.6 },
		rotation = 180
	},
	[ 1562 ] = {
		offset = { 0, -0.53, 0.4 },
		rotation = 180
	}
}

local usableSeat = {
	name = "seat",
	actions = {
		"Сесть/Встать"
	},
	onUsed = function ( player, element, actionIndex, state )
		if not state then
			return
		end
	
		local data = seatModels [ getElementModel ( element ) ]
		if data then
			if isElementAttached ( player ) then
				detachElements ( player )
				toggleControl ( player, "fire", true )
				setPedAnimation ( player, "ped", "SEAT_up", 1, false, false, true, true )
			else
				attachElements ( player, element, data.offset [ 1 ], data.offset [ 2 ], data.offset [ 3 ] )
				toggleControl ( player, "fire", false )
				setPedAnimation ( player, "ped", "SEAT_down", 1, false, false, true, true )
			end
			
			--Выравниваем игрока по объекту
			local _, _, rotZ = getElementRotation ( element )
			setPedRotation ( player, rotZ + data.rotation )
		end
	end
}

--Vehicle
local vehicleIDS = { 602, 545, 496, 517, 401, 410, 518, 600, 527, 436, 589, 580, 419, 439, 533, 549, 526, 491, 474, 445, 467, 604, 426, 507, 547, 585,
405, 587, 409, 466, 550, 492, 566, 546, 540, 551, 421, 516, 529, 592, 553, 577, 488, 511, 497, 548, 563, 512, 476, 593, 447, 425, 519, 520, 460,
417, 469, 487, 513, 581, 510, 509, 522, 481, 461, 462, 448, 521, 468, 463, 586, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 485, 552, 431, 
438, 437, 574, 420, 525, 408, 416, 596, 433, 597, 427, 599, 490, 432, 528, 601, 407, 428, 544, 523, 470, 598, 499, 588, 609, 403, 498, 514, 524, 
423, 532, 414, 578, 443, 486, 515, 406, 531, 573, 456, 455, 459, 543, 422, 583, 482, 478, 605, 554, 530, 418, 572, 582, 413, 440, 536, 575, 534, 
567, 535, 576, 412, 402, 542, 603, 475, 449, 537, 538, 441, 464, 501, 465, 564, 568, 557, 424, 471, 504, 495, 457, 539, 483, 508, 571, 500, 
444, 556, 429, 411, 541, 559, 415, 561, 480, 560, 562, 506, 565, 451, 434, 558, 494, 555, 502, 477, 503, 579, 400, 404, 489, 505, 479, 442, 458, 
606, 607, 610, 590, 569, 611, 584, 608, 435, 450, 591, 594 }

local vehicleActions = {
	{ "Открыть" }, { "Закрыть" }
}
local usableVehicleLock = {
	name = "vehlock",
	actions = {
		"Открыть/Закрыть"
	},
	onUsed = function ( player, element, actionIndex, state )
		if not state then
			return
		end
	
		if isVehicleLocked ( element ) then
			setVehicleLocked ( element, false )
			playSoundAttachedToElement ( "unlock.ogg", element )
		else
			setVehicleLocked ( element, true )
			playSoundAttachedToElement ( "lock.ogg", element )
					
			for door = 0, 5 do
				setVehicleDoorState ( element, door, 0 )
			end
		end
	end,
	--[[getActions = function ( element )
		return isVehicleLocked ( element ) and vehicleActions [ 1 ] or vehicleActions [ 2 ]
	end,]]
	
	offset = function ( element )
		
	end
}

--Button
local usableButton = {
	name = "button",
	actions = {
		"Нажать"
	},
	getActions = function ( element )
		local itemsStr = getElementData ( element, "itms" )
		
		if not itemsStr then
			return
		end
		
		return split ( itemsStr, 44 )
	end,
	onUsed = function ( player, element, actionIndex, state )
		triggerEvent ( "onButton", element, player, state, actionIndex )
	end
}

g_usableEntity = {
	name = "entity",
	actions = {
		"Нажать"
	},
	offset = function ( element )
		local offsetX = getElementData ( element, "offsetX", false )
		if offsetX then
			local offsetY = getElementData ( element, "offsetY", false )
			local offsetZ = getElementData ( element, "offsetZ", false )
			
			return offsetX, offsetY, offsetZ
		end
	end,
	getActions = function ( element )
		local itemsStr = getElementData ( element, "itms" )
		if not itemsStr then return end;
		
		return split ( itemsStr, 44 )
	end,
	onUsed = function ( player, element, actionIndex, state )
		triggerEvent ( "onEntityAction", element, player, state, actionIndex )
	end
}

--Vending
local vendActions = { 
	{ "Выпивка" }, { "Закуска" } 
}
local vendModels = {
	[ 1209 ] = {
		actions = vendActions [ 1 ],
		block = "VEND_Drink2_P"
	},
	[ 1302 ] = {
		actions = vendActions [ 2 ],
		block = "vend_eat1_P"
	},
	[ 10009 ] = {
		actions = vendActions [ 1 ],
		block = "VEND_Drink2_P"
	},
	[ 10013 ] = {
		actions = vendActions [ 1 ],
		block = "VEND_Drink2_P"
	}
}

local usableVending = {
	name = "vending",
	actions = {
		"Выпить"
	},
	onUsed = function ( player, element, actionIndex, state )
		if not state then
			return
		end
		
		local data = vendModels [ getElementModel ( element ) ]
		if data then
			setPedAnimation ( player, "VENDING", "VEND_Use", 1, false, false, true, true )
			setTimer ( setPedAnimation, 2700, 1, player, "VENDING", data.block, 1, false, false, true, true )
		end
	end,
	getActions = function ( element )
		local data = vendModels [ getElementModel ( element ) ]
		if data then
			return data.actions
		end
	end
}

--Stalker peds
local stalkerPedIDS = { 299 }

local usableStalkerPed = {
	name = "stalkerPed",
	actions = {
		"Говорить"
	},
	onUsed = function ( player, element, actionIndex, state )
		if not state then
			return
		end
	end,
	onActionHit = function ( player, element )
		outputChatBox ( "hit!" )
	end
}

--Music billboard
local usableMusicBillboard = {
	name = "musicBillboard",
	actions = {
		"Выключить",
		
		"Радио Рекорд",
		"Радио Шансон",
		"Ретро FM",
		"Мегаполис FM",
		"Realex FM",
		"Радио Дача",
		"Эхо Москвы",
		"Добрые песни",
		"DFM",
		"Наше радио",
		"Максимум",
		"Радио 7",
		"Хит FM",
		"Милицейская волна",
		"ЮФМ",
		"Гоп FM",
		"RussianTranceRadio",
		"Disco House",
		"A1"
	},
	onUsed = function ( player, element, actionIndex, state )
		if state ~= true then
			return
		end
	
		exports.billradio:setBillboardStream ( element, actionIndex - 1 )
	end,
	onActionHit = function ( player, element )
		
	end,
	offset = { 0, 0, 2 }
}

local usableChest = {
	name = "chest",
	actions = {
		"Осмотреть",
	},
	onUsed = function ( player, element, actionIndex, state )
		if state ~= true then
			return
		end
	
		exports.inventory_new:showPlayerElementItems ( player, element )
	end,
	onActionHit = function ( player, element )
		
	end,
	offset = { 0, 0, 0 }
}

function setupUsable ( )
	--Seat
	for model, _ in pairs ( seatModels ) do
		makeUsable ( model, usableSeat )
	end
	
	--Vehicle
	for _, model in ipairs ( vehicleIDS ) do
		makeUsable ( model, usableVehicleLock )
	end
	
	--Button
	--makeUsable ( 2886, usableButton )
	
	--Vending
	for model, _ in pairs ( vendModels ) do
		--makeUsable ( model, usableVending )
	end
	
	--Stalker ped
	for _, model in ipairs ( stalkerPedIDS ) do
		makeUsable ( model, usableStalkerPed )
	end
	
	--Music billboard
	makeUsable ( 3616, usableMusicBillboard )
	
	makeUsable ( 1750, usableChest )
end