{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys.security;
in {

    options.sys.security = {
        sshd = {
            enable = mkOption {
                type = types.bool;
                description = "Enable sshd service on system";
                default = true;
            };

            serverPort = mkOption {
                type = types.int;
                description = "The port to host SSH on";
                default = 22;
            };
        };
    };

    config = {
        # Stops sudo from timing out.
        security.sudo.extraConfig = "Defaults env_reset,timestamp_timeout=-1";
        security.sudo.execWheelOnly = true;

        services.openssh.enable = cfg.sshd.enable;
        services.openssh.ports = [ cfg.sshd.serverPort ];

        # Mitigate CVE-2024-6387 using the mitigation found on
        # https://ubuntu.com/security/CVE-2024-6387, while we lack
        # upstream openssh patches.
        services.openssh.settings.LoginGraceTime = 0;

        networking.firewall.allowedTCPPorts = [ (mkIf cfg.sshd.enable cfg.sshd.serverPort) ];
        networking.firewall.allowPing = true;
    };
}
