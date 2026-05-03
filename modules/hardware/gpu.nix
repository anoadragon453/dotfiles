{pkgs, lib, config, ...}:
with pkgs;
with lib;
with builtins;
let
    cfg = config.sys;
in {
    options.sys.hardware.graphics = {
        primaryGPU = mkOption {
          type = types.enum [ "amd" "intel" "nvidia" "none"];
          default = "none";
          description = "The primary gpu on your system that you want your desktop to display on";
        };

        extraGPU = mkOption {
          type = with types; listOf (enum ["amd" "intel" "nvidia"]);
          default = [];
          description = "Extra gpu your system has installed";
        };

        amd.rocm.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Install packages for AMD ROCM support. Only supported on newer AMD GPUs";
        };

        desktopProtocols = mkOption {
          type = with types; listOf (enum ["xorg" "wayland"]);
          default = [];
          description = "Desktop protocols you want to use for your desktop environment";
        };

        displayManager = mkOption {
          type = types.enum ["none" "lightdm" "greetd" "gdm" "sddm"];
          default = "none";
          description = "Select the display manager you want to boot the system with";
        };

        v4l2loopback = mkEnableOption "Enable v4l2loopback on this system";
   };

  config = let
    gfx = cfg.hardware.graphics;
    amd = (gfx.primaryGPU == "amd" || (elem "amd" gfx.extraGPU));
    intel = (gfx.primaryGPU == "intel" || (elem "intel" gfx.extraGPU));
    nvidia = (gfx.primaryGPU == "nvidia" || (elem "nvidia" gfx.extraGPU));

    xorg = (elem "xorg" gfx.desktopProtocols);
    desktopMode = xorg;

    headless = gfx.primaryGPU == "none";

    kernelPackage = config.sys.kernelPackage;
  in {
    
    boot.initrd.kernelModules = [
      # (mkIf amd "amdgpu")
    ];

    boot.extraModprobeConfig = mkIf gfx.v4l2loopback ''
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label="obs"
    '';

    boot.extraModulePackages =
      optional gfx.v4l2loopback kernelPackage.v4l2loopback;

    services.xserver = mkIf xorg {
      enable = true;

      videoDrivers =
        optional amd "amdgpu"
        # "intel" used to translate to installing the xf86videointel driver,
        #  which is unmaintained
        ++ optional intel "modesetting"
        ++ optional nvidia "nvidia";

      displayManager.lightdm.enable = gfx.displayManager == "lightdm";
      displayManager.gdm.enable = gfx.displayManager == "gdm";
      displayManager.gdm.wayland = true;

      deviceSection = mkIf (intel || amd) ''
        Option "TearFree" "true"
      '';
      
    };

    services.libinput.enable = true;

    services.displayManager = {
      sddm.enable = gfx.displayManager == "sddm";
      sddm.wayland.enable = true;
      logToJournal = true;
    };

    services.greetd.enable = gfx.displayManager == "greetd";    

    hardware.nvidia.modesetting.enable = nvidia;
    hardware.graphics.enable = !headless;
    hardware.steam-hardware.enable = !headless;

    hardware.graphics.extraPackages = mkIf (!headless) (with pkgs;
      optional amd amdvlk
      ++ optional cfg.hardware.graphics.amd.rocm.enable rocm-opencl-icd
      ++ optional cfg.hardware.graphics.amd.rocm.enable rocm-opencl-runtime
      ++ optional intel intel-media-driver
      ++ optional intel libva-vdpau-driver
      ++ optional intel libvdpau-va-gl
      ++ [ libva ]);

    hardware.graphics.extraPackages32 = mkIf (!headless) (
      with pkgs.driversi686Linux;
      optional amd amdvlk
    );

    sys.software = with pkgs;
      optional desktopMode vulkan-tools
      ++ optional desktopMode vulkan-loader
      ++ optional desktopMode vulkan-headers
      ++ optional desktopMode mesa-demos
      ++ optional amd radeontop
      ++ optional intel libva-utils
      ++ optional gfx.v4l2loopback kernelPackage.v4l2loopback
      ++ optional gfx.v4l2loopback libv4l
      ++ optional gfx.v4l2loopback xawtv;
  };
}
