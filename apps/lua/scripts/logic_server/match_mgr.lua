local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local mysql_game = require("database/mysql_game")
local redis_game = require("database/redis_game")
local State = require("logic_server/State")
local Zone = require("logic_server/Zone")
local player = require("logic_server/player")

local match_mgr = {}
local sg_matchid = 1
local PLAYER_NUM = 1 --1v1
local LOGIC_FRAME_TIME = 66 --逻辑帧的间隔

function match_mgr:new(instant)
	-- body
	if not instant then
		instant = {}
	end
	setmetatable(instant,{__index =self})
	return instant
end

function match_mgr:init(zid)
	-- body
	self.zid = zid
	self.matchid = sg_matchid
	sg_matchid = sg_matchid+1
	self.state = State.InView
	self.frameid = 0 --从第0帧开始

	self.inview_players = {}-- 旁观玩家的列表
	self.lhs_players = {}  --左侧玩家列表
	self.rhs_players = {}--右侧玩家列表
end

function match_mgr:broadcast_cmd_inview_players(stype, ctype, body, not_to_player)
	local k, v

	for k, v in pairs(self.inview_players) do 
		if v ~= not_to_player then 
			v:send_cmd(stype, ctype, body)
		end
	end
end
function match_mgr:enter_player(p) --房间添加  玩家
	-- print("matchid:",self.matchid,"uid:",p.uid,"match state: ",self.state,"player state: ",p.state)
	if self.state~=State.InView or p.state~=State.InView then --如果房间状态和玩家的状态不是 集结状态 就返回
		return false
	end
	p.matchid = self.matchid
	--将玩家添加到集结列表中
	for i=1,PLAYER_NUM*2 do
		if not self.inview_players[i] then
			self.inview_players[i]=p
			p.seatid= i
			p.side =1  --默认分配玩家在那一边
			if i>PLAYER_NUM then
				p.side = 0
			end
			break
		end
	end

	--告诉客户端 你已经进入一个房间
	local body={
		zid = self.zid,
		matchid = self.matchid,
		seatid = p.seatid,
		side = p.side,
	}
	p:send_cmd(Stype.Logic,Cmd.eEnterMatch,body)

	--告诉房间其他的玩家 有玩家进入
	body = p:get_user_arrived()
	self:broadcast_cmd_inview_players(Stype.Logic,Cmd.eUserArrived,body,p)

	--告诉 当前玩家 房间其他人的信息
	for i = 1, #self.inview_players do 
		if self.inview_players[i] and self.inview_players[i] ~= p then 
			-- print("tell other player:",self.inview_players[i].uid)
			body = self.inview_players[i]:get_user_arrived()
			p:send_cmd(Stype.Logic, Cmd.eUserArrived, body)
		end
	end
	--房间所有玩家的状态 = Ready判断
	if #self.inview_players>=PLAYER_NUM*2 then
		self.state = State.Ready
		self:update_players_state(State.Ready)
		for i=1,PLAYER_NUM*2 do
			self.inview_players[i].heroid =math.floor(math.random()*5 +1)
		end
		self:game_start()
	end 
	return true

end
function match_mgr:game_start()
	print("~~~~game_start~~~~~",self.matchid)

	local players_match_info = {}
	for i=1, PLAYER_NUM*2 do
		local p = self.inview_players[i]
		local info = {
			heroid = p.heroid,
			seatid = p.seatid,
			side = p.side,
		}

		table.insert(players_match_info,info)
	end
	local body =
	{
		players_match_info = players_match_info,
	}
	-- self:broadcast_cmd_inview_players(Stype.Logic,Cmd.eGameStart,body,nil)
	self:broadcast_cmd_inview_players(Stype.Logic,Cmd.eGameStart,body,nil)
	
	self.state = State.Playing--游戏开始状态
	self:update_players_state(State.Playing)
	--5秒后开始 第一个帧事件  1s=> 20 帧  or 1帧=> 50ms 
	self.frameid = 1 --从第1帧开始
	self.match_frames = {}
	self.next_frame_opt = {frameid = self.frameid,opts = {}}

	self.frame_timer = Scheduler.schedule(function ()
		self:on_logic_frame()
	end,5000,-1,LOGIC_FRAME_TIME)
	--
end
---帧事件 (每隔一段时间执行一次）
function match_mgr:on_logic_frame()
	table.insert(self.match_frames, self.next_frame_opt)--当前房间 游戏所有操作 都存储在 match_frames
	
	for i=1, PLAYER_NUM*2 do
		local p = self.inview_players[i]
		if p then
			-- print("uid :"..p.uid.."  frameid:"..p.sync_frameid)
			self:send_unsync_frames(p)
		end
	end
	self.frameid = self.frameid+1
	self.next_frame_opt = {frameid = self.frameid,opts = {}}--初始化 下一帧的 操作内容 空的
end
--将帧事件发送给玩家(整合 当前玩家所有 未同步的帧)
function match_mgr:send_unsync_frames(p)
	local opt_frams = {}
	for i=(p.sync_frameid+1),#self.match_frames do
		table.insert(opt_frams,self.match_frames[i])
	end
	local body = {frameid = self.frameid,unsync_frames = opt_frams}
	p:udp_send_cmd(Stype.Logic,Cmd.eLogicFrame,body)
end
function match_mgr:update_players_state(state)
	for i=1,PLAYER_NUM*2 do
		self.inview_players[i].state = state
	end
end
function match_mgr:exit_player(p)
	local body=
	{
		seatid = p.seatid
	}
	self:broadcast_cmd_inview_players(Stype.Logic,Cmd.eUserExitMatch,body,p)
	self.inview_players[p.seatid] = nil
	--?????
	-- local index = 0
	-- for index=1,#self.inview_players do
	-- 	if self.inview_players[index]==p then
	-- 		table.remove(self.inview_players,index)
	-- 	end
	-- end

	p.zid = -1 
	p.matchid = -1
	p.seatid = -1
	p.side = -1

	local body = {status = Respones.OK}
	p:send_cmd(Stype.Logic,Cmd.ExitMatchRes,body)

	--通知其他人 玩家离开
end
--外部调用；（房间所有玩家）客户端发送最新帧操作    获取最新 self.next_frame_opt 
function match_mgr:on_next_frame_event(next_frame_opts)
	local seatid = next_frame_opts.seatid
	-- print(seatid,next_frame_opts.frameid,#next_frame_opts.opts)

	local p = self.inview_players[seatid]
	if not p  then
		return
	end

	if p.sync_frameid<next_frame_opts.frameid-1 then  --客户端告诉我他当前是第100帧 当前服务器中 p 的 sync_frameid是第 98帧
		p.sync_frameid = next_frame_opts.frameid-1  --更新同步服务器 的p的sync_frameid（说明服务器丢帧了??或者说服务器慢了）
	end

	if next_frame_opts.frameid ~=self.frameid then --服务器只接受最新帧 self.frameid：服务器固定帧（有规律的递增）
		return --如果客户端给我的帧不是最新的 抛弃掉
	end
	for i=1,#next_frame_opts.opts do--一般就一个操作事件集合
		table.insert(self.next_frame_opt.opts, next_frame_opts.opts[i])---插入当前帧的操作 optevent
	end
end
return match_mgr