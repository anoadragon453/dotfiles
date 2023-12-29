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
      # Disable the vim extension's control over the Ctrl+B shortcut, such that it
      # falls through to the default action of opening and closing the file browser.
      {
        key = "ctrl+b";
        command = "-extension.vim_ctrl+b";
        when = "editorTextFocus && vim.active && vim.use<C-b> && !inDebugRepl && vim.mode != 'Insert'";
      }
    ];

    # The VSCode extensions to install.
    # Extensions come from nixpkgs.
    extensions = with pkgs.vscode-extensions; [
      golang.go
      jnoortheen.nix-ide
      jock.svg
      mkhl.direnv
      ms-vscode-remote.remote-ssh
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

      # Allow breakpoints to be set in any file.
      "debug.allowBreakpointsEverywhere" = true;

      # Turn off extension recommendation pop-ups.
      "extensions.ignoreRecommendations" = true;
      "lldb.suppressUpdateNotifications" = true;

      # Show inline suggestions in the editor.
      "editor.inlineSuggest.enabled" = true;

      # Format files upon saving them.
      "editor.formatOnSave" = true;
      
      # Disable telemetry other than crash reports.
      "telemetry.telemetryLevel" = "crash";

      # Don't show release notes after every update.
      "update.showReleaseNotes" = false;

      # Don't check for updates, as we'll update through our package manager anyhow.
      "update.mode" = "none";

      # Ignore leading and trailing whitespace changes in the diff editor.
      "diffEditor.ignoreTrimWhitespace" = false;

      # Nicer title bar with more options.
      "window.titleBarStyle" = "custom";
      "window.menuBarVisibility" = "toggle";
      "window.zoomLevel" = -1;

      # Don't ask for confirmation when moving files via drag-and-drop.
      "explorer.confirmDragAndDrop" = false;

      # Automatically restart the extension host when direnv detects a change in
      # the environment. This prevents annoying manual extension restart messages
      # from constantly popping up while changing flake files.
      "direnv.restart.automatic" = true;

      # Settings for the nix language server.
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings" = {
        "nil" = {
          "nix" = {
            "flake" = {
              # Auto-download nix flake archives. Without this, the Nix-IDE
              # extension will ask to do so every time a flake input changes.
              "autoArchive" = true;
            };
          };
        };
      };

      # Give the integrated terminal much more scrollback.
      "terminal.integrated.scrollback" = "100000";

      # Additional words to ignore for spell-checking.
      "cSpell.userWords" = [
        "actix"
        "homeserver"
        "protobuf"
        "protobufs"
        "shortcode"
      ];

      # Allow British English words as well as American.
      "cSpell.language" = "en,en-GB";

      # Additional filetypes to be spell-checked.
      "cSpell.enableFileTypes" = [
        "nix"
      ];

      # Show some lifetime elision hints in the editor, but not the trivial ones.
      "rust-analyzer.inlayHints.lifetimeElisionHints.enable" = "skip_trivial";
    };
  };
}
