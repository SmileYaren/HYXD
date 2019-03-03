--系统服务器
--初始化日志模块
Logger.init("logger/auth_server/","system",true)

require("database/mysql_game")
--初始化协议模块
local  proto_type = 
{
	PROTO_JSON = 0,
	PROTO_BUF = 1,
}

ProtoMan.init(proto_type.PROTO_BUF)

--注册protobuf 协议的映射表
if ProtoMan.proto_type() ==proto_type.PROTO_BUF then
	local  cmd_name_map = require("cmd_name_map")
	if cmd_name_map then
		ProtoMan.register_protobuf_cmd_map(cmd_name_map)
	end
end
--end

local game_config =require("game_config")
local servers = game_config.servers
local Stype = require("Stype")

--开启系统服监听
Netbus.tcp_listen(servers[Stype.System].port)
print("System Server Start at ".. servers[Stype.System].port)

local system_server = require("system_server/system_server")
local ret = Service.register(Stype.System,system_server)
if ret then
	print("register System service:["..Stype.System .."] success!!!")
else
	print("register System service:["..Stype.System .."] failed!!!")
end