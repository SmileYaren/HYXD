local mysql_center = require("database/mysql_auth_center")
local redis_center = require("database/redis_center")

local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")

function login(s,req)
	-- body
	local utag = req[3]
	local uname_login_req = req[4]
	if string.len(uname_login_req.uname)<=0 or 
		string.len(uname_login_req.upwd)~=32 then
		local msg = {Stype.Auth,Cmd.eUnameLoginRes,utag,{
			status = Respones.InvalidParams
		}}
		Session.send_msg(s,msg)
		return
	end
	mysql_center.get_uinfo_by_uname_upwd(uname_login_req.uname,uname_login_req.upwd,function ( err,uinfo )
		-- body
		if err then
			local msg = {Stype.Auth,Cmd.eUnameLoginRes,utag,{
				status = Respones.SystemErr,
			}}
			Session.send_msg(s,msg)
			return
		end

		if uinfo== nil then  --用户名密码错误
			local msg = {Stype.Auth,Cmd.eUnameLoginRes,utag,{
				status = Respones.UnameOrUpwdError,
			}}
			Session.send_msg(s,msg)
			return
		end
		if uinfo.status~=0 then  --账号被查封
			local msg = {Stype.Auth,Cmd.eUnameLoginRes,utag,{
				status = Respones.UserIsFreeze,
			}}
			Session.send_msg(s,msg)
			return
		end
		---redis center 存储 用户信息
		redis_center.set_uinfo_inredis(uinfo.uid,uinfo)
	
		local msg = { Stype.Auth, Cmd.eUnameLoginRes, utag, {
			status = Respones.OK,
			uinfo = {
				unick = uinfo.unick,
				uface = uinfo.uface,
				usex  = uinfo.usex,
				uvip  = uinfo.uvip,
				uid = uinfo.uid, 
			}
		}}
		Session.send_msg(s, msg)
		print("user login sucess!:",uinfo.unick,uinfo.uface,uinfo.usex,uinfo.uvip,uinfo.uid)
	end)
end
uname_login = {
	login = login,
}
return uname_login