local collection = { }

addEvent( "onClientAttachElementToBone", true )
addEventHandler( "onClientAttachElementToBone", root,
function ( ped, bone, x, y, z, rx, ry, rz )
	if isElement ( ped ) then
		collection [ source ] = { ped, bone, x, y, z, rx, ry, rz }
	else
		collection [ source ] = nil
	end
end )

bone_0, bone_t, bone_f = { }, { }, { }
bone_0 [ 1 ] , bone_t [ 1 ] , bone_f [ 1 ]  = 5, nil, 8 --Голова
bone_0 [ 2 ] , bone_t [ 2 ] , bone_f [ 2 ]  = 4, 5, 8 --Шея
bone_0 [ 3 ] , bone_t [ 3 ] , bone_f [ 3 ]  = 3, 4, 5 --Спина (не работает)
bone_0 [ 4 ] , bone_t [ 4 ] , bone_f [ 4 ]  = 1, 2, 3 --Таз
bone_0 [ 5 ] , bone_t [ 5 ] , bone_f [ 5 ]  = 4, 32, 5 --Левая ключица
bone_0 [ 6 ] , bone_t [ 6 ] , bone_f [ 6 ]  = 4, 22, 5 --Правая ключица
bone_0 [ 7 ] , bone_t [ 7 ] , bone_f [ 7 ]  = 32, 33, 34 --Левое плечо
bone_0 [ 8 ] , bone_t [ 8 ] , bone_f [ 8 ]  = 22, 23, 24 --Правое плечо
bone_0 [ 9 ] , bone_t [ 9 ] , bone_f [ 9 ]  = 33, 34, 32 --Левый локоть
bone_0 [ 10 ] , bone_t [ 10 ] , bone_f [ 10 ]  = 23, 24, 22 --Правый локоть
bone_0 [ 11 ] , bone_t [ 11 ] , bone_f [ 11 ]  = 34, 35, 36 --Левая рука
bone_0 [ 12 ] , bone_t [ 12 ] , bone_f [ 12 ]  = 24, 25, 26 --Правая рука
bone_0 [ 13 ] , bone_t [ 13 ] , bone_f [ 13 ]  = 41, 42, 43 --Левое бедро
bone_0 [ 14 ] , bone_t [ 14 ] , bone_f [ 14 ]  = 51, 52, 53 --Правое бедро
bone_0 [ 15 ] , bone_t [ 15 ] , bone_f [ 15 ]  = 42, 43, 44 --Левое колено
bone_0 [ 16 ] , bone_t [ 16 ] , bone_f [ 16 ]  = 52, 53, 54 --Правое колено
bone_0 [ 17 ] , bone_t [ 17 ] , bone_f [ 17 ]  = 43, 42, 44 --Левая лодыжка
bone_0 [ 18 ] , bone_t [ 18 ] , bone_f [ 18 ]  = 53, 52, 54 --Правая лодыжка
bone_0 [ 19 ] , bone_t [ 19 ] , bone_f [ 19 ]  = 44, 43, 42 --Левая нога
bone_0 [ 20 ] , bone_t [ 20 ] , bone_f [ 20 ]  = 54, 53, 52 --Правая нога

