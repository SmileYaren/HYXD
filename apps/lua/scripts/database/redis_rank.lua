local game_config = require("game_config")
local redis_conn = nil
local function is_connected( ... )
	-- body
	if not redis_conn then
		return false
	end

	return true
end
function redis_connect_to_rank()
	local host = game_config.rank_redis.host
	local port = game_config.rank_redis.port
	local db_index = game_config.rank_redis.db_index

	Redis.connect(host, port, function (err, conn)
		if err ~= nil then
			Logger.error(err)
			Scheduler.once(redis_connect_to_rank, 5000)
			return
		end

		redis_conn = conn
		Logger.debug("connect to redis rank db success!!!!")
		Redis.query(redis_conn, "select " .. db_index, function (err, ret)
		end)
	end)

end

redis_connect_to_rank()

local WOLD_CHIP_RANK = "WOLD_CHIP_RANK" 
function flush_world_rank_with_uchip_inredis(uid,uchip)
	print("***********flush_world_rank_with_uchip_inredis*************")
	-- body
		if redis_conn ==nil then
			Logger.error("redis rank disconnected")
		end
		local redis_cmd = "zadd WOLD_CHIP_RANK "..uchip.." "..uid
		Redis.query(redis_conn,redis_cmd,function (err,ret)
			-- body
			if err then
				return
			end
			print("user add rank list success!!!",uid,uchip)
		end)
end

function get_world_rank_with_uchip_inredis(n,ret_handler)
	-- body
	if redis_conn ==nil then
		Logger.error("redis rank disconnected")
	end

	local redis_cmd = "zrevrange WOLD_CHIP_RANK 0 "..n--从0---n的记录
	print("***********get_world_rank_with_uchip_inredis*********")
	Redis.query(redis_conn,redis_cmd,function (err,ret)
		-- body
		if err then
			if ret_handler then
				ret_handler("zrevrange WOLD_CHIP_RANK inredis error",nil)
			end
		end
		print("zrevrange WOLD_CHIP_RANK inredis  success!!!!")
		if ret==nil or #ret<=0 then
			ret_handler(nil,nil)
			return
		end

		local rank_info = {}
		local k,v
		for k,v in pairs(ret) do
			rank_info[k] = tonumber(v)
		end

		if ret_handler then
			ret_handler(nil,rank_info)
		end
	end)
end

local redis_rank = {
	get_world_rank_with_uchip_inredis = get_world_rank_with_uchip_inredis,
	flush_world_rank_with_uchip_inredis = flush_world_rank_with_uchip_inredis,
	is_connected = is_connected,
}

return redis_rank

