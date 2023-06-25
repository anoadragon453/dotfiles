{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys.security.yubikey;
in {
    options.sys.security = {
        yubikey = {
            enable = mkEnableOption "Enable Yubikey support on this system";

            legacySSHSupport = mkOption {
                description = "Enable support for authenticating to SSH via gpg-agent";
                default = false;
                type = types.bool;
            };

            otpSupport = mkOption {
                description = "Enable support for OTP auth code generation";
                default = false;
                type = types.bool;
            };
        };
    };

    config = mkIf cfg.enable {
        sys.software = [
            gnupg
            yubikey-personalization
            pinentry-qt

            # Install required packages for OTP if enabled.
            (mkIf cfg.otpSupport yubioath-flutter)
        ];

        # Daemon to allow communicating with smartcard devices.
        services.pcscd = {
            enable = true;
            plugins = [ libykneomgr ];
        };

        # Allow communicating to yubikey USB devices.
        services.udev.packages = [ yubikey-personalization ];

        # Required to set the SSH_AUTH_SOCK env var correctly. Although this should
        # be done by `programs.gnupg.agent.enableSSHSupport` below, something else is
        # setting SSH_AUTH_SOCK and interfering. We just override it here instead.
        environment.shellInit = mkIf cfg.legacySSHSupport ''
            export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        '';

        programs = {
            # If legacy SSH support is enabled, use GPG as the SSH agent instead.
            ssh.startAgent = !cfg.legacySSHSupport;
            gnupg.agent = {
                enable = true;
                enableSSHSupport = cfg.legacySSHSupport;
                pinentryFlavor = "qt";
            };
        };

    };
}
