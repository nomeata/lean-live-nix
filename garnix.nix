# common configuration for Running on garnix

{ config, lib, pkgs, isEfi, ... }:
{
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  boot.loader.grub.device = "/dev/sda";

  # No SSL needed when running on garnix
  services.live.useSSL = false;
}
