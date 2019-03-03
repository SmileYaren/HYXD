#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <iostream>
#include <string>
using namespace std;
//#pragma comment (lib, "libprotobufd.lib")
//#pragma comment (lib, "libprotocd.lib")
//#include "../apps/test/proto/game.pd.h"
#include "uv.h"
#include "session.h"
#include "session_uv.h"

#include "netbus.h"
#include "ws_protocol.h"
#include "tp_protocol.h"
#include "proto_man.h"
#include"service_man.h"
#include "udp_session.h"
#include "../utils/small_alloc.h";
extern "C" {

	static void 
	on_uv_udp_send_end(uv_udp_send_t* req,int status)
	{
		if (status==0)
		{ 
		}
		small_free(req);
	}
	///接收命令
	static void                         //包体（真实包）      //大小
	on_recv_client_command(session* s, unsigned char* body, int len)
	{
		//printf("client command !!!!\n");
		/*s->send_data(body,len);*/
		struct raw_cmd raw;
		//解包
		if (proto_man::decode_raw_cmd(body, len, &raw))
		{
			///通过 服务器管理者的map 分发事件
			if (!service_man::on_recv_raw_cmd((session*)s, &raw))
			{
				s->close();
			}
		}
	}

	///tcp接受数据
	static void 
	on_recv_tcp_data(uv_session* s)
	{
		///正在接收的包  包的大小一直在变化
		unsigned char * pkg_data = (unsigned char*)((s->long_pkg != NULL) ? s->long_pkg : s->recv_buf);
		while (s->recved>0)
		{
			//当前包的总大小  还没收完  一直在接收
			int pkg_size = 0;
			int head_size = 0;
			//pkg	  接受的pkg大小 //data大小  data head 大小
			if (!tp_protocol::read_header(pkg_data, s->recved, &pkg_size, &head_size))
			{
				break;
			}
			if (s->recved < pkg_size)
			{
				break; //继续收包
			}
			//地址相加  获取真实 数据包的 地址
			unsigned char* raw_data = pkg_data + head_size;//地址 向后移动两个字节 

			///解析命令  传入 session，真实包，包大小
			on_recv_client_command((session*)s, raw_data, pkg_size - head_size);

			if (s->recved > pkg_size)// 多收了一部分包
			{
				///将多收字节 放到pkg_data中
				memmove(pkg_data, pkg_data + pkg_size, s->recved - pkg_size);
			}
			//recved 存放多余的字节的长度
			s->recved -= pkg_size;

			///处理 大包的释放 空间
			if (s->recved == 0 && s->long_pkg != NULL)
			{
				free(s->long_pkg);
				s->long_pkg = NULL;
				s->long_pkg_size = 0;
			}
		}
	}
	static void 
	on_recv_ws_data(uv_session* s)
	{
		unsigned char * pkg_data = (unsigned char*)((s->long_pkg != NULL) ? s->long_pkg : s->recv_buf);
		while (s->recved>0)
		{
			int pkg_size = 0;
			int head_size = 0;
											//pkg	  接受的pkg大小 //data大小  data head 大小
			if (!ws_protocol::read_ws_header(pkg_data, s->recved, &pkg_size, &head_size))
			{
				break;
			}
			if (s->recved < pkg_size)
			{
				break; //继续收包
			}

			unsigned char* raw_data = pkg_data + head_size;
			unsigned char* mask = raw_data - 4;
			ws_protocol::parser_ws_recv_data(raw_data,mask,pkg_size-head_size);

			on_recv_client_command((session*)s,raw_data,pkg_size-head_size);

			if (s->recved > pkg_size)
			{
				memmove(pkg_data,pkg_data+pkg_size,s->recved-pkg_size);
			}
			s->recved -= pkg_size;
			if (s->recved == 0 && s->long_pkg != NULL)
			{
				free(s->long_pkg);
				s->long_pkg = NULL;
				s->long_pkg_size = 0;
			}
		}

	}
	//udp
	struct udp_recv_buf
	{
		char* recv_buf;
		size_t max_recv_len;
	};
	static void
		udp_uv_alloc_buf(uv_handle_t* handle,
						size_t suggested_size,
						uv_buf_t* buf)
	{
		suggested_size = (suggested_size < 8096) ? 8096 : suggested_size;
		struct udp_recv_buf* udp_buf = (struct udp_recv_buf*)handle->data;
		if (udp_buf->max_recv_len < suggested_size)
		{
			if (udp_buf->recv_buf)
			{
				free(udp_buf->recv_buf);
				udp_buf->recv_buf = NULL;
			}
			udp_buf->recv_buf = (char*)malloc(suggested_size);
			udp_buf->max_recv_len = suggested_size;
		}
		buf->base = udp_buf->recv_buf;
		buf->len = suggested_size;

	}
	static void
	uv_alloc_buf(uv_handle_t* handle,
				 size_t suggested_size,
				 uv_buf_t* buf)
	{
		uv_session* s = (uv_session*)handle->data;
		if (s->recved < RECV_LEN)//使用4k的存储空间 存储
		{
			*buf = uv_buf_init(s->recv_buf + s->recved, RECV_LEN - s->recved);//使用小缓存 地址在已经添加的地址之后到 RECV_LEN
		}
		else //超出4k后 动态分配存储空间
		{
			if (s->long_pkg == NULL)//超出 recved  继续收
			{
				if (s->socket_type == WS_SOCKET&&s->is_ws_shake) //ws && shake
				{
					int  pkg_size;
					int head_size;
					ws_protocol::read_ws_header((unsigned char*)s->recv_buf,s->recved,&pkg_size,&head_size);

					s->long_pkg_size = pkg_size;
					s->long_pkg = (char*)malloc(pkg_size);
					memcpy(s->long_pkg,s->recv_buf,s->recved);

				}
				else //tcp
				{
					int pkg_size;
					int head_size;
					tp_protocol::read_header((unsigned char*)s->recv_buf,s->recved,&pkg_size,&head_size);
					s->long_pkg_size = pkg_size;
					s->long_pkg = (char*)malloc(pkg_size);
					memcpy(s->long_pkg,s->recv_buf,s->recved);
				}
			}
			else
			{	//1、s->long_pkg+s->recved(地址移动到4500的位置 ) 2、 s->long_pkg_size-s->recved(5000-4500 剩余的500个字节放到long_pkg中)    --------s->recved:4500；s->long_pkg_size = 5000
				*buf = uv_buf_init(s->long_pkg+s->recved,s->long_pkg_size-s->recved);
			}
		}

	}

	static void
	on_close(uv_handle_t* handle) {
		uv_session* s = (uv_session*)handle->data;
		uv_session::destroy(s);
	}

	static void
	on_shutdown(uv_shutdown_t* req, int status) {
			uv_close((uv_handle_t*)req->handle, on_close);
	}

	///udp接受数据
	static void after_uv_udp_recv(uv_udp_t* handle,
								ssize_t nread,
								const uv_buf_t* buf,
								const struct sockaddr* addr,
								unsigned flags)
	{

		if (nread < 0)
		{
			return;
		}
		udp_session udp_s;

		udp_s.udp_handler = handle;
		udp_s.addr = addr;
		uv_ip4_name((struct sockaddr_in*)addr, udp_s.c_address, 32);
		udp_s.c_port = ntohs(((struct sockaddr_in*)addr)->sin_port);

		on_recv_client_command((session*)&udp_s, (unsigned char*)buf->base, nread);


	}

}
	static void
	after_read(uv_stream_t* stream,
	    	   ssize_t nread,
			   const uv_buf_t* buf) {

		uv_session* s = (uv_session*)stream->data;
		if (nread < 0) {
			s->close();
			return;
		}
		// end
		///记录session  的长度recved  增加
		s->recved += nread;
		if (s->socket_type == WS_SOCKET)
		{
			if (s->is_ws_shake==0)
			{
				if (ws_protocol::ws_shake_hand((session*)s, s->recv_buf, s->recved))
				{
					s->is_ws_shake = 1;
					s->recved = 0;
				}
			}
			else //接受数据
			{
				on_recv_ws_data(s);
			}
		}
		else //tcp
		{
			on_recv_tcp_data(s);
		}
	}
	///客户端连接成功
	static void
		uv_connection(uv_stream_t* server, int status) {
		//创建一个uv_session  用于存放client 句柄
		uv_session* s = uv_session::create();
		uv_tcp_t* client = &s->tcp_handler;
		memset(client, 0, sizeof(uv_tcp_t));///动态申请 内存空间

		///使用uv loop初始化一个连接client的线程  将session对象放到client data中 传出去
	    uv_tcp_init(uv_default_loop(), client);
		client->data = (void*)s;

		///开始连接 client
		uv_accept(server, (uv_stream_t*)client);

		//获取 ip
		struct sockaddr_in addr;
		int len = sizeof(addr);
	    uv_tcp_getpeername(client, (sockaddr*)&addr, &len);

		uv_ip4_name(&addr, (char*)s->c_address, 64);
		s->c_port = ntohs(addr.sin_port);
		s->socket_type = (int)(server->data);
		printf("new client comming %s:%d\n", s->c_address, s->c_port);
		
		///开始读取  客户端信息
		uv_read_start((uv_stream_t*)client, uv_alloc_buf, after_read);

	}


