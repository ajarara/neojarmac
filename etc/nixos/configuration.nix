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
  # inlined the hardware config.
  imports =
    [ 
      <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];
  
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nix.maxJobs = pkgs.lib.mkDefault 1;

    
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
    extraGroups = ["wheel" "ajarara" "nginx" "znc" ];
    openssh.authorizedKeys.keys = [ (builtins.readFile ./secrets/ajarara.pub) ];
  };

  fileSystems."/" =
    { device = "/dev/disk/by-label/root";
      fsType = "btrfs";
    };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
  
  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # build from local nixpkgs checkout
  # nix.nixPath = [ "/etc/nixos" "nixos-config=/etc/nixos/configuration.nix" ];

  # default nix path. really here for doc reasons.
  # nix.nixPath = [
  #   "/nix/var/nix/profiles/pre-user/root/channels"  # adding /nixos makes the -I flag work... what's going on here.
  #   "nixos-config=/etc/nixos/configuration.nix"
  #   "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
  # ]  # intentionally leaving out semicolon here to make sure this isn't uncommented by mistake
  
  
  # is it okay to listen on all interfaces?
  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 5013 ];
  
  # let's try with swap enabled...
  nixpkgs.config.packageOverrides = pkgs: rec {
    znc = pkgs.znc.override {
      withPython = true;
      withPerl = true;  # is necessary for python
    };
  };
  # one of the things that irks me a little bit is that NixOS doesn't really handle directory management.
  # granted this is intrinsically state, and Nix is a functional language, but _some_ state is necessary.
  systemd.services.nginxScaffolding = {
    description = "Idempotent directory setup";
    requiredBy = [ "nginx.service" ];
    
    script = ''
     
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

  # services.mysql = {
  #   enable = true;
  #   dataDir = "/var/db/mysql";
  #   package = pkgs.mysql55;
  #   initialScript = pkgs.writeText "piwik-sql-init" ''
  #     CREATE USER 'piwik'@'localhost' IDENTIFIED BY '${builtins.readFile ./secrets/piwikCreds}';
  #     GRANT ALL PRIVILEGES ON piwikdb . * TO 'piwik'@'localhost';
  #   '';
  #   # bind locally only.
  #   # extraOptions = ''
  #   #   bind-address = 127.0.0.1
  #   # '';
  # };
  
  # services.nixosManual.enable = false;
  # services.piwik = {
  #   enable = true;
  #   webServerUser = "nginx";
  #   nginx = {
  #     # hmm maybe I don't want it as a subdomain, but instead a port?
  #     # is there a way to use the current definition of what a
  #     # virtualHost is? in nginx' case it's in a separate file
  #     # and could be imported.
  #     virtualHost = "piwik.jarmac.org";
  #     forceSSL = true;
  #     enableACME = true;
  #   };
  # };

  # to update this config,
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
