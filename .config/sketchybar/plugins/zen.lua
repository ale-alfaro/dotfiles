return function(state)
	local drawing_state = state == "on" and "off" or "on"

	return {
		{ "github.bell", { drawing = drawing_state } },
		{ "apple.logo", { drawing = drawing_state } },
		{ "/cpu.*/", { drawing = drawing_state } },
		{ "calendar", { icon = { drawing = drawing_state } } },
		{ "system.yabai", { drawing = drawing_state } },
		{ "separator", { drawing = drawing_state } },
		{ "front_app", { drawing = drawing_sttate } },
		{ "spotify.play", { updates = state == "on" and "off" or "on" } },
		{ "spotify.title", { drawing = drawing_state } },
		{ "spotify.artist", { drawing = drawing_state } },
	}
end
