
local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local game_mgr = require("logic_server/game_mgr")
local logic_service_handles = {}

logic_service_handles[Cmd.eLoginLogicReq] = game_mgr.login_logic_server
logic_service_handles[Cmd.eUserLostConn] = game_mgr.on_player_disconnect
logic_service_handles[Cmd.eEnterZoneReq] = game_mgr.enter_zone --进入某个地图
logic_service_handles[Cmd.eExitMatchReq] = game_mgr.do_exit_mathch --玩家退出房间
logic_service_handles[Cmd.eUdpTest] = game_mgr.do_udp_test --udp测试
logic_service_handles[Cmd.eNextFrameOpts] = game_mgr.on_next_frame_event --下一帧的事件
function on_logic_recv_cmd(s,msg)
	-- print("**********on_logic_recv_cmd:",msg[2])
	if logic_service_handles[msg[2]] then
		logic_service_handles[msg[2]](s,msg)
	end
end

function on_gateway_disconnect(s,stype)
	print("Logic service disconnect with gateway !!!")
	game_mgr.on_gateway_disconnect(s)
end

function on_gateway_connect(s,stype)
	print("gateway connect to Logic !!!")
	game_mgr.on_gateway_connect(s)
end
local logic_service = {
	on_session_recv_cmd = on_logic_recv_cmd,
	on_session_disconnect = on_gateway_disconnect,
	on_session_connect = on_gateway_connect,

}

return logic_service