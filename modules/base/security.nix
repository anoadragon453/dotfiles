{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys.security;
in {

    options.sys.security = {
        sshd.enable = mkOption {
            type = types.bool;
            description = "Enable sshd service on system";
            default = true;
        };
    };

    config = {
        # Stops sudo from timing out.
        security.sudo.extraConfig = "Defaults env_reset,timestamp_timeout=-1";
        security.sudo.execWheelOnly = true;

        services.openssh.enable = lib.mkForce cfg.sshd.enable;

        networking.firewall.allowedTCPPorts = [ (mkIf cfg.sshd.enable 22) ];
        networking.firewall.allowPing = true;
    };
}
