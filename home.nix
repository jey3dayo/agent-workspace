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
  # home-manager binary is managed by ~/.config/home-manager (primary).
  # Enabling here would conflict with the primary configuration.
  programs.home-manager.enable = false;
}
