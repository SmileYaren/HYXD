@echo �����û�����������
@start start_auth_server.bat
@sleep 1


@echo ����ϵͳ����������
@start start_system_server.bat
@sleep 1

@echo �����߼�����������
@start  start_logic_server.bat
@sleep 1

@echo �������ط���������
@start  start_gateway.bat
@sleep 1

