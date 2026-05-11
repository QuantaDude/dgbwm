local wezterm = require("wezterm")

return {
  -- Fast startup
  check_for_updates = false,
  automatically_reload_config = false,
  front_end = "WebGpu",

  -- Shell
  default_prog = { "/usr/bin/fish", "-l" },

  -- Font
  font = wezterm.font_with_fallback({
    "Fira Code"  }),

  font_size = 14,
  harfbuzz_features = {
    "calt=1",
    "clig=1",
    "liga=1",
  },

  -- Gruvbox
 color_scheme = 'Gruvbox dark, soft (base16)',

  -- Hide top bar / tabs
  enable_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,
  window_decorations = "RESIZE",

  -- Performance tweaks
  max_fps = 60,
  animation_fps = 1,
  cursor_blink_rate = 0,

  -- Reduce input lag
  enable_wayland = false,

  -- Padding
  window_padding = {
    left = 6,
    right = 6,
    top = 4,
    bottom = 2,
  },

  -- Scrollback
  scrollback_lines = 5000,

  -- Startup size
  initial_cols = 120,
  initial_rows = 32,

  -- Clean cursor
  default_cursor_style = "BlinkingBlock",

  -- Less GPU memory weirdness
  webgpu_power_preference = "HighPerformance",
}
