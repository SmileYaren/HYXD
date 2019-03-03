local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local mysql_game = require("database/mysql_game")

local sys_msg_data = {}
local sys_msg_version = 0  --记录消息版本，时间戳
function load_sys_msg( ... )
	print("********load_sys_msg")
	-- body
	mysql_game.get_sys_msg(function(err,ret)
			if err then
				Scheduler.once(load_sys_msg,5000)
				return
			end
			sys_msg_version = Utils.timestamp()
			if ret ==nil or # ret<=0 then
				sys_msg_data={}
				return
			end
			sys_msg_data = ret
			for k,v in pairs(sys_msg_data) do
				print(k,v)
			end
				--1点 更新一下 加载数据库中的配置
			local tormorow = Utils.timestamp_today()+25*60*60
			Scheduler.once(load_sys_msg,(tormorow-sys_msg_version)*1000)
		end)
end
Scheduler.once(load_sys_msg,5000)

--获取客户端请求 系统消息
function get_sys_msg(s,req)
	-- body
	print("*******************get_sys_msg*********************")
	local  uid = req[3]
	local body = req[4]
	print(uid,body.ver_num,sys_msg_version)
	if body.ver_num ==sys_msg_version then
		local msg = {Stype.System,Cmd.eGetSysMsgRes,uid,{
			status = Respones.OK,
			ver_num = sys_msg_version,
		}}
	end
	local msg = {Stype.System,Cmd.eGetSysMsgRes,uid,{
		status = Respones.OK,
		ver_num = sys_msg_version,
		sys_msgs = sys_msg_data,
	}}
	Session.send_msg(s,msg)
end

local sys_msg = {
	
	get_sys_msg = get_sys_msg,
}
return sys_msg