addEventHandler ( "onClientPreRender", root,
	function ( )
		for element, property in pairs ( collection ) do
			if isElement ( property [ 1 ] ) then
				if isElementStreamedIn ( property [ 1 ] ) then
					local x, y, z, tx, ty, tz, fx, fy, fz
					x, y, z = getPedBonePosition ( property [ 1 ], bone_0 [ property [ 2 ] ] )
					if property [ 2 ] == 1 then
						local x6, y6, z6 = getPedBonePosition ( property [ 1 ], 6 )
						local x7, y7, z7 = getPedBonePosition ( property [ 1 ], 7 )
						tx, ty, tz = ( x6 + x7 ) * 0.5, ( y6 + y7 ) * 0.5, ( z6 + z7 ) * 0.5
					else
						tx, ty, tz = getPedBonePosition ( property [ 1 ], bone_t [ property [ 2 ] ] )
					end
					local fx, fy, fz = getPedBonePosition ( property [ 1 ], bone_f [ property [ 2 ] ] )
					local xx, xy, xz, yx, yy, yz, zx, zy, zz = getMatrixFromPoints ( x, y, z, tx, ty, tz, fx, fy, fz )
					local objx = x + property [ 3 ] * xx + property [ 4 ] * yx + property [ 5 ] * zx
					local objy = y + property [ 3 ] * xy + property [ 4 ] * yy + property [ 5 ] * zy
					local objz = z + property [ 3 ] * xz + property [ 4 ] * yz + property [ 5 ] * zz
					local rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz = getMatrixFromEulerAngles ( property [ 6 ], property [ 7 ], property [ 8 ] )
			
					local txx = rxx * xx + rxy * yx + rxz * zx
					local txy = rxx * xy + rxy * yy + rxz * zy
					local txz = rxx * xz + rxy * yz + rxz * zz
					local tyx = ryx * xx + ryy * yx + ryz * zx
					local tyy = ryx * xy + ryy * yy + ryz * zy
					local tyz = ryx * xz + ryy * yz + ryz * zz
					local tzx = rzx * xx + rzy * yx + rzz * zx
					local tzy = rzx * xy + rzy * yy + rzz * zy
					local tzz = rzx * xz + rzy * yz + rzz * zz
					local offrx, offry, offrz = getEulerAnglesFromMatrix ( txx, txy, txz, tyx, tyy, tyz, tzx, tzy, tzz )
			
					setElementPosition ( element, objx, objy, objz )
					setElementRotation ( element, offrx, offry, offrz, "ZXY" )
				else
					setElementPosition ( element, getElementPosition ( property [ 1 ] ) )
				end
			else
				collection [ element ] = nil
			end
		end
	end 
)

function isElementAttachedToBone ( element )
	if isElement ( element ) and getElementType ( element ) == "object" then
		if collection [ element ] then
			return true
		end
	end
	
	return false
end

function attachElementToBone ( element, ped, bone, x, y, z, rx, ry, rz )
	if ( isElement ( element ) and getElementType ( element ) == "object" ) and isElement ( ped ) then
	
		collection [ element ] = { ped, bone, x, y, z, rx, ry, rz }
	end
	
	return false
end

function detachElementFromBone ( element )
	if isElement ( element ) and getElementType ( element ) == "object" then  
		if collection [ element ] then
			collection [ element ] = nil
			
			return true
		end
	end
	
	return false
end

addEventHandler ( "onClientElementDestroy", root,
	function ( )
		if collection [ source ] then
			collection [ source ] = nil
		end
	end
)

function getPositionByBoneOffset ( ped, bone, offx, offy, offz )
	local x, y, z, tx, ty, tz, fx, fy, fz
	x, y, z = getPedBonePosition ( ped, bone_0 [ bone ] )
	if bone == 1 then
		local x6, y6, z6 = getPedBonePosition ( ped, 6 )
		local x7, y7, z7 = getPedBonePosition ( ped, 7 )
		tx, ty, tz = ( x6 + x7 ) * 0.5, ( y6 + y7 ) * 0.5, ( z6 + z7 ) * 0.5
	else
		tx, ty, tz = getPedBonePosition ( ped, bone_t [ bone ] )
	end
	
	fx, fy, fz = getPedBonePosition ( ped, bone_f [ bone ] )
	local xx, xy, xz, yx, yy, yz, zx, zy, zz = getMatrixFromPoints ( x, y, z, tx, ty, tz, fx, fy, fz )
	local objx = x + offx * xx + offy * yx + offz * zx
	local objy = y + offx * xy + offy * yy + offz * zy
	local objz = z + offx * xz + offy * yz + offz * zz
	--[[local rxx, rxy, rxz, ryx, ryy, ryz, rzx, rzy, rzz = getMatrixFromEulerAngles ( 0, 0, 0 )
			
	local txx = rxx * xx + rxy * yx + rxz * zx
	local txy = rxx * xy + rxy * yy + rxz * zy
	local txz = rxx * xz + rxy * yz + rxz * zz
	local tyx = ryx * xx + ryy * yx + ryz * zx
	local tyy = ryx * xy + ryy * yy + ryz * zy
	local tyz = ryx * xz + ryy * yz + ryz * zz
	local tzx = rzx * xx + rzy * yx + rzz * zx
	local tzy = rzx * xy + rzy * yy + rzz * zy
	local tzz = rzx * xz + rzy * yz + rzz * zz
	local offrx, offry, offrz = getEulerAnglesFromMatrix ( txx, txy, txz, tyx, tyy, tyz, tzx, tzy, tzz )]]
	
	return objx, objy, objz
