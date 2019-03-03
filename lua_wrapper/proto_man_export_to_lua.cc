#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../netbus/proto_man.h"

#include "lua_wrapper.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "tolua++.h"
#ifdef __cplusplus
}
#endif

#include "tolua_fix.h"

#include "proto_man_export_to_lua.h"

#include "google/protobuf/message.h"
using namespace google::protobuf;

// local cmd_name_map = {"Name2", "Name1", "Name3"}... Lua 1��ʼ, cmd 1��ʼ
static int
lua_register_protobuf_cmd_map(lua_State* L) {
	std::map<int, std::string> cmd_map;
	int n = luaL_len(L, 1);
	if (n <= 0) {
		goto lua_failed;
	}
	for (int i = 1; i <= n; i++) {
		lua_pushnumber(L, i);
		lua_gettable(L, 1);
		const char* name = luaL_checkstring(L, -1);
		if (name) {
			cmd_map[i] = name;
		}
		lua_pop(L, 1);
	}
	proto_man::register_protobuf_cmd_map(cmd_map);
lua_failed:
	return 0;
}

static int
lua_proto_type(lua_State* tolua_S) {
	lua_pushinteger(tolua_S, proto_man::proto_type());
	return 1;
}

static int
lua_proto_man_init(lua_State* tolua_S) {
	int argc = lua_gettop(tolua_S);
	if (argc != 1) {
		goto lua_failed;
	}
	int proto_type = (int)lua_tointeger(tolua_S, 1);
	if (proto_type != PROTO_JSON && proto_type != PROTO_BUF) {
		goto lua_failed;
	}

	proto_man::init(proto_type);
lua_failed:
	return 0;
}

int
register_proto_man_export(lua_State* tolua_S) {
	lua_getglobal(tolua_S, "_G");
	if (lua_istable(tolua_S, -1)) {
		tolua_open(tolua_S);
		tolua_module(tolua_S, "ProtoMan", 0);
		tolua_beginmodule(tolua_S, "ProtoMan");

		tolua_function(tolua_S, "init", lua_proto_man_init);
		tolua_function(tolua_S, "proto_type", lua_proto_type);
		tolua_function(tolua_S, "register_protobuf_cmd_map", lua_register_protobuf_cmd_map);
		tolua_endmodule(tolua_S);
	}
	lua_pop(tolua_S, 1);

	return 0;
}

// RawCmd.read_header(raw_cmd)
static int
lua_raw_read_header(lua_State* tolua_S) {
	int argc = lua_gettop(tolua_S);
	if (argc != 1) {
		goto lua_failed;
	}

	struct raw_cmd* raw = (struct raw_cmd*) tolua_touserdata(tolua_S, 1, NULL);
	if (raw == NULL) {
		goto lua_failed;
	}

	lua_pushinteger(tolua_S, raw->stype);
	lua_pushinteger(tolua_S, raw->ctype);
	lua_pushinteger(tolua_S, raw->utag);

	return 3;

lua_failed:
	return 0;
}

void
push_proto_message_tolua(const Message* message);

static int
lua_raw_read_body(lua_State* tolua_S) {
	int argc = lua_gettop(tolua_S);
	if (argc != 1) {
		goto lua_failed;
	}

	struct raw_cmd* raw = (struct raw_cmd*) tolua_touserdata(tolua_S, 1, NULL);
	if (raw == NULL) {
		goto lua_failed;
	}

	struct cmd_msg* msg;
	if (proto_man::decode_cmd_msg(raw->raw_data, raw->raw_len, &msg)) {
		if (msg->body == NULL) {
			lua_pushnil(tolua_S);
		}
		else if (proto_man::proto_type() == PROTO_JSON) {
			lua_pushstring(tolua_S, (const char*)msg->body);
		}
		else {
			push_proto_message_tolua((Message*)msg->body);
		}
		proto_man::cmd_msg_free(msg);
	}
	return 1;

lua_failed:
	return 0;
}

static int
lua_raw_set_utag(lua_State* tolua_S) {
	int argc = lua_gettop(tolua_S);
	if (argc != 2) {
		goto lua_failed;
	}

	struct raw_cmd* raw = (struct raw_cmd*) tolua_touserdata(tolua_S, 1, NULL);
	if (raw == NULL) {
		goto lua_failed;
	}

	unsigned int utag = (unsigned int)luaL_checkinteger(tolua_S, 2);
	raw->utag = utag;
	// �޸����ǵ�body�ڴ�;

	unsigned char* utag_ptr = raw->raw_data + 4;
	utag_ptr[0] = (utag & 0x000000FF);
	utag_ptr[1] = ((utag & 0x0000FF00) >> 8);
	utag_ptr[2] = ((utag & 0x00FF0000) >> 16);
	utag_ptr[3] = ((utag & 0xFF000000) >> 24);

	return 0;

lua_failed:
	return 0;
}

int
register_raw_cmd_export(lua_State* tolua_S) {
	lua_getglobal(tolua_S, "_G");
	if (lua_istable(tolua_S, -1)) {
		tolua_open(tolua_S);
		tolua_module(tolua_S, "RawCmd", 0);
		tolua_beginmodule(tolua_S, "RawCmd");

		tolua_function(tolua_S, "read_header", lua_raw_read_header);
		tolua_function(tolua_S, "set_utag", lua_raw_set_utag);
		tolua_function(tolua_S, "read_body", lua_raw_read_body);
		tolua_endmodule(tolua_S);
	}
	lua_pop(tolua_S, 1);

	return 0;
}

