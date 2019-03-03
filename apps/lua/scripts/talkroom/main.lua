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

--开启网络服务
Netbus.tcp_listen(6080)
Netbus.ws_listen(8001)
Netbus.udp_listen(8002)

--end
print("start service success !!!")
--注册服务器
local trm_server = require("trm_server");
local ret = Service.register(trm_server.stype,trm_server.service)
if(ret)  then
	print("register trm server  success")
else
	print("register trm server  failed")
end


-- print("hello mm")
-- key = ""
-- function PrintTable(table , level)
--   level = level or 1
--   local indent = ""
--   for i = 1, level do
--     indent = indent.."  "
--   end

--   if key ~= "" then
--     print(indent..key.." ".."=".." ".."{")
--   else
--     print(indent .. "{")
--   end

--   key = ""
--   for k,v in pairs(table) do
--      if type(v) == "table" then
--         key = k
--         PrintTable(v, level + 1)
--      else
--         local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
--       print(content)  
--       end
--   end
--   print(indent .. "}")

-- end

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