static netbus g_netbus;
netbus* netbus::instance() {
	return &g_netbus;
}
netbus::netbus()
{
	this->udp_handler = NULL;
}
void netbus::udp_listen(int port)
{
	if (this->udp_handler)
	{
		return;
	}
	uv_udp_t* server = (uv_udp_t*)malloc(sizeof(uv_udp_t));
	memset(server,0,sizeof(uv_udp_t));

	uv_udp_init(uv_default_loop(),server);
	struct udp_recv_buf* udp_buf = (struct udp_recv_buf*)malloc(sizeof(struct udp_recv_buf));
	memset(udp_buf, 0, (sizeof(struct udp_recv_buf)));
	server->data = (struct udp_recv_buf*)udp_buf;

	struct sockaddr_in addr;
	uv_ip4_addr("0.0.0.0",port,&addr);
	uv_udp_bind(server,(const struct sockaddr*)&addr,0);

	this->udp_handler = (void*)server;
	uv_udp_recv_start(server,udp_uv_alloc_buf,after_uv_udp_recv);
}

///监听 客户端连接
void netbus::tcp_listen(int port) {
	uv_tcp_t* listen = (uv_tcp_t*)malloc(sizeof(uv_tcp_t));
	memset(listen,0,sizeof(uv_tcp_t));

	uv_tcp_init(uv_default_loop(),listen);

	struct sockaddr_in addr;
	uv_ip4_addr("0.0.0.0",port,&addr);
	
	int ret = uv_tcp_bind(listen, (sockaddr*)&addr,0 );
	if (ret != 0)
	{
		printf("bind error\n");
		free(listen);
	}
	///开启监听
	uv_listen((uv_stream_t*)listen, SOMAXCONN, uv_connection);
	listen->data = (void*)TCP_SOCKET;
}
void netbus::ws_listen(int port) {
	uv_tcp_t* listen = (uv_tcp_t*)malloc(sizeof(uv_tcp_t));
	memset(listen, 0, sizeof(uv_tcp_t));

	uv_tcp_init(uv_default_loop(), listen);

	struct sockaddr_in addr;
	uv_ip4_addr("0.0.0.0", port, &addr);

	int ret = uv_tcp_bind(listen, (sockaddr*)&addr, 0);
	if (ret != 0)
	{
		printf("bind error\n");
		free(listen);
	}
	uv_listen((uv_stream_t*)listen, SOMAXCONN, uv_connection);
	listen->data = (void*)WS_SOCKET;
}


