# common settings for all NixOS machines

{ config, lib, pkgs, inputs, ... }:
{
  security.acme.defaults.email = "mail@joachim-breitner.de";
  security.acme.acceptTerms = true;

  environment.systemPackages = with pkgs; [
    ripgrep
    htop
    file
    nvd
  ];

  services.nginx = {
    enableReload = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # Joachim
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRd0CZZQXyKTEQSEtrIpcTg15XEoRjuYodwo0nr5hNj jojo@kirk"
  ];

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # Else too noisy in the log
  networking.firewall.logRefusedConnections = false;

  services.fail2ban.enable = true;

  programs.vim = {
    defaultEditor = true;
    enable = true;
  };

  nix.settings.allowed-users = [ "@wheel" ];
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.registry = {
    nixpkgs = {
      from = { id = "nixpkgs"; type = "indirect"; };
      flake = inputs.nixpkgs;
    };
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
    persistent = true;
  };

  documentation.nixos.enable = false;
  documentation.enable = false;

  time.timeZone = "UTC";

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
