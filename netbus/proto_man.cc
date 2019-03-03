#include<stdlib.h>
#include<stdio.h>
#include<string.h>

using namespace std;
#include "proto_man.h"
#include "google/protobuf/message.h"
#include "../utils/small_alloc.h"
#include "../utils/catch_alloc.h"

extern cache_allocer* wbuf_allocer;
#define CMD_HEADER 8

#define my_malloc small_alloc
#define my_free small_free



static int g_proto_type = PROTO_BUF;
static std::map<int, std::string> g_pb_cmd_map;

void 
proto_man::init(int proto_type)
{
	g_proto_type = proto_type;
}
int
proto_man:: proto_type()
{
	return g_proto_type;
}

void 
proto_man::register_protobuf_cmd_map(std::map<int,std::string>& map)
{
	std::map<int, std::string>::iterator it;
	for (it = map.begin(); it != map.end(); it++)
	{
		g_pb_cmd_map[it->first] = it->second;
	}
}

const char*
proto_man::protobuf_cmd_name(int ctype) {
	return g_pb_cmd_map[ctype].c_str();
}
//------------------------------------------------
//一定要把 这两个局部方法 放到使用的方法体上面
google::protobuf::Message*
proto_man:: create_message(const char* type_name) {
	google::protobuf::Message* message = NULL;

	const google::protobuf::Descriptor* descriptor =
		google::protobuf::DescriptorPool::generated_pool()->FindMessageTypeByName(type_name);
	if (descriptor) {
		const google::protobuf::Message* prototype =
			google::protobuf::MessageFactory::generated_factory()->GetPrototype(descriptor);
		if (prototype) {
			message = prototype->New();
		}
	}
	return message;
}
void
proto_man::release_message(google::protobuf::Message* m)
{
	delete m;
}
bool					//包体                  //包体大小     ///解包之后的命令
proto_man::decode_raw_cmd(unsigned char* cmd, int cmd_len, struct raw_cmd* raw)
{
	if (cmd_len < CMD_HEADER)
	{
		return false;
	}

	raw->stype = cmd[0] | (cmd[1] << 8);
	raw->ctype = cmd[2] | (cmd[3] << 8);
	raw->utag = cmd[4] | (cmd[5] << 8) | (cmd[6] << 16) | (cmd[7] << 24);

	raw->raw_data = cmd;
	raw->raw_len = cmd_len;

	return true;
}

//--------------------------------------------------------end
//stype（2）  ctype(2) utype(4)  body()
bool proto_man::decode_cmd_msg(unsigned char* cmd, int cmd_len, struct cmd_msg** out_msg)
{
	*out_msg = NULL;

	if (cmd_len < CMD_HEADER)
	{
		return false;
	}

	struct cmd_msg* msg = (struct cmd_msg*)my_malloc(sizeof(struct cmd_msg));
	
	msg->stype = cmd[0] | (cmd[1] << 8);
	msg->ctype = cmd[2] | (cmd[3] << 8);
	msg->utag = cmd[4] | (cmd[5] << 8) | (cmd[6] << 16) | (cmd[7]<<24);
	msg->body = NULL;

	*out_msg = msg;
	if (cmd_len == CMD_HEADER) //空命令
		return true;
	if (g_proto_type == PROTO_JSON) //json
	{
		int json_len = cmd_len - CMD_HEADER;

		//char*json_str = (char*)malloc(json_len + 1);
		char* json_str = (char*)cache_alloc(wbuf_allocer,json_len+1);
		memcpy(json_str,cmd+CMD_HEADER,json_len);
		json_str[json_len] = 0;
		msg->body = (void*)json_str;
	}
	else //protobuf
	{
		google::protobuf::Message* p_m = create_message(g_pb_cmd_map[msg->ctype].c_str());

		if (p_m == NULL)
		{
			my_free(msg);
			*out_msg = NULL;
			return false;
		}
		if (!p_m->ParseFromArray(cmd + CMD_HEADER, cmd_len - CMD_HEADER))
		{
			my_free(msg);
			*out_msg = NULL;
			release_message(p_m);
			return false;
		}
		msg->body = p_m;
	}
	return true;
}




void 
proto_man::cmd_msg_free(struct cmd_msg* msg)
{
	if (msg->body)
	{
		if (g_proto_type == PROTO_JSON)
		{
			cache_free(wbuf_allocer,msg->body);
			msg->body = NULL;

		}
		else
		{
			google::protobuf::Message* p_m = (google::protobuf::Message*)msg->body;
			delete p_m;
			msg->body = NULL;
		}
	}
	my_free(msg);
}
//编码
unsigned char* 
proto_man::encode_msg_to_raw(const struct cmd_msg* msg, int* out_len)
{
	int raw_len = 0;
	unsigned char* raw_data = NULL;

	if (g_proto_type==PROTO_JSON)
	{
		char* json_str =NULL;
		int len = 0;
		if (msg->body)
		{
			json_str = (char*)msg->body;
		    len = strlen(json_str) + 1;
		}

		raw_data = (unsigned char*)cache_alloc(wbuf_allocer,CMD_HEADER + len);

		if (msg->body != NULL)
		{
			memcpy(raw_data + CMD_HEADER, json_str, len - 1);
			raw_data[8 + len] = 0;
		}
		*out_len = (len + CMD_HEADER);
	}
	else if (g_proto_type == PROTO_BUF)
	{
		google::protobuf::Message* p_m;
		int pf_len = 0;
		if (msg->body)
		{
		    p_m = (google::protobuf::Message*)msg->body;
		    pf_len = p_m->ByteSize();
		}
		raw_data = (unsigned char*)cache_alloc(wbuf_allocer,CMD_HEADER + pf_len);
		if (msg->body)
		{
			if (!p_m->SerializePartialToArray(raw_data + CMD_HEADER, pf_len))
			{
				cache_free(wbuf_allocer,raw_data);
				return NULL;
			}
		}
	
		*out_len = (pf_len +  CMD_HEADER );
	}
	else
	{
		return NULL;
	}
	//注意 括号  运算符的优先级
	raw_data[0] = (msg->stype & 0x000000ff);//取出低位 数据（8bit）放到低地址上
	raw_data[1] = ((msg->stype & 0x0000ff00) >> 8);//取出高位字节 放到高地址上
	raw_data[2] = (msg->ctype & 0x000000ff);
	raw_data[3] = ((msg->ctype & 0x0000ff00) >> 8);
	memcpy(raw_data + 4, &msg->utag, 4);

	return raw_data;
}

void proto_man::msg_raw_free(unsigned char* raw)
{
	cache_free(wbuf_allocer, raw);
}
