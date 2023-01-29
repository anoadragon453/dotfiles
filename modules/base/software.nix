{pkgs, config, lib, ...}:
{
    # This is a list of cli tools that should be present on all of my systems,
    # regardless of whether they have a GUI configured or not.
    sys.software = with pkgs; [
        # Misc cli tools
        bat
        bintools
        bottom
        devenv
        docker-compose  # Named docker-compose_2 in nixos 22.05
        dnsutils
        file
        fd
        ffmpeg
        gcc
        gdb
        ghostscript
        htop
        hyperfine
        imagemagick
        killall
        magic-wormhole
        ncdu
        ripgrep
        tmux
        wget
        yt-dlp
        
        # Archive Tools
        unzip
        unrar
        zip
        p7zip
        xar

        # System monitoring tools
        strace
        ltrace

        # This is in base because nix makes use of it with flakes.
        git

        # Allow decrypting secrets from our nix config
        git-crypt
        gnupg

        # Nix tools
        cachix
        nil
        nix-index

        # TODO: Not sure which of these I need
        # Ported from core - need to move out to somewhere else
        fuse-overlayfs # prob not in base
        unionfs-fuse # prob not in base
        squashfsTools # prob not in base
        squashfuse # prob not in base
        pstree # prob not in base
    ];
}
