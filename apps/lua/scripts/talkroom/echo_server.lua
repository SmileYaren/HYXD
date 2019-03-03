function echo_recv_cmd(s,msg)
	-- body
	print(msg[1])
	print(msg[2])
	print(msg[3])

	local  body = msg[4]
	print (body.name)
	print (body.email)
	print (body.age)
	print (body.int_set)

	local to_client = {1,2,0,{ status = 200}}
	Session.send_msg(s,to_client)

end

function echo_session_disconnect(s)
	-- body
	local  ip,port  = Session.get_address(s)
	print("esho_session_disconnect"..ip..":"..port)

end
local echo_service = 
{
	on_session_recv_cmd = echo_recv_cmd,
	on_session_disconnect = echo_session_disconnect,
}
local echo_server = 
{
	stype = 1,
	service=echo_service,
}
print ("regist echo server")
return echo_server;