
{ config, lib, ... }:
{
  # an option to communicate elsewhere to know whether this is in the VM or not
  options = {
    inVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Whether this is built for local testing in the VM";
    };
  };

  # for testing with
  # nix run .#nixosConfigurations.live.config.system.build.vm
  config = {
    virtualisation.vmVariant = {
      inVM = true;
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
