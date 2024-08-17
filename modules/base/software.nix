{pkgs, ...}:
{
    # This is a list of cli tools that should be present on all of my systems,
    # regardless of whether they have a GUI configured or not.
    sys.software = with pkgs; [
        # Misc cli tools
        bat
        bintools
        bottom
        distrobox
        docker-compose  # Named docker-compose_2 in nixos 22.05
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
        hyperfine
        imagemagick
        jless
        jq
        killall
        lazydocker
        magic-wormhole-rs
        nmap
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
        xar

        # System monitoring tools
        strace
        ltrace

        opentofu

        # Nix tools
        nil
        nix-index

        # Scripting Languages
        # useful to have around for one-off scripts
        python312
        nodejs

        # TODO: Not sure which of these I need
        # Ported from core - need to move out to somewhere else
        fuse-overlayfs # prob not in base
        unionfs-fuse # prob not in base
        squashfsTools # prob not in base
        squashfuse # prob not in base
        pstree # prob not in base
    ];

    # Allow mounting sshfs filesystems.
    system.fsPackages = with pkgs; [ sshfs ];
}
