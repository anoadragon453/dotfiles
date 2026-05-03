{ pkgs, pkgsUnstable, ... }:
{
  # Consolidate all rust build files into a single directory on disk, to prevent
  # duplicate built dependencies across different projects.
  programs.zed-editor = {
    enable = true;

    # Allow zed to download language servers on the fly.
    package = pkgsUnstable.zed-editor;

    extensions = [
      "nix"
    ];

    extraPackages = with pkgsUnstable; [
      go
      # Nix language server support
      # These must be manually installed.
      nixd nil
      openssl
      pkg-config
      
      # The pyrefly Python type-checker written in Rust.
      pyrefly
      ty
      
      yaml-language-server
      package-version-server
      vscode-json-languageserver
    ];

    userSettings = {
      autosave = {
        after_delay = {
          milliseconds = 500;
        };
      };
      agent = {
        default_model = {
          provider = "zed.dev";
          model = "claude-sonnet-4";
        };
        version = "2";
      };
      base_keymap = "JetBrains";
      languages = {
        Python = {
          # Prefer PyRight over pylsp.
          # PyRight has proper support for excluding directories from search
          # results.
          language_servers = ["ty" "!pyrefly" "!pyright" "!pylsp"];
        };
      };
      lsp = {
        rust-analyzer = {
          intialization_options = {
            cargo = {
              allTargets = false;
            };
          };
        };
        ty = {
          binary = {
            path = "/nix/store/zlaxrnmiqgxp64gyz33mv18dq1b583ag-ty-0.0.1-alpha.5/bin/ty";
            arguments = [ "server" ];
          };
        };
      };
      load_direnv = "direct";
      # Turn off real-time AI edit predictions.
      show_edit_predictions = false;
      ui_font_size = 18;
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
