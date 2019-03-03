--用户服务器
--初始化日志模块
Logger.init("logger/logic_server/","logic",true)
--end

--连接用户中心数据库
require("database/mysql_game")

--end
local proto_type =
{
	PROTO_JSON =0,
	PROTO_BUF = 1,
}

ProtoMan.init(proto_type.PROTO_BUF)
---注册protobuf 协议的映射表
if ProtoMan.proto_type() == proto_type.PROTO_BUF then
	local cmd_name_map = require("cmd_name_map")
	if cmd_name_map then
		ProtoMan.register_protobuf_cmd_map(cmd_name_map)
	end
end
--end

local game_config = require("game_config")
local servers = game_config.servers
local Stype = require("Stype")

--开启用户服 监听
Netbus.tcp_listen(servers[Stype.Logic].port)
print("Logic Server Start At"..servers[Stype.Logic].port)
Netbus.udp_listen(game_config.logic_udp.port)

--end
--注册服务器
local Logic_service = require("logic_server/logic_service");
local ret = Service.register(Stype.Logic,Logic_service)
if(ret)  then
		print("register Logic Service["..  Stype.Logic  .."]  success")
else
		print("register Logic Service[".. Stype.Logic .."]  failed")
end


