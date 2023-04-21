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
      (vscode-with-extensions.override {
        vscode = vscode;
        vscodeExtensions = with vscode-extensions; [
          bungcip.better-toml
          golang.go
          jnoortheen.nix-ide
          mkhl.direnv
          rust-lang.rust-analyzer
          serayuzgur.crates
          timonwong.shellcheck
          vadimcn.vscode-lldb
          vscodevim.vim
          waderyan.gitblame
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [];
      })
    ];
  };
}
