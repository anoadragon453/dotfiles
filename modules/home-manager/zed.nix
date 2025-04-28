{ pkgs, pkgsUnstable, ... }:
{
  # Consolidate all rust build files into a single directory on disk, to prevent
  # duplicate built dependencies across different projects.
  programs.zed-editor = {
    enable = true;

    # Allow zed to download language servers on the fly.
    # `zed-editor-fhs` is only available on nixos-unstable currently.
    package = pkgsUnstable.zed-editor-fhs;

    extensions = [
      "nix"
    ];

    # Only included in home-manager-unstable currently.
    # extraPackages = with pkgsUnstable; [
    #   go
    #   # Nix language server support
    #   # These must be manually installed.
    #   nixd nil
    #   openssl
    #   python313Packages.python-lsp-server
    # ];

    userSettings = {
      autosave = {
        after_delay = {
          milliseconds = 500;
        };
      };
      assistant = {
        default_model = {
          provider = "copilot_chat";
          model = "gpt-4o";
        };
        version = "2";
      };
      base_keymap = "JetBrains";
      load_direnv = "direct";
      # Turn off real-time AI edit predictions.
      show_edit_predictions = false;
      vim_mode = true;
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          # Toggle the terminal.
          "ctrl-`" = "workspace::ToggleBottomDock";
        };
      }
    ];
  };
}
