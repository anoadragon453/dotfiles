{ lib, osConfig, ... }:
{
  programs.alacritty = lib.mkIf (builtins.length osConfig.sys.hardware.graphics.desktopProtocols != 0) {
    enable = true;

    settings = {
      env = {
        # TODO: Necessary?
        TERM = "xterm-256color";
      };

      window = {
        # Show some of the content behind the terminal window.
        opacity = 0.95;
        
        # Add a tiny bit of padding around the terminal content.
        padding = {
          x = 5;
          y = 5;
        };
      };

      scrolling = {
        # All the scrollback!
        history = 10000;

        # How quickly to scroll the terminal window per wheel tick.
        multiplier = 3;
      };

      colors = {
        # Make bold text slightly more noticeable.
        draw_bold_text_with_bright_colors = true;
      };
    };
  };
}