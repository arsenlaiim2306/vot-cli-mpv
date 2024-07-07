local vot_cli_path = "vot-cli"
local from_languages = {"ru", "en", "zh", "ko", "ar", "fr", "it", "es", "de", "ja"}
local to_languages = {"ru", "en", "kk"}

local continue_trans = false
local enabled = false
local last_path = ""
local selected_from = 2
local selected_to = 1

function load_options()
    local options = {
        toggle_key = "y",
        select_from_key = "'",
        select_to_key = "\\"
    }

    local opt = require 'mp.options'
    opt.read_options(options, "vot_translate")

    return options
end

function get_path(path, from, to)
	path = path:gsub("https://youtu.be/", "https://www.youtube.com/watch?v=")
	path = path:gsub("ytdl://", "https://www.youtube.com/watch?v=")

	local handle = io.popen(vot_cli_path .. " " .. path .. " --lang " .. from .. " --reslang " .. to)

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

		local result_path = get_path(last_path, from_languages[selected_from], to_languages[selected_to])

		mp.osd_message("link received: " .. result_path)
		mp.command("audio-add '" .. result_path .. "'")

		mp.command("set lavfi-complex '[aid1]volume=0.2[vol1];[aid2]volume=1[vol2];[vol1][vol2]amix[ao]'")
	end

	enabled = not enabled
end

function selecting_from_lang()
	selected_from = selected_from + 1
	if selected_from > #from_languages then
		selected_from = 1
	end
	mp.osd_message("Video language: " .. from_languages[selected_from])
end

function selecting_to_lang()
	selected_to = selected_to + 1
	if selected_to > #to_languages then
		selected_to = 1
	end
	mp.osd_message("Result language: " .. to_languages[selected_to])
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

local options = load_options()

mp.register_event("file-loaded", load_next)
mp.register_event("end-file", upload)

mp.add_key_binding(options.toggle_key, load_toggle)
mp.add_key_binding(options.select_from_key, selecting_from_lang)
mp.add_key_binding(options.select_to_key, selecting_to_lang)
