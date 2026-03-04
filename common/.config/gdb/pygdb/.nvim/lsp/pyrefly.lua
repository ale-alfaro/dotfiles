return {
	settings = {
		pyrefly = {
			extraPaths = {
				"/opt/zephyr-sdk-custom/arm-zephyr-eabi/share/gdb/python/gdb",
			},
			analysis = {
				inlayHints = {
					callArgumentNames = "off",
					functionReturnTypes = true,
					pytestParameters = false,
					variableTypes = true,
				},
				showHoverGoToLinks = true,
			},
		},
	},
}
