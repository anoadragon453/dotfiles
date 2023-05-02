{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
let
    cfg = config.sys.virtualisation;
in {
    options.sys.virtualisation = {
        docker = {
            enable = mkOption {
                type = types.bool;
                default = false;
                description = "Enables docker";
            };
        };
        podman = {
            enable = mkOption {
                type = types.bool;
                default = false;
                description = "Enables podman";
            };
        };
    };

    config = {
        virtualisation = {
            docker.enable = cfg.docker.enable;
            podman.enable = cfg.podman.enable;

            # Set 'docker' as an alias for podman if podman is enabled and docker is disabled.
            podman.dockerCompat = cfg.podman.enable && !cfg.docker.enable;

            # Specify configuration that is only used when building VM via build-vm
            vmVariant = {
                virtualisation = {
                    # Bump the resources for a VM built with this configuration.
                    cores = 4;         # Simulate 4 CPU cores.
                    memorySize = 6144; # Memory limit in MB.
                    diskSize = 20480;  # Disk size in MB.
                };

                # Disable any custom networking interfaces when running this config in a VM.
                # (otherwise boot will hang for 1m30s waiting fo them to come up.)
                # mkForce ensures any other configured options are overridden.
                networking.interfaces = mkForce {};
            };
        };
    };
}
