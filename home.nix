# User Home Manager configuration for agent-skills
{ inputs, username, homeDirectory, targets ? import ./nix/targets.nix, ... }:
let
  selection = import ./nix/selection.nix;
in
{
  programs.agent-skills = {
    enable = true;

    localSkillsPath = ./skills-internal;

    sources = import ./nix/sources.nix { inherit inputs; };

    skills.enable = if selection ? enable then selection.enable else null;

    targets = targets;

    configFiles = [
      {
        src = ./AGENTS.md;
        default = "AGENTS.md";
        rename = { claude = "CLAUDE.md"; };
      }
    ];
  };

  # Home Manager basics (username/homeDirectory provided via extraSpecialArgs)
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";
  # Avoid profile conflicts when home-manager is already installed elsewhere.
  programs.home-manager.enable = false;
}
