--网关服务器
--初始化日志模块
Logger.init("logger/geteway/","geteway",true)
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

--开启网络服务
Netbus.tcp_listen(game_config.gateway_tcp_port)
Netbus.ws_listen(game_config.gateway_ws_port)
--end
--注册服务器
local servers = game_config.servers;
local gw_service = require("gateway/gw_service")
-- local extern = require("extern")
for k,v in pairs(servers) do
	local ret = Service.register_with_raw(v.stype,gw_service)
	if ret then
		print("register gw_server["..  v.stype  .."]  success")
	else
		print("register gw_server["..  v.stype  .."]  failed")

	end
end



