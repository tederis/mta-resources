--[[
	Postprocess & XRAY & 30.06.2012

	Эффекты постпроцессинга:
		-Add color(оттенок изображения)
		-Base color
		-Gray color(насыщенность)
		-Duality(раздвоение изображения)
		-Noise(шум)
		-Blur(размытие изображения)
		-ColorMapper
		
	Постэффекты можно анимировать посредством ключей
]]

sw, sh = guiGetScreenSize ( )

Postprocess = { 
	shader = dxCreateShader ( "shaders/noise.fx" ),
	screenSource = dxCreateScreenSource ( sw, sh )
}
Postprocess.__index = Postprocess
dxSetShaderValue ( Postprocess.shader, "Tex0", Postprocess.screenSource )

function Postprocess.create ( effector )
	if Postprocess.effector then
		removeEventHandler ( "onClientRender", root, Postprocess.draw )
	end
	
	--Инициализируем эффектор
	Postprocess.initEffector ( effector )
	
	--Разрешаем приступить к работе
	Postprocess.effector = effector
	addEventHandler ( "onClientRender", root, Postprocess.draw )
end

function Postprocess.initEffector ( effector )
	local now = getTickCount ( )
	
	for _, set in pairs ( effector ) do
		set.progress = 0
		set.startTime = now
		set.point = 1
	end
	
	if effector.noise then
		noise.create ( )
	end
end

function Postprocess.draw ( )
	local now = getTickCount ( )

	for name, set in pairs ( Postprocess.effector ) do
		local progress = 1
		
		if set.point > 1 then
			local elapsedTime = now - set.startTime
			local duration = set [ set.point ] [ 1 ] - set [ set.point - 1 ] [ 1 ]
			progress = elapsedTime / duration
		end
		
		local point = set [ set.point ]
		local prevPoint = set.point > 1 and set [ set.point - 1 ] or point
		
		if name == "grayColor" then
			local grayIntensity = math.slerp ( prevPoint [ 5 ], point [ 5 ], progress )
			
			dxSetShaderValue ( Postprocess.shader, "grayColor", 0.3, 0.3, 0.3, (1-grayIntensity)/1 )
		elseif name == "noise" then
			local noiseIntensity = math.slerp ( prevPoint [ 3 ], point [ 3 ], progress )
			
			noise.setIntensity ( (1-noiseIntensity)/1 )
		end
		
		dxUpdateScreenSource ( Postprocess.screenSource )
		dxDrawImage ( 0, 0, sw, sh, Postprocess.shader, 0, 0, 0, tocolor ( 255 * 0.15, 255 * 0.25, 255 * 0.25, 255 ) )
		
		if progress >= 1 then
			set.point = set.point + 1
			if set.point > #set then
				set.point = 1
			end
			
			--set.point = math.min ( set.point + 1, #set )
			--set.point = set.point + 1
			set.startTime = now
			
			--if set.point > #set then
				--removeEventHandler ( "onClientRender", root, Postprocess.draw )
			--end
		end
	end
end

---------------------------------
--Noise
---------------------------------
noise = { 
	lastUpdate = getTickCount ( ),
	frame = 1,
	rate = 24,
	sequence = {
		"textures/noise/ui_noise_00.dds",
		"textures/noise/ui_noise_01.dds",
		"textures/noise/ui_noise_02.dds",
		"textures/noise/ui_noise_03.dds",
		"textures/noise/ui_noise_04.dds",
		"textures/noise/ui_noise_03.dds",
		"textures/noise/ui_noise_01.dds",
		"textures/noise/ui_noise_02.dds",
		"textures/noise/ui_noise_00.dds",
		"textures/noise/ui_noise_03.dds",
		"textures/noise/ui_noise_04.dds"
	}
}

function noise.create ( )
	if noise.textures then
		return
	end
	
	noise.frame = 1
	noise.textures = { }
	
	for i, filepath in ipairs ( noise.sequence ) do
		noise.textures [ i ] = dxCreateTexture ( filepath )
	end
	
	addEventHandler ( "onClientRender", root, noise.update )
end

function noise.abort ( )
	if not noise.textures then
		return
	end

	for _, texture in ipairs ( noise.textures ) do
		destroyElement ( texture )
	end
	noise.textures = nil
	
	removeEventHandler ( "onClientRender", root, noise.update )
end

function noise.setIntensity ( intensity )
	dxSetShaderValue ( Postprocess.shader, "NoiseIntensity", intensity )
end

function noise.update ( )
	local now = getTickCount ( )
	
	if now - noise.lastUpdate > noise.rate then
		dxSetShaderValue ( Postprocess.shader, "NoiseTex", noise.textures [ noise.frame ] )
		
		noise.frame = noise.frame + 1
		if noise.frame > #noise.sequence then
			noise.frame = 1
		end
		noise.lastUpdate = now
	end
end




local electra = { 
	--r, g, b
	--addColor = {
		--TODO
	--},
	--r, g, b
	baseColor = {
		{ 0, 0.15, 0.25, 0.25 }
	},
	--r, g, b, intensity
	grayColor = {
		{ 0, 0, 0, 0, 0.50 },
		{ 3000, 0, 0, 0, 0.85 },
		{ 6000, 0, 0, 0, 0.50 }
	},
	--h, v
	duality = {
		{ 0, 0, 0 },
		{ 2000, 0, 0 }
	},
	--intensity, grain, fps
	noise = {
		{ 0, 1, 0.20, 30 },
		{ 3000, 1, 0.50, 8 },
		{ 6000, 1, 0.20, 15 }
	},
	--r, g, b, intensity
	blur = {
		{ 0, 0, 0, 0, 0.50 },
		{ 3000, 0, 0, 0, 0.85 },
		{ 6000, 0, 0, 0, 0.50 }
	},
	--influence
	--colorMapper = {
		--TODO
	--}
}

--Postprocess.create ( electra )