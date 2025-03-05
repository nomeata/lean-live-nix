# common configuration for Hetzner AMD machines with standard disk/RAID layout

{ config, lib, pkgs, isEfi, ... }:
{
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.swraid.enable = true;
  # remove warning about unset mail
  # https://github.com/NixOS/nixpkgs/pull/273308
  boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";

  boot.loader.grub.enable = !isEfi;
  boot.loader.grub.device = lib.mkIf (!isEfi) "/dev/nvme0n1";

  boot.loader.systemd-boot.enable = isEfi;
  boot.loader.efi.canTouchEfiVariables = isEfi;

  fileSystems."/" =
    { device = "/dev/disk/by-label/root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = if isEfi then "vfat" else "ext3";
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; }
    ];

  networking.useDHCP = lib.mkDefault true;
}
