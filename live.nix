# lean4web playground server

{ config, pkgs, lib, inputs, ... }:
let
  lean4web = pkgs.buildNpmPackage {
    name = "lean4web";
    src = inputs.lean4web;
    npmDepsHash = "sha256-rTS1/CMfK8dqV7JFUpiK02B57itqL8d7gDu2B7KRDI8=";
    # server build also fetches mathlib, which we do dynamically in `update-leanproject`
    npmBuildScript = "build_client";
    # makeCacheWritable = true;
    npmFlags = [ "--loglevel=verbose"];
  };

  pkgs-unstable = import inputs.nixpkgs-unstable { config = config.nixpkgs.config; system = pkgs.system; };
in {
  imports = [
    ./vm-support.nix
  ];

  options = {
    services.live.useSSL = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to force SSL";
    };
  };

  config = {
    services.nginx = {
      enable = true;

      virtualHosts."live.example.com" = {
        default = true;
        enableACME = config.services.live.useSSL;
        forceSSL = config.services.live.useSSL;
        locations = {
          "/".root = "${lean4web}/lib/node_modules/leanweb/client/dist";
          "/websocket" = {
            proxyPass = "http://localhost:8080/websocket";
            proxyWebsockets = true;
          };
          "/api" = {
            proxyPass = "http://localhost:8080/api";
          };
        };
      };
    };

    # using a normal user is much easier than telling elan and cache and ... where to put their things
    users.users.lean4web = {
      isNormalUser = true;
      shell = null;
    };

    # periodically update Lean and mathlib projects, symlinked to in ~lean4web/deploy/live
    systemd.services.update-leanproject = {
      wants = ["network-online.target"];
      after = ["network-online.target"];

      path = (with pkgs; [ bash curl git gnutar gzip elan ]) ++
             (with pkgs-unstable; [ ]);

      startAt = "00/6:00"; #  repeat every 6 hours
      serviceConfig = {
        User = "lean4web";
        WorkingDirectory = "~";
        ExecStart = let
          atomicScript = pkgs.writeShellScript "atomic" (builtins.readFile ./atomic.sh);
          updateScript = pkgs.writeShellScript "update-leanproject" ''
            set -e
            echo "Updating lean-nightly"
            cp -r ${inputs.lean4web}/Projects/lean-nightly .
            chmod u+w -R lean-nightly
            cd lean-nightly
            rm -f ./lake-manifest.json
            lake build
            cd ..

            # For mathlib-stable
            echo "Updating mathlib-stable"
            cp -r ${inputs.lean4web}/Projects/mathlib-stable .
            chmod u+w -R mathlib-stable
            cd mathlib-stable
            rm -f ./lake-manifest.json
            curl -L https://raw.githubusercontent.com/leanprover-community/mathlib4/stable/lean-toolchain -o lean-toolchain
            lake update
            lake exe cache get
            lake build
            cd ..

            # For mathlib-demo
            echo "Updating mathlib-demo"
            cp -r ${inputs.lean4web}/Projects/mathlib-demo .
            chmod u+w -R mathlib-demo
            # Updating mathlib-demo: We follow the instructions at
            # https://github.com/leanprover-community/mathlib4/wiki/Using-mathlib4-as-a-dependency#updating-mathlib4
            # Additionally, we had once problems with the `lake-manifest` when a new dependency got added
            # to `mathlib`, therefore we now delete it every time for good measure.
            cd mathlib-demo
            rm -f ./lake-manifest.json
            curl -L https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o lean-toolchain
            lake update
            lake exe cache get
            lake build
            cd ..

            # Patrick Masso's Project
            echo "Updating GlimpseOfLean"
            git clone https://github.com/PatrickMassot/GlimpseOfLean
            cd GlimpseOfLean
            lake exe cache get
            lake build
            cd ..
          '';
        in "${atomicScript} build deploy/live ${updateScript}";
        Restart = "on-failure";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
      };
      unitConfig = {
        # at most one restart within 30 mins
        StartLimitIntervalSec = "1800";
        StartLimitBurst = "2";
      };
    };

    systemd.services.server = {
      wantedBy = ["multi-user.target"];
      wants = ["update-leanproject.service"];
      after = ["update-leanproject.service"];

      path = (with pkgs; [ bash git bubblewrap patchelf nix elan ]) ++
             (with pkgs-unstable; [ ]);

      serviceConfig = {
        User = "lean4web";
        WorkingDirectory = "/home/lean4web";
        ExecStart = "${lean4web}/bin/server";
        Environment = "NODE_ENV=production GLIBC=${pkgs.glibc}";
        Restart = "always";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        # breaks `lake env printenv LEAN_PATH`
        #ProtectHome = "read-only";
      };
      unitConfig = {
        StartLimitIntervalSec = "10";
        StartLimitBurst = "3";
      };
    };
  }
}