void netbus::run() {
	uv_run(uv_default_loop(), UV_RUN_DEFAULT);
}

void netbus::init()
{
	service_man::init();
	init_session_allocer();
}

struct connect_cb
{
	void(*on_connected)(int err,session* s,void* udata);
	void* udata;
};
///作为客户端 连接 服务器
static void 
after_connect(uv_connect_t* handle,int status)
{
	uv_session* s = (uv_session*)handle->handle->data;
	struct connect_cb* cb = (struct connect_cb*)handle->data ;

	if (status)
	{
		///回调上层 方法
		if (cb->on_connected)
		{
			cb->on_connected(1,NULL,cb->udata);
		}
		s->close();
		free(cb);
		free(handle);
		return;
	}
	//如果连接成功、
	if (cb->on_connected)
	{
		cb->on_connected(0,(session*)s,cb->udata);
	}
	uv_read_start((uv_stream_t*)handle->handle,uv_alloc_buf,after_read);
	free(cb);
	free(handle);

}
///开始连接 服务器
void  netbus::tcp_connect(const char* server_ip, int port,
	void(*on_connected)(int err, session* s, void* udata),
	void* udata)
{
	struct sockaddr_in bind_addr;
	int iret = uv_ip4_addr(server_ip,port,&bind_addr);
	if (iret)
	{
		return;
	}

	uv_session* s = uv_session::create();
	uv_tcp_t* client = &s->tcp_handler;
	memset(client,0,sizeof(uv_tcp_t));
	uv_tcp_init(uv_default_loop(),client);
	client->data = (void*)s;
	s->as_client = 1;
	s->socket_type = TCP_SOCKET;
	strcpy(s->c_address,server_ip);//服务器的ip
	s->c_port = port;

	uv_connect_t* connect_req = (uv_connect_t*)malloc(sizeof(uv_connect_t));
	struct connect_cb* cb = (struct connect_cb*)malloc(sizeof(struct connect_cb));
	cb->on_connected = on_connected;
	cb->udata = udata;
	connect_req->data = (void*)cb;

	iret = uv_tcp_connect(connect_req, client, (struct sockaddr*)&bind_addr, after_connect);
	if (iret)
	{
		return;
	}
}

///udp 发送数据
void netbus::udp_send_to(char* ip,int port,unsigned char* body,int len)
{
	uv_buf_t w_buf;

	w_buf = uv_buf_init((char*)body,len);
	uv_udp_send_t* req = (uv_udp_send_t*)small_alloc(sizeof(uv_udp_send_t));

	SOCKADDR_IN addr;
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr.S_un.S_addr = inet_addr(ip);

	uv_udp_send(req,(uv_udp_t*)this->udp_handler,&w_buf,1,(const sockaddr*)&addr,on_uv_udp_send_end);
}