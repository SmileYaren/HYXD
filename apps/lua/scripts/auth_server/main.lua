--用户服务器
--初始化日志模块
Logger.init("logger/auth_server/","auth",true)
--end

--连接用户中心数据库
require("database/mysql_auth_center")

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
Netbus.tcp_listen(servers[Stype.Auth].port)
print("Auth Server Start At"..servers[Stype.Auth].port)
--end
--注册服务器
local auth_service = require("auth_server/auth_service");
local ret = Service.register(Stype.Auth,auth_service)
if(ret)  then
		print("register Auth Service["..  Stype.Auth  .."]  success")
else
		print("register Auth Service[".. Stype.Auth .."]  failed")
end



-- mysql_wrapper.connect("127.0.0.1",3306,"taidou","root","root",function(err,context)
-- 	--log_debug("event call")
-- 	if err then
-- 		print(err)
-- 	else

-- 	end
-- 	mysql_wrapper.query(context,"select * from testuser",function(err, result) 

-- 		if(err) then
-- 			print(err)
-- 		else
-- 			PrintTable(result)
-- 		end
-- 		end)
-- 	-- mysql_wrapper.close(context)
-- end)
--[[


redis_wrapper.connect("127.0.0.1",6379,function(err,context)
	if err then
		print(err)
		return
	end
		print("redis connect success")
		redis_wrapper.query(context,"hmset test_1 name xiaoli age 19 des hahaha",function(err,result)
			if err then
				print(err)
				return
			end
			print("redis query set suceess")
			print(result)

				redis_wrapper.query(context,"hgetall test_1",function(err,result)
				if err then
					print(err)
					return
				end
					print("redis query get suceess")
					PrintTable(result)
				end)
			end)
		-- redis_wrapper.query(context,"hgetall test_1",function(err,result)
		-- 		if err then
		-- 			print(err)
		-- 			return
		-- 		end
		-- 			print("redis query get suceess")
		-- 			PrintTable(result)
		-- 		end)
		
	end)
]]
-- local my_service={
-- 	on_session_recv_md = function(session,msg)
-- 		-- body
-- 	end,
-- 	on_session_disconnect= function(session)
-- 		-- body

-- 	end
-- }
-- local ret = service.register(100,my_service)