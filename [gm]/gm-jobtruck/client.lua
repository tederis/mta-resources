local truckPoints = {
	{ -187.4041, -277.0196, 0.4219 },
	{ 58.0364, -256.7285, 0.5781 },
	{ 95.8675, -154.3627, 1.5751 },
	{ 809.7556, -598.0007, 15.1875 },
	{ 1403.833, 399.4294, 18.75 },
	{ 1338.289, 348.9004, 18.4062 },
	{ 1449.715, 2358.852, 9.8203 },
	{ 1037.475, 2131.344, 9.8203 },
	{ 987.9741, 2080.389, 9.8203 },
	{ 1288.671, 1195.232, 9.8656 },
	{ 2467.902, 1950.061, 9.2381 },
	{ 2792.744, 2578.336, 9.8203 },
	{ 2271.477, 2791.739, 9.8203 },
	{ 2596.519, 1738.582, 9.8281 },
	{ 2818.84, 912.5091, 9.75 },
	{ 2706.505, 827.3236, 9.2145 },
	{ 1627.723, 688.4043, 9.8281 },
	{ 1504.492, 981.141, 9.7187 },
	{ 1724.012, 1590.128, 9.2578 },
	{ 1727.833, 2338.017, 9.813 },
	{ 2413.683, -2113.674, 12.3881 },
	{ 2784.973, -2455.441, 12.625 },
	{ 2112.662, -2070.376, 12.5547 },
	{ 1763.641, -2070.371, 12.6195 },
	{ -1888.621, -1711.836, 20.7656 },
	{ -2117.227, -2380.507, 29.4688 },
	{ -1545.439, -2747.032, 47.5314 },
	{ -1407.375, 2645.957, 54.7031 },
	{ -2245.581, 2371.693, 3.9919 },
	{ -1360.633, 2068.094, 51.4589 },
	{ 274.2705, 1382.781, 9.6016 },
	{ 628.8638, 1714.891, 5.9922 },
	{ 635.0028, 1213.777, 10.7188 },
	{ -914.953, 2012.138, 59.9283 },
	{ 385.8214, 2595.55, 15.4843 },
	{ -1556.977, -441.3493, 5.0 },
	{ -2659.631, 1380.642, 6.1643 },
	{ -1650.928, 437.5679, 6.1797 },
	{ -1745.116, 37.8752, 2.5408 },
	{ 56.744, -268.404, 0.579 },
	{ 100.397, -155.05, 1.583 }
}

local targetMarker

addEventHandler ( "onClientMissionStart", resourceRoot,
	function ( )
		showTextLine ( "#FFFFFFСадитесь в #2121FFгрузовик" )
		
		createTargetMarker ( )
	end
)

addEventHandler ( "onClientVehicleEnter", root,
	function ( player, seat )
       
	end
)

function createTargetMarker ( )
	local randomIndex = math.random ( 1, #truckPoints )

	targetMarker = createMarker ( truckPoints [ randomIndex ] [ 1 ], truckPoints [ randomIndex ] [ 2 ], truckPoints [ randomIndex ] [ 3 ], 	"cylinder", 5 )
	addEventHandler ( "onClientMarkerHit", targetMarker, targetMarkerHit, false )
	local blip = createBlip ( truckPoints [ randomIndex ] [ 1 ], truckPoints [ randomIndex ] [ 2 ], truckPoints [ randomIndex ] [ 3 ],
		0, 2, 0, 0, 255 )
	setElementParent ( blip, targetMarker )
end

function targetMarkerHit ( element, matchingDimension )
	if not matchingDimension then
		return
	end
	
	triggerServerEvent ( "onPlayerDeliveredCargo", localPlayer )
end