sw, sh = guiGetScreenSize ( )

local shader = dxCreateShader ( "shaders/shader.fx" )
local texture = dxCreateTexture ( "textures/pfx_flame_01.dds" )
dxSetShaderValue ( shader, "Tex0", texture )

local flame_burst_line_up = {
	maxParticles = 32,
	sprite = {
		texture = shader
	},
	killOld = { --удаление частиц через определенное время
		ageLimit = 1000
	},
	source = {
		rate = 32, --скорость создания частиц ( чем больше значение, тем быстрее они появляются )
		domain = {
			line = {
				-0.050, 0.050, -0.300,
				0.050, 0.050, -0.750
			}
		},
		velocity = {
			--должно быть Box
			line = {
				0, 0, 6,
				0, 0, 9
			}
		},
		rotation = {
			line = {
				-3000, -3000, -3000,
				3600, 3600, 3600
			}
		},
		size = {
			line = {
				0.030, 0.030, 0,
				0.037, 0.037, 0
			}
		},
		color = {
			line = {
				255, 255, 255, 255,
				68, 68, 68, 255
			}
		},
	},
	--[[targetVelocity = {
		velocity = { 0, 0, 0 },
		scale = 2 --задает силу функции. при значении, меньшим единицы данный параметр отрицательно воздействует на функцию, при большим единицы - положительно
	},]]
	targetColor = { 
		color = { 33, 38, 70, 0 },
		scale = 7
	},
	targetSize = {
		size = { 2, 2, 2 },
		scale = { 5, 5, 5 }
	},
	targetRotate = {
		rotation = { 0, 0, 0 },
		scale = 0.050
	}
}

addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		--local ps = ParticleSystem.create ( flame_burst_line_up, -874.63068, 1924.89758, 44.84520 )
		--ParticleSystem.create ( star_glow_04, -851.40631, 1904.64258, 45.52583 )
		--ParticleSystem.create ( electra2_flash, -851.40631, 1904.64258, 45.52583 )
	end
, false )

--local noiseShader = dxCreateShader ( "shaders/noise.fx" )
--local screenSource = dxCreateScreenSource ( sw, sh )
--dxSetShaderValue ( noiseShader, "Tex0", screenSource )


addEventHandler ( "onClientRender", root,
	function ( )
		--dxUpdateScreenSource ( screenSource )
		
		--dxDrawImage ( 0, 0, sw, sh, noiseShader )
	end
)