-- WHAT THIS PLUGIN DOES:
-- An all inclusive plugin (i.e.you don't need to modify nothing on the outside) to link groups, group with BOTs and so on... be creative! :D
-- On the first use, just set variables "d_home_id" and "d_target_id" or simply set them with proper BOT's command (admin only) Enjoy :D
-- Put this plugin at the top of the list of active plugins.

-- TESTED ON:
-- TeleSeed (https://github.com/SEEDTEAM/TeleSeed)

-- Developed by @JuyceX.


d_home_id = 'user#id'..00000000 -- Id on which you wanna receive your messages.
d_target_id = 'user#id'..00000000 -- Id of group, BOT, user you wanna send indirectly messages.

do

local target_id, home_id, listen_media

local function get_receiver(msg)
	if msg.to.type == 'user' then
		return 'user#id'..msg.from.id
	elseif msg.to.type == 'chat' then
		return 'chat#id'..msg.to.id
	elseif msg.to.type == 'encr_chat' then
		return msg.to.print_name
	end
end

local function pre_process(msg)
	if not msg.text and msg.media then
		msg.text = '[media]'
	end
	return msg
end


local function update_bridge_status(home, target, listening)
	
	if not _config.bridge then
		_config.bridge = {}
	end
	
	bridge = _config.bridge
	
	bridge.home_id = home
	bridge.target_id = target
	bridge.listen_media = listening
	
	home_id = home
	target_id = target
	listen_media = listening
	
	save_config()
	
end

local function init_bridge_status()
	
	if not _config.bridge then
		target_id = d_target_id
		home_id = d_home_id
		listen_media = false
		
		update_bridge_status(home_id, target_id, listen_media)
	else
		target_id = _config.bridge.target_id
		home_id = _config.bridge.home_id
		listen_media = _config.bridge.listen_media
	end
	
end


local function run(msg, matches)

	init_bridge_status()

	--> BOT SETTINGS < --
	if is_sudo(msg) and matches[1] == '!target' or matches[1] == '!home' then
		local id
		if #matches == 3  then
			if matches[2] == '!!user' then
				id = 'user#id'..matches[3]
			elseif matches[2] == '!!group' then
				id = 'chat#id'..matches[3]
			else
				return 'Invalid chat type!'
			end
		elseif #matches == 1 then
			id = get_receiver(msg)
		end
		
		if matches[1] == '!home' then
			home_id = id
		elseif matches[1] == '!target' then
			target_id = id
		end
		update_bridge_status(home_id, target_id, listen_media)
		return 'Target: '..target_id ..'\nHome: '..home_id
	end
	
	-- > MESSAGES HANDLING < --
	if get_receiver(msg) == target_id then
	-- TARGET
		fwd_msg(home_id, msg.id, ok_cb, false)
		return
	elseif get_receiver(msg) == home_id then
	-- HOME
		if msg.media and listen_media == true then
		-- Medias
			result = fwd_msg(target_id, msg.id, ok_cb, false)
			if result then
				listen_media = false
				update_bridge_status(home_id, target_id, listen_media)
				return 'Media sent succesfully!'
			else
				return "An error occured during media sending. Please, retry."
			end
		else
		-- Plain Text
			if matches[1]:lower() == '//sendmedia' and listen_media == false then -- Send media request
				listen_media = true
				update_bridge_status(home_id, target_id, listen_media)
				return "Send me the media you wanna redirect on the other side."
			elseif matches[1]:lower() == '//cancelsending' and  listen_media == true then -- Cancel media request 
				listen_media = false
				update_bridge_status(home_id, target_id, listen_media)
				return "Ok, I won't send nothing on the other side."
			elseif matches[1]:sub(1,2) == '//' then 
				send_large_msg(target_id, matches[1]:sub(3, -1))
			end
		end
	end
end


return {
	patterns = {
		"^(!%w+) (!!%w+) (%d+)$",
		"(.+)"
	},
	run = run,
	pre_process = pre_process
}
end
