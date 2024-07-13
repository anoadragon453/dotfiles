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
      (mkIf amd "amdgpu")
    ];

    boot.extraModprobeConfig = mkIf gfx.v4l2loopback ''
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label="obs"
    '';

    boot.extraModulePackages = [
      (mkIf gfx.v4l2loopback kernelPackage.v4l2loopback)
    ];

    services.xserver = mkIf xorg {
      enable = true;

      videoDrivers = [
        (mkIf amd "amdgpu") 
        (mkIf intel "intel")
        (mkIf nvidia "nvidia")
      ];

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
      logToJournal = true;
    };

    services.greetd.enable = gfx.displayManager == "greetd";    

    hardware.nvidia.modesetting.enable = nvidia;
    hardware.opengl.enable = !headless;
    hardware.steam-hardware.enable = !headless;

    hardware.opengl.extraPackages = mkIf (!headless) (with pkgs;[
      (mkIf amd amdvlk)

      (mkIf cfg.hardware.graphics.amd.rocm.enable rocm-opencl-icd)
      (mkIf cfg.hardware.graphics.amd.rocm.enable rocm-opencl-runtime)

      (mkIf intel intel-media-driver)
      (mkIf intel vaapiIntel)
      (mkIf intel vaapiVdpau)
      (mkIf intel libvdpau-va-gl)

      libva
    ]);

    hardware.opengl.extraPackages32 = mkIf (!headless) (with pkgs.driversi686Linux;[
      (mkIf amd amdvlk)
    ]);

    sys.software = with pkgs; [
      (mkIf desktopMode vulkan-tools)
      (mkIf desktopMode vulkan-loader)
      (mkIf desktopMode vulkan-headers)
      (mkIf desktopMode glxinfo)
      (mkIf amd radeontop)
      (mkIf intel libva-utils)

      (mkIf gfx.v4l2loopback kernelPackage.v4l2loopback)
      (mkIf gfx.v4l2loopback libv4l)
      (mkIf gfx.v4l2loopback xawtv)
   ];
  };
}
