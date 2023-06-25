{pkgs, config, lib, ...}:
with lib;
let
  xorg = (elem "xorg" config.sys.hardware.graphics.desktopProtocols);
  wayland = (elem "wayland" config.sys.hardware.graphics.desktopProtocols);
  desktopMode = xorg || wayland;
in {
  config = mkIf desktopMode {
    # Install VSCode with FHS support (such that binaries bundled in extensions
    # don't need to be patched to point to NixOS-compatible paths).
    sys.software = with pkgs; [
      # Install VSCode and fetch various extensions from nixpkgs.
      (vscode-with-extensions.override {
        vscode = vscode;
        vscodeExtensions = with vscode-extensions; [
          bungcip.better-toml
          golang.go
          jnoortheen.nix-ide
          jock.svg
          mkhl.direnv
          rust-lang.rust-analyzer
          serayuzgur.crates
          svelte.svelte-vscode
          timonwong.shellcheck
          vadimcn.vscode-lldb
          vscodevim.vim
          waderyan.gitblame
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # Take quick markdown notes in the sidebar.
          # https://marketplace.visualstudio.com/items?itemName=assisrMatheus.sidebar-markdown-notes
          {
            name = "sidebar-markdown-notes";
            publisher = "assisrmatheus";
            version = "1.0.4";
            sha256 = "sha256-shqLyJWmRNfi441yErSuDM4wei/XD/MCnz/08wqEHH8=";
          }
        ];
      })
    ];
  };
}
