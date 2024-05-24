local vot_cli_path = "vot-cli"

local continue_trans = false
local enabled = false
local last_path = ""


local settings = {
	load_key = "y",
	lang = "ru"
}

local opts = require("mp.options")
opts.read_options(settings, "vot-mpv", function(list) update_opts(list) end)


function update_opts(changelog)
	settings.load_key = changelog.load_key
	settings.lang = changelog.lang
end

function get_path(path)
	path = path:gsub("https://youtu.be/", "https://www.youtube.com/watch?v=")
	path = path:gsub("ytdl://", "https://www.youtube.com/watch?v=")

	local handle = io.popen(vot_cli_path .. " " .. path .. " --reslang " .. settings.lang)

	new_path = handle:read('*a')
	new_path = string.match(new_path, "https://vtrans[^%s]+")
	new_path = new_path:sub(1, -2)
	return new_path
end

function load_toggle()
	if last_path == "" then
		last_path = tostring(mp.get_property("path"))
	elseif not (last_path == tostring(mp.get_property("path"))) then
		last_path = tostring(mp.get_property("path"))
		enabled = false
	end

	if enabled then
		mp.command("set lavfi-complex ''")
		mp.set_property("audio", 1)
	else
		mp.osd_message("Getting a link: " .. last_path)

		local result_path = get_path(last_path)

		mp.osd_message("link received: " .. result_path)
		mp.command("audio-add '" .. result_path .. "'")

		mp.command("set lavfi-complex '[aid1]volume=0.2[vol1];[aid2]volume=1[vol2];[vol1][vol2]amix[ao]'")
	end

	enabled = not enabled
end

function load_next()
	if continue_trans then
		load_toggle()
	end
end

function upload()
	continue_trans = enabled

	enabled = false
	last_path = ""

	mp.command("set lavfi-complex ''")
	mp.set_property("audio", 1)

end

mp.register_event("file-loaded", load_next)
mp.register_event("end-file", upload)

mp.add_key_binding(settings.load_key, "load_toggle", load_toggle)
