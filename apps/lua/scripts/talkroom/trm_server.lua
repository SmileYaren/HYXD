

function on_recv_login_cmd(s)
	-- body
end

function on_recv_exit_cmd(s)
	-- body
end
function on_recv_send_msg_cmd(s,str)
	-- body
end
--{stype,ctype,utag,body}
function on_trm_recv_cmd(s,msg)
	-- body
	local ctype =msg[2]
	local body =msg[4]

	if ctype ==1 then--登陆请求

	elseif ctype==3 then --推出请求

	elseif ctype===5 then--发消息请求

	end
end

function on_trm_session_disconnect(s)
	-- body
	local  ip,port  = Session.get_address(s)
	print("esho_session_disconnect"..ip..":"..port)

end
local trm_service = 
{
	on_session_recv_cmd = on_trm_recv_cmd,
	on_session_disconnect = on_trm_session_disconnect,
}
local trm_server = 
{
	stype = 1,
	service=trm_service,
}
print ("regist echo server")
return trm_server;