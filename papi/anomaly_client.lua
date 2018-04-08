local detectors = { 
	[ "geiger" ] = {
		distance = 15,
		time = getTickCount ( ),
		sound = { 
			"sounds/geiger_%s.ogg",
			1, 8
		}
	},
	[ "da-2" ] = {
		distance = 15,
		time = getTickCount ( ),
		sound = {
			"sounds/da-2_beep1.ogg",
			1, 1
		}
	}
}

local _anomalies = {

}
function addAnomalyDetector ( x, y, z )
	table.insert ( _anomalies, { x, y, z } )
end

local dist3d = getDistanceBetweenPoints3D

setTimer (
	function ( )
		local px, py, pz = getElementPosition ( localPlayer )
		local minDist = 15
		local minAnomaly

		for _, anomaly in ipairs ( _anomalies ) do
			local dist = dist3d ( px, py, pz, anomaly [ 1 ], anomaly [ 2 ], anomaly [ 3 ] )
			if dist < minDist then
				minDist = dist
				minAnomaly = anomaly
			end
		end
		
		setDetectorTarget ( "da-2", minAnomaly )
	end,
500, 0 )

function setDetectorTarget ( name, target )
	local detector = detectors [ name ]
	if not detector then
		return
	end
	
	detector.target = target
end

function detectorUpdatePulse ( )
	local px, py, pz = getElementPosition ( localPlayer )
	local now = getTickCount ( )
	
	for _, detector in pairs ( detectors ) do
		if detector.target then
			local x, y, z = detector.target [ 1 ], detector.target [ 2 ], detector.target [ 3 ]

			local delay = 1000 * ( getDistanceBetweenPoints3D ( x, y, z, px, py, pz-1 ) / detector.distance )
		
			if now - detector.time > delay then
				local soundPath = string.format ( detector.sound [ 1 ], 
					math.random ( detector.sound [ 2 ], detector.sound [ 3 ] ) )
			
				playSound ( soundPath )
			
				detector.time = getTickCount ( )
			end
		end
	end
	
end
setTimer ( detectorUpdatePulse, 50, 0 )