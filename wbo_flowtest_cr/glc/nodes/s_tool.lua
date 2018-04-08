------------------------
-- Tools группа       --
-- Утилиты            --
------------------------

--[[
	Tool:KeyToChannel
]]
local _outputs = { }
for i = 1, 10 do
	_outputs [ i ] = { "onEvent" .. i, "any" }
end

NodeRef "Tool:KeyToChannel" { 
	doEvent = function ( self, value )
		value = tonumber ( value )
		self:triggerOutput ( value )
	end,
	
	events = {
		inputs = {
			{ "doEvent", "any", "if(@input==1)then [@onEvent1] elseif(@input==2) then [@onEvent2] end;" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:ChannelToKey
]]
local _inputs = { }
for i = 1, 10 do
	_inputs [ i ] = { "doWork" .. i, "any" }
end

NodeRef "Tool:ChannelToKey" { 
	_input = function ( self, value, port )
		self:triggerOutput ( 1, port )
	end,
	
	events = {
		inputs = _inputs,
		outputs = {
			{ "onKey", "number" }
		}
	}
}

--[[
	Tool:Hub
]]
local _inputs = { }
for i = 1, 6 do
	_inputs [ i ] = { "doIn" .. i, "any" }
end

local _outputs = { }
for i = 1, 6 do
	_outputs [ i ] = { "onOut" .. i, "any" }
end

NodeRef "Tool:Hub" { 
	_input = function ( self, value )
		for i = 1, 6 do
			self:triggerOutput ( i, value )
		end
	end,
	
	events = {
		inputs = _inputs,
		outputs = _outputs
	}
}

--[[
	Tool:RandomPort
]]
local _outputs = { }
for i = 1, 6 do
	_outputs [ i ] = { "onOut" .. i, "any" }
end

NodeRef "Tool:RandomPort" { 
	doIn = function ( self, value )
		local vars = self.vars
		
		local min = tonumber ( vars.Min )
		local max = tonumber ( vars.Max )
		local rand = math.random ( math.max ( min, 1 ), max == 0 and 6 or max )
		
		self:triggerOutput ( rand, value )
	end,
	
	events = {
		inputs = {
			{ "doIn", "any" },
			{ "Min", "number" },
			{ "Max", "number" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:Script
]]
NodeRef "Tool:Script" { 
	events = {
		outputs = {
			{ "onStart", "number" },
			{ "OwnerName", "string" }
		}
	}
}

--[[
	Tool:Switch
]]
NodeRef "Tool:Switch" {
	doSwitch = function ( self, value )
		if self.custom.state then
			self.custom.state = false
			self:triggerOutput ( 2, value )
		else
			self.custom.state = true
			self:triggerOutput ( 1, value )
		end
	end,
	
	events = {
		inputs = { 
			{ "doSwitch", "any" }
		},
		outputs = {
			{ "onOn", "any" },
			{ "onOff", "any" }
		}
	}
}

--[[
	Tool:Event
]]
local eventNodes = { 
	--event1 = {node1, node2}
}

NodeRef "Tool:Event" {
	_target = function ( self, element )
		local vars = self.vars
		local eventName = tostring ( vars.EventName )
		
		local nodes = eventNodes [ eventName ]
		if nodes == nil then
			nodes = { }; eventNodes [ eventName ] = nodes;
		end
		
		for i = 1, #nodes do
			if nodes [ i ] == self then
				return
			end
 		end
		
		table.insert ( nodes, self )
	end,
	[ "~target" ] = function ( self, element )
		local vars = self.vars
		local eventName = tostring ( vars.EventName )
		
		local nodes = eventNodes [ eventName ]
		if nodes then
			for i = 1, #nodes do
				if nodes [ i ] == self then
					table.remove ( nodes, i )
				end
			end
		end
	end,
	doTrigger = function ( self, value )
		local vars = self.vars
		local eventName = tostring ( vars.EventName )
		
		local nodes = eventNodes [ eventName ]
		if nodes then
			for i = 1, #nodes do
				nodes [ i ]:triggerOutput ( 1, value )
			end
		end
	end,
	
	events = {
		target = "element",
		inputs = { 
			{ "doTrigger", "any" },
			{ "EventName", "string" }
		},
		outputs = {
			{ "onEvent", "any" },
		}
	}
}

--[[
	Tool:Timer
]]
local activeTimersNum = 0
local timerData = { }
local onToolTimer = function ( element )
	local node = timerData [ element ]
	if node then
		local remaining, executesRemaining, totalExecutes = getTimerDetails ( node [ 2 ] )
		if executesRemaining == 1 then
			timerData [ element ] = nil
			activeTimersNum = activeTimersNum - 1
			outputDebugString ( "Node timer destroyed" )
		end

		if node [ 1 ] and node [ 1 ].tag == "Tool:Timer" then
			node [ 1 ]:triggerOutput ( 2, element )
			node [ 1 ]:triggerOutput ( 1, element )
		end
	end
end

NodeRef "Tool:Timer" {
	[ "~target" ] = function ( self, element )
		self.abstr.doKill ( self )
	end,
	doSet = function ( self )
		local vars = self.vars
		-- Уже запущен таймер для этого нода? Выходим.
		if timerData [ vars.target ] then return end;
		
		if activeTimersNum > 500 then
			outputDebugString ( "Запрещено свыше 500 активных таймеров", 2 )
			return
		end
	
		local interval = tonumber ( vars.Interval )
		local times = tonumber ( vars.Times )
		if interval and times then
			timerData [ vars.target ] = {
				self,
				setTimer ( onToolTimer, math.max ( 100, interval ), times, vars.target )
			}
			activeTimersNum = activeTimersNum + 1
		end
	end,
	doKill = function ( self )
		local vars = self.vars
		local timer = timerData [ vars.target ]
		if timer then
			if isTimer ( timer [ 2 ] ) then
				killTimer ( timer [ 2 ] )
			end
			activeTimersNum = activeTimersNum - 1
		end
		timerData [ vars.target ] = nil
	end,
	
	events = {
		inline = "var0=nil;var1=function() [onEvent]; end;",
		target = "element",
		inputs = { 
			{ "doSet", "any", "if(isTimer() == false) then var0=setTimer(var1, Interval, Times) end;" },
			{ "doKill", "any", "if(isTimer(var0))then killTimer(var0) end;" },
			{ "Interval", "number" },
			{ "Times", "number" }
		},
		outputs = {
			{ "onEvent", "element" },
			{ "Element", "element" }
		}
	}
}

--[[
	Tool:IsElement
]]
NodeRef "Tool:IsElement" {
	isElement = function ( self )
		local vars = self.vars
		self:triggerOutput ( isElement ( vars.target ) and 1 or 2 )
	end,

	events = {
		target = "element",
		inputs = { 
			{ "isElement", "any", CLEAR_TARGET }
		},
		outputs = {
			{ "onTrue", "any" },
			{ "onFalse", "any" }
		}
	}
}

--[[
	Tool:MultiData
]]
local _outputs = { }
for i = 1, 10 do
	_outputs [ i ] = { "onData" .. i, "any" }
end

NodeRef "Tool:MultiData" { 
	doSeparate = function ( self, value )
		if type ( value ) == "table" and #value < 12 and value [ 1 ] == 0x12 then
			for i = 2, #value do
				self:triggerOutput ( i - 1, value [ i ] )
			end
		end
	end,
	
	events = {
		inputs = {
			{ "doSeparate", "stream" }
		},
		outputs = _outputs
	}
}

--[[
	Tool:Gate
]]
NodeRef "Tool:Gate" {
	doInput = function ( self, value )
		local vars = self.vars

		if vars.State == true then
			self:triggerOutput ( 1, value )
		end
	end,
	doOn = function ( self )
		self.vars.State = true
	end,
	doOff = function ( self )
		self.vars.State = false
	end,
	
	events = {
		inline = "var0=false;",
		inputs = { 
			{ "doInput", "any", "if(var0==true)then out(onOutput) end;" },
			{ "doOn", "any", "var0=true;" },
			{ "doOff", "any", "var0=false;" },
			{ "State", "bool", "var0=__value" }
		},
		outputs = {
			{ "onOutput", "any" }
		}
	}
}

--[[
	Tool:Counter
]]
NodeRef "Tool:Counter" {
	doAdd = function ( self )
		--local vars = self.vars

		local count = self.custom.count
		if count then
			count = count + 1
		else
			count = 1
		end
		self.custom.count = count
		self:triggerOutput ( 2, count )
		self:triggerOutput ( 1, count )
	end,
	doReset = function ( self )
		self.custom.count = nil
		self:triggerOutput ( 2, 0 )
		self:triggerOutput ( 1, 0 )
	end,
	
	events = {
		inline = "var0=0;",
		inputs = { 
			{ "doAdd", "any", "$var0=$var0+1; [@onAdd=$var0] [@Count=$var0]" },
			{ "doReset", "any", "$var0=0; [@onAdd=$var0] [@Count=$var0];" }
		},
		outputs = {
			{ "onAdd", "number" },
			{ "Count", "number" }
		}
	}
}


--[[
	Tool:Counter
]]
NodeRef "Tool:Pack" {
	events = {
		inputs = { 
			{ "Arg1", "any" },
			{ "Arg2", "any" },
			{ "Arg3", "any" }
		},
		outputs = {
			{ "Packed", "table", "{Arg1, Arg2, Arg3}" },
		}
	}
}

--[[
	Tool:Counter
]]
NodeRef "Tool:Unpack" {
	events = {
		inputs = { 
			{ "Packed", "table", "arg0 __value[1]; arg1 __value[2]; arg2 __value[3]; out 1 arg0; out 2 arg1; out 3 arg2;" },
		},
		outputs = {
			{ "Arg1", "any", "Packed[1]" },
			{ "Arg2", "any", "Packed[2]" },
			{ "Arg3", "any", "Packed[3]" }
		}
	}
}