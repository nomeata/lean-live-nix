
{ config, lib, ... }:
{
  # for testing with
  # nix run .#nixosConfigurations.live.config.system.build.vm
  config = {
    virtualisation.vmVariant = {
      services.live.useSSL = false;
      virtualisation.diskSize = 60000; # MB, too many mathlibs around
      virtualisation.memorySize = 8069;
      virtualisation.cores = 3; # Otherwise lean4web doesn't work it seems!
      services.getty.autologinUser = "root";
      users.users.root.password = "";
      virtualisation.forwardPorts = [
        { from = "host"; host.port = 8888; guest.port = 80; }
      ];
    };
  };
}
