{lib, config, ...}:
let
    cfg = config.sys.virtualisation;
in {
    options.sys.virtualisation = {
        backend = lib.mkOption {
            type = lib.types.enum [ "docker" "podman" ];
            default = "podman";
            description = "Sets the OCI container runtime backend";
        };

        virtualbox = {
            enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enables virtualbox";
            };
        };
    };

    config = {
        virtualisation = {
            # Set the backend used for running any OCI containers.
            oci-containers.backend = cfg.backend;

            # Enable the appropriate runtime.
            docker.enable = cfg.backend == "docker";
            podman.enable = cfg.backend == "podman";

            # Set 'docker' as an alias for podman if podman is configured.
            podman.dockerCompat = cfg.backend == "podman";

            virtualbox.host.enable = cfg.virtualbox.enable;

            # Allow podman containers to find each other by DNS name.
            podman.defaultNetwork.settings.dns_enabled = true;

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
                networking.interfaces = lib.mkForce {};
            };
        };
    };
}