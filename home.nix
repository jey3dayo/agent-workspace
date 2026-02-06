# User Home Manager configuration for agent-skills
# NOTE: Requires --impure flag due to builtins.getEnv usage
{ inputs, ... }:
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

  # Home Manager basics
  # builtins.getEnv requires --impure flag
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
