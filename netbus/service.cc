#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "session.h"
#include "proto_man.h"

#include "service.h"

service::service()
{
	this->using_raw_cmd = false;
}

// bool if return false, close socket
bool
service::on_session_recv_cmd(session* s, struct cmd_msg* msg) {
	return false;
}

void
service::on_session_disconnect(session* s,int stype) {

}
bool
service::on_session_recv_raw_cmd(session* s,struct raw_cmd* raw)
{
	return false;
}

void
service::on_session_connect(session* s, int stype) {

}