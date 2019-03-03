
local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local mysql_game = require("database/mysql_game")
local redis_game = require("database/redis_game")
local State = require("logic_server/State")
local Zone = require("logic_server/Zone")
local redis_center = require("database/redis_center")
local game_config = require("game_config")

local player = {}

function player:new(instant)
	
	if not instant then
		instant = {}
	end
	setmetatable(instant,{__index = self})
	return instant
end
function player:init(uid,s,ret_handler)
	-- body
	self.session = s
	self.uid = uid
	self.zid = -1  --玩家所在的空间 -1不在任何游戏场景（圣光营地，奥斯深渊)
	self.matchid = -1 --玩家比赛房间id
	self.side = -1 --0:左边  1:右边
	self.heroid = -1--玩家的英雄id
	self.state = State.InView --玩家当前的状态（InView = 1, --集结玩家
											-- Ready =2, --玩家集结完毕
											-- Start = 3, --玩家都准备好了
											-- Playing = 4,--游戏中
											-- CheckOut = 5, -- 游戏结算）

	self.is_robot = false	--玩家是否为机器人										
	self.client_ip = nil --玩家对应的客户端的 udp的ip地址
    self.client_udp_port = 0	--玩家对应的客户端的 udp的port
    self.sync_frameid = 0--玩家同步到那一帧
	--数据库
	mysql_game.get_ugame_info(uid,function (err,ugame_info)
		-- body
		if err then
			if ret_handler then
				ret_handler(Respones.SystemErr)
			end
			return
		end
		self.ugame_info = ugame_info
		
		redis_center.get_uinfo_inredis(uid, function (err, uinfo)
			if err then 
				if ret_handler then
					ret_handler(Respones.SystemErr) 
				end
				return
			end

			self.uinfo = uinfo
			if ret_handler then
				ret_handler(Respones.OK) 
			end
		end)
	end)
	--end

end
function player:set_session(s)
	-- body
	self.session = s
end
function player:set_udp_addr(ip,port)
	self.client_ip = ip
	self.client_udp_port=port

end
--获取玩家自己信息 的body
function player:get_user_arrived( ... )
	-- body
	local body = {
		unick = self.uinfo.unick,
		uface = self.uinfo.uface,
		usex = self.uinfo.usex,
		seatid = self.seatid,
		side = self.side,
	}
	-- print("body.unick",body.unick ," body.uface" ,body.uface, " body.usex",body.usex,"body.seatid",body.seatid,body.side)
	return body
end
--玩家通过自己的session 返回指定的消息命令
function player:send_cmd(stype,ctype,body)
	-- body
	-- print(game_config.servers[stype].desic,ctype,body)
	if not self.session or self.is_robot then
		return
	end
	local msg = {stype,ctype,self.uid,body}
	Session.send_msg(self.session,msg)
end
function player:udp_send_cmd(stype,ctype,body)
	if not self.session or self.is_robot then
		return
	end

	if not self.client_ip or self.client_udp_port ==0 then
		return
	end
	local msg = {stype,ctype,0,body}
	-- print("frameid:",body.frameid,self.client_ip,self.client_udp_port)

	Session.udp_send_msg(self.client_ip,self.client_udp_port,msg)
end
return player