end

----------------------------------
--UTILS
----------------------------------
local BONE_HELPER_TOGGLE = false
local boneHelper = { 
	offsetX = 0, offsetY = 0, offsetZ = 0,
	offsetRX = 0, offsetRY = 0, offsetRZ = 0 }

addCommandHandler ( "bonehelper",
function ( command, model, bone )
	model, bone = tonumber ( model ), tonumber ( bone )
	if model and bone then
		if isElement ( boneHelper.element ) then
			destroyElement ( boneHelper.element )
		end
		boneHelper.element = createObject ( model, 0, 0, 0 )
		setElementCollisionsEnabled ( boneHelper.element, false )
		
		boneHelper.bone = bone
		attachElementToBone ( boneHelper.element, localPlayer, bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		BONE_HELPER_TOGGLE = true
	else
		outputChatBox ( "Bone helper: Вы не указали модель объекта" )
	end
end )

addEventHandler ( "onClientRender", root,
	function ( )
		if BONE_HELPER_TOGGLE ~= true or isElement ( boneHelper.element ) ~= true then
			return
		end
		
		if getKeyState ( "num_add" ) then
			boneHelper.offsetZ = boneHelper.offsetZ - 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_sub" ) then
			boneHelper.offsetZ = boneHelper.offsetZ + 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_8" ) then
			boneHelper.offsetY = boneHelper.offsetY + 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_2" ) then
			boneHelper.offsetY = boneHelper.offsetY - 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_6" ) then
			boneHelper.offsetX = boneHelper.offsetX - 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_4" ) then
			boneHelper.offsetX = boneHelper.offsetX + 0.05
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_7" ) then
			boneHelper.offsetRX = boneHelper.offsetRX - 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState( "num_9" ) then
			boneHelper.offsetRX = boneHelper.offsetRX + 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_mul" ) then
			boneHelper.offsetRY = boneHelper.offsetRY - 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_div" ) then
			boneHelper.offsetRY = boneHelper.offsetRY + 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_1" ) then
			boneHelper.offsetRZ = boneHelper.offsetRZ - 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		elseif getKeyState ( "num_3" ) then
			boneHelper.offsetRZ = boneHelper.offsetRZ + 1
			attachElementToBone ( boneHelper.element, localPlayer, boneHelper.bone, boneHelper.offsetX, boneHelper.offsetY, boneHelper.offsetZ, boneHelper.offsetRX, boneHelper.offsetRY, boneHelper.offsetRZ )
		end
	end
)

addEventHandler ( "onClientKey", root,
	function ( button, press )
		if BONE_HELPER_TOGGLE == true and button == "l" and press then
			local offsetStr = boneHelper.offsetX .. ", " .. boneHelper.offsetY .. ", " .. boneHelper.offsetZ .. ", " .. boneHelper.offsetRX .. ", " .. boneHelper.offsetRY .. ", " .. boneHelper.offsetRZ
			setClipboard ( offsetStr )
			outputChatBox ( "'" .. offsetStr .. "' скопировано в буфер обмена" )
		end
	end
)