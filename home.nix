# User Home Manager configuration for agent-skills
{ inputs, username, homeDirectory, ... }:
{
  programs.agent-skills = {
    enable = true;

    localSkillsPath = ./skills-internal;

    sources = import ./nix/sources.nix { inherit inputs; };

    skills.enable = (import ./nix/selection.nix).enable;

    targets = {
      claude   = { enable = true; dest = ".claude/skills"; };
      codex    = { enable = true; dest = ".codex/skills"; };
      cursor   = { enable = true; dest = ".cursor/skills"; };
      opencode = { enable = true; dest = ".opencode/skills"; };
      openclaw = { enable = true; dest = ".openclaw/skills"; };
      shared   = { enable = true; dest = ".skills"; };
    };
  };

  # Home Manager basics (username/homeDirectory provided via extraSpecialArgs)
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
