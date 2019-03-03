local player = require("logic_server/player")
local robot_player = player:new()

function robot_player:new()
	-- body
	local instance = {}

	setmetatable(instance,{__index= self})

	return instance
end
function robot_player:init(uid,s,ret_handler)
	-- body
	player.init(self,uid,s,ret_handler)
	self.is_robot = true
end
return robot_player