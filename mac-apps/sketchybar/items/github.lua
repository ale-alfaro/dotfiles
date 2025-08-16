local settings = require("settings")
local icons = require("icons")
local colors = require("colors")

local github_bell = {
	item = {
		position = "right",
	},
	args = {
		update_freq = 180,
		icon = {
			font = {
				style = settings.font.style_map["Black"],
				size = 15.0,
			},
			string = icons.bell,
			color = colors.blue,
		},
		label = {
			string = icons.loading,
			highlight_color = colors.blue,
		},
		background = {
			padding_left = 10,
		},
		popup = {
			align = "right",
		},
		script = "plugins/github.sh",
		click_script = settings.popup_click_script,
	},
	subscribe = {
		"mouse.entered",
		"mouse.exited",
		"mouse.exited.global",
	},
}

local github_template = {
	item = {
		position = "popup.github.bell",
	},
	args = {
		drawing = "off",
		background = {
			corner_radius = 12,
			padding_left = 7,
			padding_right = 7,
			color = colors.black,
			drawing = "off",
		},
		icon = {
			background = {
				height = 2,
				y_offset = -12,
			},
		},
	},
}

return {
	template = github_template,
	bell = github_bell,
}
