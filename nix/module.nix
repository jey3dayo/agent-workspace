# Home Manager module: programs.agent-skills
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.agent-skills;
  agentLib = import ./lib.nix { inherit pkgs; nixlib = lib; };

  catalog = agentLib.discoverCatalog {
    sources = cfg.sources;
    localPath = cfg.localSkillsPath;
  };

  localSkillIds = lib.attrNames (lib.filterAttrs (_: skill: skill.source == "local") catalog);
  enableList = lib.unique (cfg.skills.enable ++ localSkillIds);

  selectedSkills = agentLib.selectSkills {
    inherit catalog;
    enable = enableList;
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
      description = "List of skill IDs to enable (local skills are always included).";
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
            type = lib.types.enum [ "link" "copy-tree" ];
            default = "link";
            description = "Deployment structure: link (HM symlink, read-only) or copy-tree (rsync copy, writable).";
          };
        };
      });
      default = {};
      description = "Deployment targets for skill distribution.";
    };
  };

  config = lib.mkIf cfg.enable {
    # copy-tree targets: rsync-based sync (writable copy)
    home.activation.agent-skills = lib.hm.dag.entryAfter [ "writeBoundary" ]
      (let
        copyTargets = lib.filterAttrs
          (_: t: t.enable && t.structure == "copy-tree")
          cfg.targets;
        syncCommands = lib.mapAttrsToList (_name: target:
          let dest = "$HOME/${target.dest}";
          in ''
            mkdir -p "${dest}"
            ${pkgs.rsync}/bin/rsync -aL --delete --exclude='/.system' "${bundle}/" "${dest}/"
            chmod -R u+w "${dest}"
          ''
        ) copyTargets;
      in
        builtins.concatStringsSep "\n" syncCommands);

    # link targets: per-skill directory symlinks to Nix store (default)
    # Each skill dir becomes a symlink: ~/.claude/skills/agent-creator → /nix/store/.../agent-creator
    # This keeps .system and other tool-managed files writable in the parent dir
    home.file = lib.mkMerge (lib.mapAttrsToList (_name: target:
      if target.enable && target.structure == "link" then
        lib.mapAttrs' (skillId: _skill:
          lib.nameValuePair "${target.dest}/${skillId}" {
            source = "${bundle}/${skillId}";
          }
        ) selectedSkills
      else {}
    ) cfg.targets);
  };
}
