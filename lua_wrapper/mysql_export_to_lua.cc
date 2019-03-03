#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lua_wrapper.h"
#include "../database/mysql_wrapper.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "tolua++.h"
#ifdef __cplusplus
}
#endif

#include "tolua_fix.h"
#include "mysql_export_to_lua.h"

static void
on_open_cb(const char* err, void* context, void* udata) {
	if (err) {
		lua_pushstring(lua_wrapper::lua_state(), err);
		lua_pushnil(lua_wrapper::lua_state());
	}
	else {
		lua_pushnil(lua_wrapper::lua_state());
		tolua_pushuserdata(lua_wrapper::lua_state(), context);
	}

	lua_wrapper::execute_script_handler((int)udata, 2);
	lua_wrapper::remove_script_handler((int)udata);
}

static int
lua_mysql_connect(lua_State* tolua_S) {
	char* ip = (char*)tolua_tostring(tolua_S, 1, 0);
	if (ip == NULL) {
		goto lua_failed;
	}

	int port = (int)tolua_tonumber(tolua_S, 2, 0);

	char* db_name = (char*)tolua_tostring(tolua_S, 3, 0);
	if (db_name == NULL) {
		goto lua_failed;
	}

	char* uname = (char*)tolua_tostring(tolua_S, 4, 0);
	if (uname == NULL) {
		goto lua_failed;
	}

	char* upwd = (char*)tolua_tostring(tolua_S, 5, 0);
	if (upwd == NULL) {
		goto lua_failed;
	}

	int handler = toluafix_ref_function(tolua_S, 6, 0);
	mysql_wrapper::connect(ip, port, db_name, uname, upwd, on_open_cb, (void*)handler);

lua_failed:
	return 0;
}

static int
lua_mysql_close(lua_State* tolua_S) {
	void* context = tolua_touserdata(tolua_S, 1, 0);
	if (context) {
		mysql_wrapper::close(context);
	}
	return 0;
}

static void
push_mysql_row(MYSQL_ROW row, int num) {
	lua_newtable(lua_wrapper::lua_state());                                              /* L: table */
	int index = 1;
	for (int i = 0; i < num; i++)  {
		if (row[i] == NULL) {
			lua_pushnil(lua_wrapper::lua_state());
		}
		else {
			lua_pushstring(lua_wrapper::lua_state(), row[i]);
		}

		lua_rawseti(lua_wrapper::lua_state(), -2, index);          /* table[index] = value, L: table */
		++index;
	}
}

static void
on_lua_query_cb(const char* err, MYSQL_RES* result, void* udata) {
	if (err) {
		lua_pushstring(lua_wrapper::lua_state(), err);
		lua_pushnil(lua_wrapper::lua_state());
	}
	else {
		lua_pushnil(lua_wrapper::lua_state());
		if (result) { // �Ѳ�ѯ�õ��Ľ��push��һ����; { {}, {}, {}, ...}
			lua_newtable(lua_wrapper::lua_state());
			int index = 1;
			int num = mysql_num_fields(result);
			MYSQL_ROW row;
			while (row = mysql_fetch_row(result)) {
				push_mysql_row(row, num); /* L: table value */
				lua_rawseti(lua_wrapper::lua_state(), -2, index);          /* table[index] = value, L: table */
				++index;
			}
		}
		else {
			lua_pushnil(lua_wrapper::lua_state());
		}
	}

	lua_wrapper::execute_script_handler((int)udata, 2);
	lua_wrapper::remove_script_handler((int)udata);
}

static int
lua_mysql_query(lua_State* tolua_S) {
	void* context = tolua_touserdata(tolua_S, 1, 0);
	if (!context) {
		goto lua_failed;
	}
	char* sql = (char*)tolua_tostring(tolua_S, 2, 0);
	if (sql == NULL) {
		goto lua_failed;
	}
	int handler = toluafix_ref_function(tolua_S, 3, 0);
	if (handler == 0) {
		goto lua_failed;
	}

	mysql_wrapper::query(context, sql, on_lua_query_cb, (void*)handler);
lua_failed:
	return 0;
}

int
register_mysql_export(lua_State* tolua_S) {
	lua_getglobal(tolua_S, "_G");
	if (lua_istable(tolua_S, -1)) {
		tolua_open(tolua_S);
		tolua_module(tolua_S, "Mysql", 0);
		tolua_beginmodule(tolua_S, "Mysql");

		tolua_function(tolua_S, "connect", lua_mysql_connect);
		tolua_function(tolua_S, "close", lua_mysql_close);
		tolua_function(tolua_S, "query", lua_mysql_query);
		tolua_endmodule(tolua_S);
	}
	lua_pop(tolua_S, 1);
	return 0;
}