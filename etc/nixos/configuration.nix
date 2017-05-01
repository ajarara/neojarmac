# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
      # absolute
      nginxRootPath = "/var/lib/nginx";
      # relative to nginxRootPath
      blogPath = "blog";
in
{
  # the choice here is to inline the hardware config and remove this import
  # or figure out how to keep this available remotely while
  # not tracking it in version control.
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  # Set your time zone.
  time.timeZone = "EST";
  
  # Define your hostname
  networking.hostName = "jarmac";


  users.extraUsers.ajarara = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = ["wheel" "ajarara" "nginx" ];
    openssh.authorizedKeys.keys = [ (builtins.readFile ./secrets/ajarara.pub) ];
  };
  
  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # is it okay to listen on all interfaces?
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 5013 ];
  
  # one of the things that irks me a little bit is that NixOS doesn't really handle directory management.
  # granted this is intrinsically state, and Nix is a functional language, but _some_ state is necessary.
  systemd.services.nginxScaffolding = {
    description = "Idempotent directory setup";
    requiredBy = [ "nginx.service" ];
    
    script = let
    in ''
     
      mkdir -p ${nginxRootPath}
      
      chown nginx:nginx ${nginxRootPath}
      # see https://en.wikipedia.org/wiki/Setuid#setuid_and_setgid_on_directories
      # or better yet: http://permissions-calculator.org/info/#setgid
      chmod 2775 ${nginxRootPath}
      
      # does setgid work retroactively (ie recursively on the dirs
      # already present)? then the above, while it does nothing, might
      # become expensive.
      mkdir -p ${nginxRootPath}/${blogPath}
    '';

    # for some reason, still doesn't fire. Why?
    serviceConfig.Type = "oneshot";
  };
  
  services.nginx = {
    enable = true;
    virtualHosts = {
      "jarmac.org" = {
        forceSSL = true;
        enableACME = true;
        serverAliases = [ "www.jarmac.org" ];
        port = 443;
        locations."/" = {
          root = "${nginxRootPath}";
        };
      };
    };
  };

  # to update this config:
  # first comment out mutable, rebuild, then uncomment and rebuild again.
  # generally config is done through an IRC client or webmin.
  services.znc = {
    enable = true;
    mutable = true;
    confOptions = {
      port = 5013;
      userName = "alphor";
      passBlock = builtins.readFile ./secrets/zncpass.block;
    };
  };
  # On fresh ZNC config, for sanity, remember to seperate listen interfaces
  # and remove web access from external IP.
  
  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";

}
