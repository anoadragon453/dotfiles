# Builds a development shell with all the dependencies necessary to bootstrap
# install/update NixOS locally, or to deploy NixOS on a remote system (using
# deploy-rs). Secret management (encryption/decryption) is made possible by
# sops and sops-nix.
{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  name = "nixosbuildshell";

  # Native dependencies to install.
  nativeBuildInputs = with pkgs; [
    deploy-rs
    git
    nixFlakes
    pciutils  # to figure out sound card PCI ID
    sops
    starship
  ];

  # ASCII art unicorn (slightly modified) originally by snd at https://ascii.co.uk/art/unicorn.
  shellHook = ''
    # Start the starship shell.
    eval "$(starship init $(echo $0))"

    # Print development environment greeting.
    echo '
                                                                  / ･.*･｡ﾟ
                                                              ;==,_  
                                                            S" .--` 
                                                            sS  \__  
                                                        __.` ( \--> 
                                                      _=/    _./-\/  
                                                    ((\( /-`   -`l  
                                                      ) |/ \\    
                                                        \\  \\
    Welcome to the anoa NixOS flake development shell!    ~   ~
    '
    echo 'You can apply this flake to your system with: `nixos-rebuild switch --flake .#<system name>`'
    echo 'Deploy this flake to other systems using: `deploy [--targets .#<system name1> .#<system name2>...]`'

    # Configure nix with experimental flake support.
    PATH=${pkgs.writeShellScriptBin "nix" ''
      ${pkgs.nixFlakes}/bin/nix --experimental-features "nix-command flakes" "$@"
    ''}/bin:$PATH
  '';
  }
