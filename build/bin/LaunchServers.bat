@echo 启动用户服务器。。
@start start_auth_server.bat
@sleep 1


@echo 启动系统服务器。。
@start start_system_server.bat
@sleep 1

@echo 启动逻辑服务器。。
@start  start_logic_server.bat
@sleep 1

@echo 启动网关服务器。。
@start  start_gateway.bat
@sleep 1

