{pkgs, config, lib, ...}:
with pkgs;
with lib;
let
    cfg = config.sys;
in {
    options.sys = {
    cpu = {
      type = mkOption {
        type = types.enum ["intel" "amd"];
        description = "Type of cpu the system has in it";
      };

      cores = mkOption {
        type = types.int;
        default = 1;
        description = "Number of physical cores on cpu per socket";
      };

      sockets = mkOption {
        type = types.int;
        default = 1;
        description = "Number of CPU sockets installed in system";
      };

      threadsPerCore = mkOption {
        type = types.int;
        default = 1;
        description = "Number of threads per core.";
      };

      kvm = mkOption {
          type = types.bool;
          default = true;
          description = "Enable KVM virtualisation on this machine";
      };
    };
   };

   config = {
        boot.kernelParams =
            optional (cfg.cpu.type == "intel") "intel_pstate=active";

        boot.kernelModules =
            optional (cfg.cpu.kvm && cfg.cpu.type == "amd") "kvm-amd"
            ++ optional (cfg.cpu.kvm && cfg.cpu.type == "intel") "kvm-intel";

        # Install microcode update packages
        sys.software =
            optional (cfg.cpu.type == "amd") microcodeAmd
            ++ optional (cfg.cpu.type == "intel") microcode-intel;

        # Load updated microcode
        hardware.cpu.amd.updateMicrocode = cfg.cpu.type == "amd";
        hardware.cpu.intel.updateMicrocode = cfg.cpu.type == "intel";

        virtualisation.libvirtd.enable = cfg.cpu.kvm;
        # Allow users to use USB devices in VMs
        virtualisation.spiceUSBRedirection.enable = true;
   };
}
