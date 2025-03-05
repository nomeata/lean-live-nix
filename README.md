# Example live.lean-lang.org-like setup using nix

This repository contains fragments of the nix setup behind live.lean-lang.org,
for public consumption and cargo-culting.

At the moment it is a one-time dump and not actively used by the maintained service. Maybe eventually they can share the code via a nicely maintained NixOS module.

* Change the acme email address in `nixos.nix`.
* Change the SSH key in `nixos.nix`.
* Change the hostnames (`live.example.com`) in `flake.nix` and `live.nix`.
* Install nixos somehow on the target machine
* Run `deploy .#live` in a `nix develop` shell to deploy, assuming your public key has already been deployed to the machines.
