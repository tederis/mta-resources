TCT_CORE_VER = "4.0r"

ClientCore = { 
	isServerReady = false
}

function ClientCore.sendReadyMsg()
	triggerServerEvent ( "onTCTClientReady", resourceRoot )
end

function ClientCore.init ( )
	ClientCore.sendReadyMsg()

	setTimer( ClientCore.sendReadyMsg, 250, 3 )
end
addEventHandler ( "onClientResourceStart", resourceRoot, ClientCore.init, false )