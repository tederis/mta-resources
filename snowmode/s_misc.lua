local rinks = {
 { 2212.56982, -2523.30405, 20.93838, 53, 32.5, 5 },
 { 1788.78381, -2375.38257, 10, 31.5, 19.8, 5 }
}

local rinksRoot = createElement ( "rinks-root")
addEventHandler ( "onResourceStart", resourceRoot,
function ( )
 for _, rink in ipairs ( rinks ) do
  local rinkColShape = createColCuboid ( rink [ 1 ], rink [ 2 ], rink [ 3 ], rink [ 4 ], rink [ 5 ], rink [ 6 ] )
  
  setElementParent ( rinkColShape, rinksRoot )
 end
end )

addEventHandler ( "onColShapeHit", rinksRoot,
function ( player, matchingDimension )
 if matchingDimension then
  setPedAnimation ( player, "SKATE", "skate_run", 1 )
 end
end )

addEventHandler ( "onColShapeLeave", rinksRoot,
function ( player, matchingDimension )
 if matchingDimension then
  setPedAnimation ( player, "SKATE", "skate_run", true, true )
  setPedAnimation ( player, false )
 end
end )