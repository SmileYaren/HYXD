
local game_config = require("game_config")
local server_session_man = {}
local do_connecting= {}

--游客key
local g_ukey =1
--key: utag    value:session
local client_sessions_ukey = {}

--key: uid    value:session
local client_sessions_uid ={}

local Stype = require("Stype")
local Cmd = require("Cmd")
local Respones = require("Respones")

--连接服务器
function connect_to_server(stype,ip,port)
	-- body
	Netbus.tcp_connect(ip,port,function(err,session)
		do_connecting[stype] = false
		if err~=0 then
			Logger.error("connect error to server["..game_config.servers[stype].desic.."]"..ip..":"..port)
			return
		end
		server_session_man[stype] = session --将服务器的session保存
		print("connect success to server ["..game_config.servers[stype].desic.."]"..ip..":"..port)

		end)
end
--检查连接状态
function check_server_connect( ... )
	-- body
	for k,v in pairs(game_config.servers) do
		if server_session_man[v.stype] ==nil and 
			do_connecting[v.stype]==false then

			do_connecting[v.stype]=true
			print("connecting to server[".. v.desic .."]"..v.ip..":"..v.port)
			connect_to_server(v.stype,v.ip,v.port)
		end
	end
end
--初始化
function gw_service_init( ... )
	print("**********gw_service_init**************")
	-- body
	for k,v in pairs(game_config.servers) do
		server_session_man[v.stype] = nil
		do_connecting[v.stype] = false
	end
	---  一秒钟之后执行，-1：无数次 ;5000：每隔五秒执行一次
	Scheduler.schedule(check_server_connect,1000,-1,5000)
end
--是否是游客或用户请求命令
function is_login_request_cmd(ctype)
	-- body
	if ctype ==Cmd.eGuestLoginReq or 
		ctype==Cmd.eUnameLoginReq then
		return true
	end	
	return false
end
--是否是游客或用户请求的返回 命令
function is_login_return_cmd(ctype)
	-- body
	if ctype== Cmd.eGuestLoginRes or
		 ctype==Cmd.eUnameLoginRes then
		return true
	end
	return false
end

--作为服务器 转发给 其他服务器消息 session 来自客户端
function send_to_server(client_session,raw_cmd)
	-- body
	local stype,ctype,utag =RawCmd.read_header(raw_cmd)
	print("send_to_server： ",stype,ctype,utag)
	local  server_session = server_session_man[stype] --得到我要发送给那个服务器
	if server_session ==nil then
		return
	end
	if is_login_request_cmd(ctype) then --客户端请求登陆
		utag= Session.get_utag(client_session)
		if utag==0 then
			utag = g_ukey
			g_ukey = g_ukey+1
			Session.set_utag(client_session,utag)
		end
		client_sessions_ukey[utag] =client_session
	elseif ctype ==Cmd.eLoginLogicReq then --登陆游戏逻辑服请求
		print("~~~~~~~Cmd.eLoginLogicReq~~~~~~~~")
		local uid = Session.get_uid(client_session)
		utag = uid
		if utag == 0 then --第一次登陆 没有uid 返回先去登陆 在执行其他命令
			return 
		end
		local tcp_ip,tcp_port= Session.get_address(client_session)
		print("tcp_ip",tcp_ip,"tcp_port",tcp_port)
		local body = RawCmd.read_body(raw_cmd)
		body.udp_ip = tcp_ip
		-- body.udp_port = tcp_port --自己加的？？

		print("#####"..body.udp_ip.."  "..body.udp_port)

		local login_logic_cmd = {stype,ctype,utag,body}
		Session.send_msg(server_session,login_logic_cmd)
		return
	else--其他命令
		local  uid =Session.get_uid(client_session)--得到客户端的 uid
		utag = uid
		if utag == 0 then --第一次登陆 没有uid 返回先去登陆 在执行其他命令
			return 
		end
	end
	
	RawCmd.set_utag(raw_cmd,utag)
	Session.send_raw_cmd(server_session,raw_cmd)
end

