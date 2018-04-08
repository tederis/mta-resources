TCT_CORE_VER = "4.0r"

ClientCore = { 
	isServerReady = false
}

function ClientCore.init ( )
	triggerServerEvent ( "onTCTClientReady", resourceRoot )
end

addEventHandler ( "onClientResourceStart", resourceRoot, ClientCore.init, false )