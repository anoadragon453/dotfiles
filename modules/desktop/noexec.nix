{lib, config, ...}:

let
  cfg = config.sys.security;

  # A helper function to create an exec bind mount entry for the
  # `fileSystems` NixOS option for each of the directories in the
  # provided list `dirNames`.
  #
  # This function expects absolute directory names to be passed,
  # and only those under `/home` and `/tmp`.
  createExecBindMounts = dirNames:
    builtins.listToAttrs (map (absoluteDirName: 
    {
      name = absoluteDirName;
      value = {
        device = absoluteDirName;

        # Parent directories should be mounted first.
        depends = [ "/home" "/tmp" ];

        # This is a bind mount.
        fsType = "none";

        options = [ "bind" "exec" "relatime" ];
      };
    }) dirNames);
in {
  options.sys.security = {
    noexecHomeAndTmp = lib.mkEnableOption "Configure /home and /tmp to be noexec";
  };

  config = lib.mkIf cfg.noexecHomeAndTmp {
    # Security: Re-mount /tmp as `noexec`.
    fileSystems = {
      "/tmp" = 
        { device = "/tmp";

          # The root filesystem must be mounted first, as `/tmp` exists on it.
          depends = ["/"];

          # This is a bind mount.
          fsType = "none";

          options = [
            "bind"
            "relatime"
            "noexec"
            "nosuid"
            "nodev"
          ];
        };
    
      # Security: Re-mount /home as `noexec`.
      "/home" = 
        { device = "/home";

          # The root filesystem must be mounted first, as `/home` exists on it.
          depends = ["/"];

          # This is a bind mount.
          fsType = "none";

          options = [
            "bind"
            "relatime"
            "noexec"
            "nosuid"
            "nodev"
          ];
        };

      # Allow certain directories within `work`s home directory to have `exec`.
    } // createExecBindMounts [
      "/home/user/.cache"
      "/home/user/.config"
      "/home/user/.local/bin"
      "/home/user/.local/share"
      "/home/user/.rustup"
      "/home/user/code"
      "/home/user/go/bin"
      "/home/user/Documents"

      "/home/work/.cache"
      "/home/work/.config"
      "/home/work/.local/bin"
      "/home/work/.local/share"
      "/home/work/.rustup"
      "/home/work/code"
      "/home/work/go/bin"

      "/tmp/go-build"
    ];

    # Tell go not to store build files it expects to later execute in /tmp.
    # The main problem is that directories like `/tmp/go-build-*` are created by
    # default (which I can't predict and bind mount above). So, tell go to store
    # them in a subdirectory of `/tmp`.
    environment.variables = {
      GOTMPDIR = "/tmp/go-build";
    };
    # Ensure that directory exists.
    systemd.tmpfiles.rules = [
      "d /tmp/go-build 0777 root root"
    ];
  };
}