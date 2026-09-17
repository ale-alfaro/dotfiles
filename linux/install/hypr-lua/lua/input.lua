-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "us",
    kb_options = "compose:caps",
    numlock_by_default = true,
    repeat_delay = 250,
    repeat_rate = 35,

    follow_mouse = 1,
    sensitivity = 0.35, -- -1.0 to 1.0, 0 means no modification

    touchpad = {
      natural_scroll = true,
      -- disable_while_typing = true,
    },
  },

  binds = {
    scroll_event_delay = 0,
    hide_special_on_workspace_change = true,
  },
})
