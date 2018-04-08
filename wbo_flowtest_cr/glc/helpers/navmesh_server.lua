Navmesh = { }

function Navmesh.create ( )

end

function setPedNavmesh ( ped, path )
	setElementData ( ped, "navmesh", path )
	setElementSyncer ( ped, true )
end