{ config, pkgs, pkgsUnstable, ... }:
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
      nixd
      nil
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
        sandbox_permissions = {
          write_paths = [
            # Set the config separately for each user.
            #
            # If we put a directory for one user in the config for another, Zed
            # will complain when executing its AI agent, as when building the
            # sandbox it will try to check that each configured allowed
            # directory exists. And it can't do that for those in other users'
            # home directory's, which it can't read.
            "${config.home.homeDirectory}/.cargo/target"
          ];
        };
        default_model = {
          provider = "openai-subscribed";
          speed = "fast";
          effort = "xhigh";
          enable_thinking = true;
          model = "gpt-5.6-sol";
        };
      };
      base_keymap = "VSCode";
      languages = {
        Python = {
          # Prefer PyRight over pylsp.
          # PyRight has proper support for excluding directories from search
          # results.
          language_servers = [
            "basedpyright"
            "!ty"
            "!pyrefly"
            "!pyright"
            "!pylsp"
          ];
        };
      };
      lsp = {
        ty = {
          binary = {
            path = "/nix/store/zlaxrnmiqgxp64gyz33mv18dq1b583ag-ty-0.0.1-alpha.5/bin/ty";
            arguments = [ "server" ];
          };
        };
      };
      load_direnv = "shell_hook";
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

    userTasks = [
      {
        "label" = "copy .envrc into new worktree";
        "command" = "cp";
        "args" = [
          "$ZED_MAIN_GIT_WORKTREE/.envrc"
          "$ZED_WORKTREE_ROOT/.envrc"
        ];
        "hooks" = ["create_worktree"];
        "reveal" = "no_focus";
        "hide" = "on_success";
      }
      {
        "label" = "auto `direnv allow` the new .envrc file";
        "command" = "direnv";
        "args" = [
          "allow"
        ];
        "hooks" = ["create_worktree"];
        "reveal" = "no_focus";
        "hide" = "on_success";
      }
    ];
  };
}
