-- Machine-specific. Delete this file on a host that doesn't want it; the entry
-- point loads it optionally.

-- NVIDIA
hl.env("NVD_BACKEND", "direct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- GTK only honors whole numbers, and XWayland windows are sized by it.
hl.env("GDK_SCALE", "2")

-- https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
