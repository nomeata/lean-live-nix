{
  description = "Live Lean Service";
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-24.11;
  inputs.nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
  inputs.flake-utils.url = github:numtide/flake-utils;
  inputs.deploy-rs.url = github:serokell/deploy-rs;
  inputs.lean4web.url = github:Kha/lean4web/nixos;
  inputs.lean4web.flake = false;

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, flake-utils, deploy-rs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    pkgs-unstable = import nixpkgs-unstable { inherit system; };
    # use deploy-rs from nixpkgs
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlay
        (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
      ];
    };
  in {
    deploy = {
      remoteBuild = true;
      sshUser = "root";
    };

    nixosConfigurations.live = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nixos.nix
        ./hetzner-amd.nix
        ./live.nix
      ];
      specialArgs = { inherit inputs; isEfi = false; };
    };
    deploy.nodes.live = {
      hostname = "live.example.com";
      profiles.system.path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.live;
    };

  } // inputs.flake-utils.lib.eachDefaultSystem (system:
    let pkgs = inputs.nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [ pkgs.deploy-rs pssh ];
      };
    });
}
