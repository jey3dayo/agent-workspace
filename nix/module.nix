# Home Manager module: programs.agent-skills
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.agent-skills;
  agentLib = import ./lib.nix { inherit pkgs; nixlib = lib; };

  catalog = agentLib.discoverCatalog {
    sources = cfg.sources;
    localPath = cfg.localSkillsPath;
  };

  selectedSkills = agentLib.selectSkills {
    inherit catalog;
    enable = cfg.skills.enable;
  };

  bundle = agentLib.mkBundle {
    skills = selectedSkills;
    name = "agent-skills-bundle";
  };

in {
  options.programs.agent-skills = {
    enable = lib.mkEnableOption "AI Agent Skills management";

    sources = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.path = lib.mkOption {
          type = lib.types.path;
          description = "Path to external skill source directory.";
        };
      });
      default = {};
      description = "External skill sources (name -> { path }).";
    };

    localSkillsPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to local skills directory (skills-internal). Local skills override external on conflict.";
    };

    skills.enable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of skill IDs to enable.";
    };

    targets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "this deployment target";
          dest = lib.mkOption {
            type = lib.types.str;
            description = "Destination path relative to $HOME.";
          };
          structure = lib.mkOption {
            type = lib.types.enum [ "symlink-tree" "copy-tree" "link" ];
            default = "symlink-tree";
            description = "Deployment structure: symlink-tree (rsync), copy-tree (rsync -L), or link (HM symlink).";
          };
        };
      });
      default = {};
      description = "Deployment targets for skill distribution.";
    };
  };

  config = lib.mkIf cfg.enable {
    # rsync-based sync for symlink-tree and copy-tree targets
    home.activation.agent-skills = lib.hm.dag.entryAfter [ "writeBoundary" ]
      (let
        rsyncTargets = lib.filterAttrs
          (_: t: t.enable && (t.structure == "symlink-tree" || t.structure == "copy-tree"))
          cfg.targets;
        syncCommands = lib.mapAttrsToList (_name: target:
          let
            dest = "$HOME/${target.dest}";
            rsyncFlags = if target.structure == "copy-tree" then "-aL" else "-a";
          in ''
            mkdir -p "${dest}"
            ${pkgs.rsync}/bin/rsync ${rsyncFlags} --delete --exclude='/.system' "${bundle}/" "${dest}/"
            chmod -R u+w "${dest}"
          ''
        ) rsyncTargets;
      in
        builtins.concatStringsSep "\n" syncCommands);

    # HM native symlink for "link" structure targets
    home.file = lib.mkMerge (lib.mapAttrsToList (_name: target:
      if target.enable && target.structure == "link" then {
        "${target.dest}" = {
          source = bundle;
          recursive = true;
        };
      } else {}
    ) cfg.targets);
  };
}
