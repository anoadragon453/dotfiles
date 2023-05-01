{...}:
{
  config = {
    # Create a new desktop entry for xterm in the user's home directory that prevents it
    # from appears in Desktop Environment's application's menu.
    # This is motivated by xterm coming up as the first result when search from 'term'.
    sys.user.allUsers.files = {
      xtermDesktopEntryNoDisplay = {
        path = ".local/share/applications/xterm.desktop";
        # Copied from the upstream xterm package, with a 'NoDisplay=true' line
        # added at the end.
        text = ''
        [Desktop Entry]
        Type=Application
        Name=XTerm
        Comment=Standard terminal emulator for the X window system
        TryExec=xterm
        Exec=xterm
        Icon=xterm-color_48x48
        Terminal=false
        Categories=System;TerminalEmulator;
        Keywords=terminal;emulator;
        ### This is the crucial line ###
        NoDisplay=true
        '';
      };
    };
  };
}
