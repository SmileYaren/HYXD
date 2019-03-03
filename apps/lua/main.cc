#include <stdio.h>
#include <string.h>
#include <stdlib.h>
//
#include <iostream>
#include <string>
using namespace std;

#include "../../netbus/netbus.h"
#include "../../netbus/proto_man.h"
#include "../../utils/time_list.h"
#include "../../utils/logger.h"
#include "../../database/mysql_wrapper.h"
#include "../../database/redis_wrapper.h"
#include"../../lua_wrapper/lua_wrapper.h"

static 
void on_logger_timer(void* udata)
{
	log_debug("on_logger_timer");
}
static void
on_query_cb(const char* err,MYSQL_RES* result,void *udata)
{
	if (err)
	{
		printf("err");
		return;
	}
	printf("query success\n");

}
static void 
on_open_cb(const char* err,void* context,void* data)
{
	if (err)
	{
		printf("err");
		return;
	}

	printf("connect mysql success\n");
	//mysql_wrapper::query(context, "update testuser set username = \"nnn\" where id = 3", on_query_cb);
	mysql_wrapper::query(context, "select * from testuser", on_query_cb,data);

	//mysql_wrapper::close(context);

}

static void test_db()
{
	mysql_wrapper::connect("127.0.0.1", 3306, "taidou", "root", "root", on_open_cb);

}
//redis
static void 
on_redis_qurey(const  char* err, redisReply* result, void* udata)
{
	if (err)
	{
		printf("err");
		return;
	}
	printf("redis qurey success\n");

}
static void 
on_redis_open(const char* err, void* context, void* udata)
{
	if (err != NULL)
	{
		printf("%s\n",err);
		return;
	}

	printf("connec redis success\n");
	redis_wrapper::query(context,"select 1",on_redis_qurey);
	redis_wrapper::close_redis(context);
}
static void test_redis()
{
	redis_wrapper::connect("127.0.0.1",6379,on_redis_open);
}

int main(int argc, char** argv) {
	netbus::instance()->init();
	lua_wrapper::init();

	//netbus::instance()->tcp_connect("127.0.0.1",7788,NULL,NULL);
 	if (argc != 3)//²âÊÔ
	{
		std::string search_path = "../../apps/lua/scripts/";
		lua_wrapper::add_search_path(search_path);
		//std::string lua_file = search_path + argv[2];
		std::string lua_file = search_path + "logic_server/main.lua";

		lua_wrapper::do_file(lua_file);
	}
	else
	{
		std::string search_path = argv[1];
		if (*(search_path.end() - 1) != '/')
		{
			search_path += "/";
		}

		lua_wrapper::add_search_path(search_path);

		std::string lua_file = search_path + argv[2];
		lua_wrapper::do_file(lua_file);


	}

	netbus::instance()->run();
	lua_wrapper::exit();
	system("pause");
	return 0;
}