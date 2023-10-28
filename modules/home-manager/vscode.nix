{ lib, osConfig, pkgs, ... }:
{
  programs.vscode = lib.mkIf (builtins.length osConfig.sys.hardware.graphics.desktopProtocols != 0) {
    enable = true;

    # A minur (-) before a command disables that command.
    keybindings = [
      # Disable the vim extension's control over the Ctrl+P shortcut, such that it
      # falls through to the file search.
      {
        key = "ctrl+p";
        command = "-extension.vim_ctrl+p";
      }
      # Disable the editor's Ctrl+E shortcut, such that Ctrl+E goes to the end of
      # the line in the terminal.
      {
        key = "ctrl+e";
        command = "-workbench.action.quickOpen";
      }
    ];

    # The VSCode extensions to install.
    # Extensions come from nixpkgs.
    extensions = with pkgs.vscode-extensions; [
      golang.go
      jnoortheen.nix-ide
      jock.svg
      mkhl.direnv
      rust-lang.rust-analyzer
      serayuzgur.crates
      streetsidesoftware.code-spell-checker
      svelte.svelte-vscode
      tamasfe.even-better-toml
      timonwong.shellcheck
      vadimcn.vscode-lldb
      vscodevim.vim
      waderyan.gitblame
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "dragon-jinja";
        publisher = "hongquan";
        version = "0.21.3";
        sha256 = "sha256-uPhkazR1qhOeN+sWBEQbh6nDN4pUwUaxwAVI7vqkf9c=";
      }
    ];

    # Don't allow vscode to update extensions.
    mutableExtensionsDir = false;

    userSettings = {
      # Automatically save files after editing has ceased for a few moments.
      "files.autoSave" = "afterDelay";

      # Show the welcome page on startup.
      "workbench.startupEditor" = "welcomePage";
      
      # Disable telemetry other than crash reports.
      "telemetry.telemetryLevel" = "crash";

      # Don't show release notes after every update.
      "update.showReleaseNotes" = false;

      # Ignore leading and trailing whitespace changes in the diff editor.
      "diffEditor.ignoreTrimWhitespace" = false;

      # Nicer title bar with more options.
      "window.titleBarStyle" = "custom";

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      # Auto-download nix flake archives. Without this, the Nix-IDE
      # extension will ask to do so every time a flake input changes.
      "nix.serverSettings" = {
        "nil" = {
          "nix" = {
            "flake" = {
              "autoArchive" = true;
            };
          };
        };
      };

      # Additional words to ignore for spell-checking.
      "cSpell.userWords" = [
        "actix"
      ];
    };
  };
}
