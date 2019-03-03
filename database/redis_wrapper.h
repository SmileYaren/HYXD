#ifndef __REDIS_WRAPPER_H__
#define __REDIS_WRAPPER_H__

#include<hiredis.h>

struct redisReply;

class redis_wrapper
{
public:
	static void connect(char* ip,int port,
						void(*open_cb)(const char* erro,void* context,void* udata),
						void* udata=NULL
						);


	static void close_redis(void* context);


	static void query(void* context,
						char* sql,
						void(*query_cb)(const char* erro, redisReply* result, void* udata),
						void* udata = NULL
						);

};

#endif