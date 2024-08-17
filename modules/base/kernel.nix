{pkgs, config, lib, ...}:
let
    cfg = config.sys;
in {
    options.sys.kernelPackage = lib.mkOption {
      default = pkgs.linuxPackages_latest;
      description = "Kernel package used to build this system";
    };

    config = {
        # Earlyoom prevents systems from locking up when they run out of memory
        services.earlyoom.enable = true;

        # A good TTY font
        console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
        
        boot.consoleLogLevel = cfg.bootLogLevel;
        boot.kernelPackages = cfg.kernelPackage;

        boot.kernel.sysctl = {
            # Allow debuggers (such as IDEs) to attach to other processes.
            "kernel.yama.ptrace_scope" = 0;
            # Allow tailscale VPN to route IPv6 traffic.
            "net.ipv6.conf.all.forwarding" = 1;
        };
    };
}
