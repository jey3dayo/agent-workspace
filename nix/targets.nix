# Default deployment targets for `nix run .#install`
[
  { tool = "claude";   dest = ".claude/skills"; }
  { tool = "codex";    dest = ".codex/skills"; }
  { tool = "cursor";   dest = ".cursor/skills"; }
  { tool = "opencode"; dest = ".opencode/skills"; }
  { tool = "openclaw"; dest = ".openclaw/skills"; }
  { tool = "shared";   dest = ".skills"; }
]