--作为客户端 收到 其他服务器消息 session 来自服务器
function  send_to_client(server_session,raw_cmd)
	local stype,ctype,utag = RawCmd.read_header(raw_cmd)
	local client_session =nil
	if is_login_return_cmd (ctype) then --如果是登陆返回的命令
		client_session = client_sessions_ukey[utag]
		client_sessions_ukey[utag] = nil

		if client_session ==nil then
			return
		end
		local body = RawCmd.read_body(raw_cmd)
		if body.status~=Respones.OK then
			RawCmd.set_utag(raw_cmd,0)
			Session.send_raw_cmd(client_session,raw_cmd)
			return
		end

		local  uid = body.uinfo.uid
		--
		if client_sessions_uid[uid] and client_sessions_uid[uid]~=client_session then  --？？
			local relogin_cmd = {Stype.Auth,Cmd.eRelogin,0,nil}
			Session.send_msg(client_sessions_uid[uid],relogin_cmd)
			Session.close(client_sessions_uid[uid])
		end

		client_sessions_uid[uid] = client_session
		Session.set_uid(client_session,uid)

		body.uinfo.uid = 0  --给客户端 数据时将uid 置空
		local login_res = {stype,ctype,0,body}
		Session.send_msg(client_session,login_res)
		return
	end

	-- 很有可能是uid来做key,可是同时要排除掉不是 ukey来做的?
	-- 必须要区分这个命令登陆前还是登陆后，
	--只有命令的类型才知道我们是要到uid里查，还是到ukey里查;
	-- 暂时先预留出来，因为和登陆有关系要衔接好;


	--登陆之后 处理命令。
	client_session = client_sessions_uid[utag]
	if client_session then
		RawCmd.set_utag(raw_cmd,0) --将utag设置为0  不让用户知道id号
		Session.send_raw_cmd(client_session,raw_cmd)

		if ctype==Cmd.eLoginOutRes then  --账号注销消息
			Session.set_uid(client_session,0)
			client_sessions_uid[utag] = nil
		end
	end

end


--接受消息
function on_gw_recv_raw_cmd(s,raw_cmd)
	-- body
	if Session.asclient(s) == 0 then
		send_to_server(s,raw_cmd) --作为服务器 转发给 其他服务器消息
	else
		send_to_client(s,raw_cmd) --作为客户端 收到 其他服务器消息
	end

end
--收到断开连接的消息 一种是连接服务器的连接断开  一种是客户端连接我的链接断开
function on_gw_session_disconnect(s,stype)
	-- print("on_gw_session_disconnect:",stype)y
	-- 连接到服务器的 session 断线了
	if Session.asclient(s) ==1 then
		for k,v in pairs(server_session_man) do
			if v==s then
				print("gateway disconnect ["..game_config.servers[k].desic.."]");	
				server_session_man[k] = nil
				return
			end
		end
		return
	end
	--连接到网关的客户端断线
	--把客户端从临时映射表中删除
	local utag = Session.get_utag(s)
	if client_sessions_ukey[utag] ~=nil and client_sessions_ukey[utag]==s then
		client_sessions_ukey[utag] =nil
		Session.set_utag(s,0)
	end
	--把客户端从uid映射表中删除
	local uid = Session.get_uid(s)
	if client_sessions_uid~=nil and client_sessions_uid[uid] == s then
		client_sessions_uid[uid] =nil
	end
	--如果网关没有与其他服务器连接 return
	local server_session = server_session_man[stype]
	if server_session ==nil then
		return
	end
	-- else 
	-- 客户端uid用户掉线了，我要把这个事件告诉和网关所连接的stype类服务器
	if uid ~= 0 then 
		local user_lost = {stype,Cmd.eUserLostConn,uid,nil}
		Session.send_msg(server_session,user_lost)
	end
end
gw_service_init()

local  gw_service = {
	--网关服务器使用 raw_cmd (未解包的原始数据)  接收客户端/服务端的命令
	on_session_recv_raw_cmd = on_gw_recv_raw_cmd,
	--断开客户端或者服务端的连接
	on_session_disconnect = on_gw_session_disconnect,
}


return gw_service