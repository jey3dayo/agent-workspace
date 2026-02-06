# User Home Manager configuration for agent-skills
{ inputs, ... }:
{
  programs.agent-skills = {
    enable = true;

    localSkillsPath = ./skills-internal;

    sources = {
      openai-curated.path = "${inputs.openai-skills}/skills/.curated";
      openai-system.path = "${inputs.openai-skills}/skills/.system";
      vercel.path = "${inputs.vercel-agent-skills}/skills";
      agent-browser.path = "${inputs.vercel-agent-browser}/skills";
      ui-ux-pro-max.path = "${inputs.ui-ux-pro-max}/.claude/skills";
      orchestra.path = "${inputs.claude-code-orchestra}/.claude/skills";
    };

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
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
