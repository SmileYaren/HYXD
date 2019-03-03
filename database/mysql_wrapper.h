#ifndef __MYSQL_WRAPPER_H__
#define __MYSQL_WRAPPER_H__
#include "mysql.h"
class mysql_wrapper
{
public:
	static void connect(char* ip,int port,
						char* db_name,char* uname,char* pwad,
						void(*open_cb)(const char* erro,void* context,void* udata),
					    void* udata=NULL
						);


	static void close(void* context);


	static void query(void* context,
						char* sql,
						void(*query_cb)(const char* erro, MYSQL_RES* result, void* udata),
						void* udata);

};

#endif