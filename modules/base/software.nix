{pkgs, ...}:
{
    # This is a list of cli tools that should be present on all of my systems,
    # regardless of whether they have a GUI configured or not.
    sys.software = with pkgs; [
        # Misc cli tools
        bat
        bintools
        bottom
        devenv
        distrobox
        docker-compose
        dnsutils
        file
        fd
        ffmpeg
        gdb
        gdu
        ghostscript
        gnumake
        gnupg
        htop
        imagemagick
        jless
        jq
        killall
        lazydocker
        lazygit
        magic-wormhole-rs
        nmap
        openssl
        ripgrep
        tmux
        wget
        yazi
        yt-dlp
        zellij
        
        # Archive Tools
        unzip
        unrar
        zip
        p7zip

        # System monitoring tools
        strace
        ltrace

        # Nix tools
        nix-index

        # Scripting Languages
        # useful to have around for one-off scripts
        python312
        nodejs
    ];

    # Allow mounting sshfs filesystems.
    system.fsPackages = with pkgs; [ sshfs ];
}
