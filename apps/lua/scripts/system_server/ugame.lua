local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local mysql_game = require("database/mysql_game")
local login_bonues = require("system_server/login_bonues")
local redis_game  = require("database/redis_game")
local redis_rank  = require("database/redis_rank")

function get_ugame_info(s,req)

	local uid = req[3]
	print("*************ugame.get_ugame_info****************",uid)

	mysql_game.get_ugame_info(uid,function (err,ugame_info)
		-- body
		if err then
			local msg = {Stype.System,Cmd.eGetUgameInfoRes,uid,{
				status = Respones.SystemErr,
			}}
			Session.send_msg(s,msg)
			return
		end
		if ugame_info ==nil then --没找到对应的id信息 g_key
			mysql_game.insert_ugame_info(uid,function (err,ret)
				if err then
					print("******mysql_game.insert_ugame_info  err!!*****"..err)
					local msg = {Stype.System,Cmd.eGetUgameInfoRes,uid,{
					status = Respones.SystemErr,
					}}
					Session.send_msg(s,msg)
					return
				end
				get_ugame_info(s,req)
			end)

			return

		end

		--*****************************游戏开始的逻辑**********************************************
		--读取到id的信息
		if ugame_info.ustatus~=0 then --账号封号
			local msg={Stype.System,Cmd.eGetUgameInfoRes,uid,{
				status = Respones.UserIsFreeze,--
			}}
			Session.send_msg(s,msg)
			return
		end

		--更新游戏redis数据库中的数据
		redis_game.set_ugame_info_inredis(uid,ugame_info)

		--刷新世界排行榜
		redis_rank.flush_world_rank_with_uchip_inredis(uid,ugame_info.uchip)

		--检查登陆奖励
		login_bonues.check_login_bonues(uid,function (err,bonues_info)
			-- body
			if err then
				local msg = {Stype.System,Cmd.eGetUgameInfoRes,uid,{
						status = Respones.SystemErr
				}}
				Session.send_msg(s,msg)
				return
			end
			local msg = {Stype.System,Cmd.eGetUgameInfoRes,uid,{
						status = Respones.OK,
						uinfo = {
							uchip = ugame_info.uchip,
							uexp = ugame_info.uexp,
							uvip = ugame_info.uvip,
							uchip2 = ugame_info.uchip2,
							uchip3 = ugame_info.uchip3,
							udata1 = ugame_info.udata1,
							udata2 = ugame_info.udata2,
							udata3 = ugame_info.udata3,

							bonues_status = bonues_info.status,
							bonues = bonues_info.bonues,
							days = bonues_info.days
					}
				}}
			Session.send_msg(s,msg)
		end)
	end)
end
local ugame={
	get_ugame_info = get_ugame_info
}

return ugame