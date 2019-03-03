local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
local mysql_game = require("database/mysql_game")
local login_bonues = require("system_server/login_bonues")
local redis_game  = require("database/redis_game")
local redis_rank  = require("database/redis_rank")
local redis_center = require("database/redis_center")

--发送客户端查询信息（昵称，头像，性别，vip，奖励信息）
function send_rank_info_to_client(s,uid,rank_uids,rank_user_info,rank_ugame_info)
	print("*******send_rank_info_to_client*******",#rank_uids,#rank_user_info,#rank_ugame_info)
	print("uface:",rank_user_info[1].uface)
	local rank_info_body = {}
	local i 
	for i=1,#rank_uids do
		local user_rank_info = {
			unick = rank_user_info[i].unick,
			uface = rank_user_info[i].uface,
			usex = rank_user_info[i].usex,
			uvip = rank_ugame_info[i].uvip,
			uchip = rank_ugame_info[i].uchip,
		}
		rank_info_body[i] = user_rank_info
	end
	print(rank_info_body[1].unick,rank_info_body[1].uface,rank_info_body[1].usex,rank_info_body[1].uvip,rank_info_body[1].uchip)
	local msg = {Stype.System,Cmd.eGetWorldRankUchipRes,uid,{
		status = Respones.OK,
		rank_info = rank_info_body,
	}}

	Session.send_msg(s,msg)
end
--redis 游戏数据库 通过 id 获取游戏数据
function get_rank_user_ugame_info(index,rank_uid,success_func,failed_func)
	-- body
	redis_game.get_ugame_info_inredis(rank_uid,function (err,ugame_info)
		-- body
		if err or ugame_info==nil then
			if failed_func then
				failed_func()
			end
		end
		success_func(index,ugame_info)
	end)
end
--通过Uids 获取排名信息（上层获取到 rank_uids和rank_uinfo）
function get_rank_ugame_info(s,uid,rank_uids,rank_uinfo)
	-- body
	local rank_ugame_info = {}
	local failed_func = function ()
		-- body
		local msg = {Stype.System,Cmd.eGetWorldRankUchipRes,uid,{
				status = Respones.SystemErr,
		}}
		Session.send_msg(s,msg)
		return
	end
	local success_func = function(index,ugame_info)
		rank_ugame_info[index] = ugame_info
		if index ==#rank_uids then
			send_rank_info_to_client(s,uid,rank_uids,rank_uinfo,rank_ugame_info)
		else
			index = index+1
			get_rank_user_ugame_info(index,rank_uids[index],success_func,failed_func)
		end
	end
	get_rank_user_ugame_info(1,rank_uids[1],success_func,failed_func)

end
--redis中心数据库 通过id  获取用户信息
function get_rank_user_center_info(index,rank_uid,success_func,failed_func)
	-- body
	redis_center.get_uinfo_inredis(rank_uid,function (err,uinfo)
		-- body
		if err or uinfo==nil then
			if failed_func then
				failed_func()
			end
		end
		success_func(index,uinfo)
	end)
end
-- 主 ： 获取世界排行信息 前30
function get_world_uchip_rank(s,req)
	print("*********get_world_uchip_rank**********")
	local uid = req[3]
	redis_rank.get_world_rank_with_uchip_inredis(30,function (err,rank_uids)
		-- body
		if err or rank_uids ==nil then

			local msg = {Stype.System,Cmd.eGetWorldRankUchipRes,uid,{
					status = Respones.SystemErr,
			}}
			Session.send_msg(s,msg)
			return
		end
		if #rank_uids<=0 then
			print("get world rank list == 0")
			--没有记录
			local msg = {Stype.System,Cmd.eGetWorldRankUchipRes,uid,{

					status = Respones.OK,
			}}
			Session.send_msg(s,msg)
			return
		end

		print("get world rank list >=1!!!")
		local rank_user_info = {}
		local failed_func = function ( ... )
			-- body
			local msg = {Stype.System,Cmd.eGetWorldRankUchipRes,uid,{

					status = Respones.SystemErr,
			}}
			Session.send_msg(s,msg)
			return
		end
		local success_func = function (index,user_info)
			-- body
			rank_user_info[index] = user_info
			if index ==#rank_uids then --全部成功获取
				get_rank_ugame_info(s,uid,rank_uids,rank_user_info)
			else
				print("gggg",rank_user_info[index].uface)
				index = index+1
				get_rank_user_center_info(index,rank_uid[index],success_func,failed_func)
			end
		end
		get_rank_user_center_info(1,rank_uids[1],success_func,failed_func)

	end)
end
game_rank = 
{
	get_world_uchip_rank = get_world_uchip_rank,
}
return game_rank