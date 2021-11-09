{pkgs, config, lib, ...}:
with lib;
with builtins;
let
  xorg = (elem "xorg" config.sys.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
  cfg = config.sys.desktop.rofi;
in {
  options.sys.desktop.rofi = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Rofi";
    };
  };

  config = mkIf (cfg.enable && desktopMode) {

    environment.systemPackages = with pkgs; [
      rofi
    ];

    sys.users.allUsers.files = {
      roficonfig = {
        path = ".config/rofi/config.rasi";
        text = ''
          /*Dracula theme based on the Purple official rofi theme*/

          * {
              font: "Jetbrains Mono 12";
              foreground: #f8f8f2;
              background: #282a36;
              active-background: #6272a4;
              urgent-background: #ff5555;
              selected-background: @active-background;
              selected-urgent-background: @urgent-background;
              selected-active-background: @active-background;
              separatorcolor: @active-background;
              bordercolor: @active-background;
          }

          #window {
              background-color: @background;
              border:           1;
              border-radius: 6;
              border-color: @bordercolor;
              padding:          5;
          }
          #mainbox {
              border:  0;
              padding: 0;
          }
          #message {
              border:       1px dash 0px 0px ;
              border-color: @separatorcolor;
              padding:      1px ;
          }
          #textbox {
              text-color: @foreground;
          }
          #listview {
              fixed-height: 0;
              border:       2px dash 0px 0px ;
              border-color: @bordercolor;
              spacing:      2px ;
              scrollbar:    false;
              padding:      2px 0px 0px ;
          }
          #element {
              border:  0;
              padding: 1px ;
          }
          #element.normal.normal {
              background-color: @background;
              text-color:       @foreground;
          }
          #element.normal.urgent {
              background-color: @urgent-background;
              text-color:       @urgent-foreground;
          }
          #element.normal.active {
              background-color: @active-background;
              text-color:       @foreground;
          }
          #element.selected.normal {
              background-color: @selected-background;
              text-color:       @foreground;
          }
          #element.selected.urgent {
              background-color: @selected-urgent-background;
              text-color:       @foreground;
          }
          #element.selected.active {
              background-color: @selected-active-background;
              text-color:       @foreground;
          }
          #element.alternate.normal {
              background-color: @background;
              text-color:       @foreground;
          }
          #element.alternate.urgent {
              background-color: @urgent-background;
              text-color:       @foreground;
          }
          #element.alternate.active {
              background-color: @active-background;
              text-color:       @foreground;
          }
          #scrollbar {
              width:        2px ;
              border:       0;
              handle-width: 8px ;
              padding:      0;
          }
          #sidebar {
              border:       2px dash 0px 0px ;
              border-color: @separatorcolor;
          }
          #button.selected {
              background-color: @selected-background;
              text-color:       @foreground;
          }
          #inputbar {
              spacing:    0;
              text-color: @foreground;
              padding:    1px ;
          }
          #case-indicator {
              spacing:    0;
              text-color: @foreground;
          }
          #entry {
              spacing:    0;
              text-color: @foreground;
          }
          #prompt {
              spacing:    0;
              text-color: @foreground;
          }
          #inputbar {
              children:   [ prompt,textbox-prompt-colon,entry,case-indicator ];
          }
          #textbox-prompt-colon {
              expand:     false;
              str:        ":";
              margin:     0px 0.3em 0em 0em ;
              text-color: @foreground;
          }
        '';
      };
    };
  };
}
