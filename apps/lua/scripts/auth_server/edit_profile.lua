
local mysql_center = require("database/mysql_auth_center")
local Respones = require("Respones")
local Stype = require("Stype")
local Cmd = require("Cmd")

-- {stype, ctype, utag, body}
function do_edit_profile(s, req) 
	local uid = req[3]
	local edit_profile_req = req[4]

	print("***do_edit_profile****")
	print(uid, edit_profile_req.unick, edit_profile_req.uface, edit_profile_req.usex)
	
	if (string.len(edit_profile_req.unick) <= 0) or 
	   (edit_profile_req.uface <= 0 or edit_profile_req.uface > 9) or 
	   (edit_profile_req.usex ~= 0 and edit_profile_req.usex ~= 1) then -- 参数错误
		local msg = {Stype.Auth, Cmd.eEditProfileRes, uid, {
			status = Respones.InvalidParams,
		}}

		Session.send_msg(s, msg)
		return
	end	

	-- 更新用户中心数据库
	local ret_handler = function(err, res)
		local ret_status = Respones.OK
		if err ~= nil then
			ret_status = Respones.SystemErr
		end

		--
		local msg = {Stype.Auth, Cmd.eEditProfileRes, uid, {
			status = ret_status,
		}}
		Session.send_msg(s, msg)
	end
	if mysql_center ==nil then
		print("mysql_center nil") 
	end
	if mysql_center.edit_profile ==nil then
		print("mysql_center.edit_profile nil") 
	end
	if ret_handler ==nil then
		print("ret_handler nil") 
	end
	mysql_center.edit_profile(uid, edit_profile_req.unick, edit_profile_req.uface, edit_profile_req.usex, ret_handler)
	-- redis_center.edit_profile(uid, edit_profile_req.unick, edit_profile_req.uface, edit_profile_req.usex)
	--  end
end

local edit_profile =
{
	do_edit_profile = do_edit_profile,
}
return edit_profile
