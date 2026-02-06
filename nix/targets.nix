# Deployment targets for skill distribution
# Fields: enable (bool), dest (string), structure? ("link"|"copy-tree", default "link")
{
  claude   = { enable = true; dest = ".claude/skills"; };
  codex    = { enable = true; dest = ".codex/skills"; };
  cursor   = { enable = true; dest = ".cursor/skills"; };
  opencode = { enable = true; dest = ".opencode/skills"; };
  openclaw = { enable = true; dest = ".openclaw/skills"; };
  shared   = { enable = true; dest = ".skills"; };
}
