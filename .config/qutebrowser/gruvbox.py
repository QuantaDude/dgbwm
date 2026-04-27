def get_pallet(scheme='dark', intensity='hard'):
    if scheme not in ('dark', 'light'):
        raise RuntimeError('Scheme must be one of "dark", "light".')
    if intensity not in ('hard', 'medium', 'soft'):
        raise RuntimeError('Intensity must be one of "hard", "medium", "soft".')

    if scheme == 'dark':
        pallet = {
            'fg': '#ebdbb2',
            'red': '#fb4934',
            'orange': '#fe8019',
            'yellow': '#fabd2f',
            'green': '#b8bb26',
            'aqua': '#8ec07c',
            'blue': '#83a598',
            'purple': '#d3869b',
            'grey0': '#928374',
            'grey1': '#a89984',
            'grey2': '#bdae93',
            'statusline1': '#b8bb26',
            'statusline2': '#ebdbb2',
            'statusline3': '#fb4934',
        }

        if intensity == 'hard':
            pallet.update({
                'bg_dim': '#1d2021',
                'bg0': '#1d2021',
                'bg1': '#282828',
                'bg2': '#32302f',
                'bg3': '#3c3836',
                'bg4': '#504945',
                'bg5': '#665c54',
                'bg_visual': '#3c3836',
                'bg_red': '#3c1f1e',
                'bg_green': '#2e3b1e',
                'bg_blue': '#1e2f3b',
                'bg_yellow': '#3b3320',
            })
        elif intensity == 'medium':
            pallet.update({
                'bg_dim': '#282828',
                'bg0': '#282828',
                'bg1': '#32302f',
                'bg2': '#3c3836',
                'bg3': '#504945',
                'bg4': '#665c54',
                'bg5': '#7c6f64',
                'bg_visual': '#3c3836',
                'bg_red': '#4b2c2b',
                'bg_green': '#3b4b2b',
                'bg_blue': '#2b3b4b',
                'bg_yellow': '#4b432b',
            })
        else:  # soft
            pallet.update({
                'bg_dim': '#32302f',
                'bg0': '#32302f',
                'bg1': '#3c3836',
                'bg2': '#504945',
                'bg3': '#665c54',
                'bg4': '#7c6f64',
                'bg5': '#928374',
                'bg_visual': '#504945',
                'bg_red': '#5a3a39',
                'bg_green': '#4a5a39',
                'bg_blue': '#394a5a',
                'bg_yellow': '#5a5239',
            })

    else:
        # Gruvbox light
        pallet = {
            'fg': '#3c3836',
            'red': '#cc241d',
            'orange': '#d65d0e',
            'yellow': '#d79921',
            'green': '#98971a',
            'aqua': '#689d6a',
            'blue': '#458588',
            'purple': '#b16286',
            'grey0': '#7c6f64',
            'grey1': '#928374',
            'grey2': '#a89984',
            'statusline1': '#98971a',
            'statusline2': '#3c3836',
            'statusline3': '#cc241d',
        }

        if intensity == 'hard':
            pallet.update({
                'bg_dim': '#f9f5d7',
                'bg0': '#fbf1c7',
                'bg1': '#f2e5bc',
                'bg2': '#ebdbb2',
                'bg3': '#e0cfa9',
                'bg4': '#d5c4a1',
                'bg5': '#bdae93',
                'bg_visual': '#ebdbb2',
                'bg_red': '#f2c7c5',
                'bg_green': '#e6e8c5',
                'bg_blue': '#d5e3e8',
                'bg_yellow': '#f3e1a6',
            })
        elif intensity == 'medium':
            pallet.update({
                'bg_dim': '#f2e5bc',
                'bg0': '#fbf1c7',
                'bg1': '#ebdbb2',
                'bg2': '#e0cfa9',
                'bg3': '#d5c4a1',
                'bg4': '#bdae93',
                'bg5': '#a89984',
                'bg_visual': '#ebdbb2',
                'bg_red': '#f2c7c5',
                'bg_green': '#e6e8c5',
                'bg_blue': '#d5e3e8',
                'bg_yellow': '#f3e1a6',
            })
        else:
            pallet.update({
                'bg_dim': '#ebdbb2',
                'bg0': '#f2e5bc',
                'bg1': '#e0cfa9',
                'bg2': '#d5c4a1',
                'bg3': '#bdae93',
                'bg4': '#a89984',
                'bg5': '#928374',
                'bg_visual': '#e0cfa9',
                'bg_red': '#f2c7c5',
                'bg_green': '#e6e8c5',
                'bg_blue': '#d5e3e8',
                'bg_yellow': '#f3e1a6',
            })

    return pallet
def set(c, scheme='dark', intensity='hard'):
    t = get_pallet(scheme, intensity)

    c.colors.webpage.bg = t['bg0']

    c.colors.keyhint.fg = t['fg']
    c.colors.keyhint.suffix.fg = t['red']

    c.colors.messages.error.bg = t['bg_red']
    c.colors.messages.error.fg = t['fg']
    c.colors.messages.info.bg = t['bg_blue']
    c.colors.messages.info.fg = t['fg']
    c.colors.messages.warning.bg = t['bg_yellow']
    c.colors.messages.warning.fg = t['fg']

    c.colors.prompts.bg = t['bg0']
    c.colors.prompts.fg = t['fg']

    c.colors.completion.category.bg = t['bg0']
    c.colors.completion.category.fg = t['fg']
    c.colors.completion.fg = t['fg']
    c.colors.completion.even.bg = t['bg0']
    c.colors.completion.odd.bg = t['bg1']
    c.colors.completion.match.fg = t['red']
    c.colors.completion.item.selected.fg = t['fg']
    c.colors.completion.item.selected.bg = t['bg3']
    c.colors.completion.item.selected.border.top = t['bg3']
    c.colors.completion.item.selected.border.bottom = t['bg3']

    c.colors.completion.scrollbar.bg = t['bg_dim']
    c.colors.completion.scrollbar.fg = t['fg']

    c.colors.hints.bg = t['bg0']
    c.colors.hints.fg = t['fg']
    c.colors.hints.match.fg = t['red']
    c.hints.border = '0px solid black'

    c.colors.statusbar.normal.fg = t['fg']
    c.colors.statusbar.normal.bg = t['bg1']

    c.colors.statusbar.insert.fg = t['bg0']
    c.colors.statusbar.insert.bg = t['statusline1']

    c.colors.statusbar.command.fg = t['fg']
    c.colors.statusbar.command.bg = t['bg0']

    c.colors.statusbar.url.error.fg = t['orange']
    c.colors.statusbar.url.fg = t['fg']
    c.colors.statusbar.url.hover.fg = t['blue']
    c.colors.statusbar.url.success.http.fg = t['green']
    c.colors.statusbar.url.success.https.fg = t['green']

    c.colors.tabs.bar.bg = t['bg_dim']
    c.colors.tabs.even.bg = t['bg0']
    c.colors.tabs.odd.bg = t['bg0']
    c.colors.tabs.even.fg = t['fg']
    c.colors.tabs.odd.fg = t['fg']
    c.colors.tabs.selected.even.bg = t['orange']
    c.colors.tabs.selected.odd.bg = t['yellow']
    c.colors.tabs.selected.even.fg = t['bg0']
    c.colors.tabs.selected.odd.fg = t['bg0']
    c.colors.tabs.indicator.start = t['blue']
    c.colors.tabs.indicator.stop = t['green']
    c.colors.tabs.indicator.error = t['red']
