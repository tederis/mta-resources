function validateAccount ( name, pass )
	pass = tostring ( pass )
	if utfLen ( pass ) > 0 then
		return getAccount ( tostring ( name ), pass ) ~= false
	end
	return false
end