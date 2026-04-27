import gruvbox
config.load_autoconfig()
# Tabs font
c.fonts.tabs.selected = "14pt monospace"
c.fonts.tabs.unselected = "14pt monospace"

# Statusbar font
c.fonts.statusbar = "14pt monospace"
c.tabs.padding = {'top': 6, 'bottom': 6, 'left': 8, 'right': 8}
c.statusbar.padding = {'top': 4, 'bottom': 4, 'left': 6, 'right': 6}
gruvbox.set(c, 'dark', 'hard') # options are dark/light and hard/medium/soft
