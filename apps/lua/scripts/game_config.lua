local Stype = require("Stype")
local remote_servers ={}


--游戏用户服 配置
remote_servers[Stype.Auth] = 
{
	stype = Stype.Auth,
	ip = "127.0.0.1",
	port = 8000,
	desic = "Auth server",
}
--游戏系统服 配置
remote_servers[Stype.System] = 
{
	stype = Stype.System,
	ip = "127.0.0.1",
	port = 8001,
	desic = "System server",
}	
--游戏逻辑服 配置
remote_servers[Stype.Logic] = 
{
	stype = Stype.Logic,
	ip = "127.0.0.1",
	port = 8002,
	desic = "Logic server",
}	

local game_config=
{
	gateway_tcp_ip = "127.0.0.1",
	gateway_tcp_port = 6080,

	gateway_ws_ip = "127.0.0.1",
	gateway_ws_port = 6081,

	servers = remote_servers,
	--用户数据库
	auth_mysql =   
	{
		host = "127.0.0.1",
		port = "3306",
		db_name = "auth_center", --数据库 名
		uname = "root",			--数据库账号
		upwd = "root",			--数据库密码
	},
	--用户中心redis
	center_redis ={
		host = "127.0.0.1", --redis的host
		port = 6379,        --redis 端口
		db_index = 1, 		--redis的数据
	},
	--游戏数据库
	game_mysql =
	{
		host = "127.0.0.1",
		port = 3306,
		db_name = "moba_game",
		uname ="root",
		upwd ="root",
	},
	--游戏redis
	game_redis = 
	{
		host = "127.0.0.1", --redis的host
		port = 6379,        --redis 端口
		db_index = 2, 		--redis的数据
	},
	--排行redis
	rank_redis = 
	{
		host = "127.0.0.1", --redis的host
		port = 6379,        --redis 端口
		db_index = 3 	, 		--redis的数据
	},
	--logic server udp
	logic_udp =
	{
		host = "127.0.0.1",
		port = 8800,
	}
}
return game_config