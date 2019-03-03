local mysql_center = require("database/mysql_auth_center")
local redis_center = require("database/redis_center")

local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")
--升级账号
function _do_account_upgrade(s,req,uid,uname,upwd_md5)
	mysql_center.do_account_upgrade(uid,uname,upwd_md5,function(err,ret)
		if err then
			local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status = Respones.SystemErr
			}}
			Session.send_msg(s,msg)
			return
		end
			local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status.Respones.OK,
			}}
		end)
end

--检查是否为游客
function _check_is_guest(s,req,uid,uname,upwd_md5)

	mysql_center.get_uinfo_by_uid(uid,function (err,uinfo)
		-- body
		if err then
			local msg ={Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status = Respones.SystemErr
			}}
			Session.send_msg(s,msg)
			return
		end
		if uinfo.is_guest~=1 then --不是游客
			local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status = Respones.SystemErr
			}}
			Session.send_msg(s,msg)
		end
		--升级账号
	_do_account_upgrade(s,req,uid,uname,upwd_md5)
	end)
end

--更新账号密码 
function do_upgrade(s,req)
	-- body
	local uid = req[3]--utag
	local account_upgrade_req = req[4]

	local uname = account_upgrade_req.uname
	local upwd_md5 = account_upgrade_req.upwd_md5

	if string.len(uname)<=0 or string.len(upwd_md5)~=32 then
		local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
			status = Respones.InvalidParams,
		}}
		Session.send_msg()
	end

	mysql_center.check_uname_exist(uname,function (err,ret)
		-- body
		if err then
			local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status = Respones.SystemErr,
			}}
			Session.send_msg(s,msg)
			return
		end
		if ret then  --uname 重复
			local msg = {Stype.Auth,Cmd.eAccountUpgradeRes,uid,{
				status.Respones.UnameIsExist,
			}}
			Session.send_msg(s,msg)
			return
		end
		_check_is_guest(s,req,uid,uname,upwd_md5)
	end)
end

local account_upgrade = 
{
	do_upgrade = do_upgrade,
}
return account_upgrade