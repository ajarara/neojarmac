# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

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
    extraGroups = ["wheel" "ajarara" ];
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
  networking.firewall.allowedTCPPorts = [ 80 ];
  
  services.nginx.enable = true;

  # one of the things that irks me a little bit is that NixOS doesn't really handle directory management.
  
  # services.nginx.virtualHosts = {
  #  "jarmac.org" =  {
  #     locations."/" = {
  #       port = 22;
  #       root = "";
  #     };
  #     locations
  #   };
  # };

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "17.03";

}
