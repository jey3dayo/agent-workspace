# Enabled skill IDs (shared between home.nix and `nix run .#install`)
{
  enable = [
    # --- skills-internal (local) ---
    "agent-creator"
    "cc-sdd"
    "claude-system"
    "code-quality-improvement"
    "code-review"
    "codex-system"
    "command-creator"
    "doc-standards"
    "docs-manager"
    "dotfiles-integration"
    "gemini-system"
    "generate-svg"
    "gh-fix-review"
    "integration-framework"
    "markdown-docs"
    "marketplace-builder"
    "mcp-tools"
    "polish"
    "review"
    "rules-creator"
    "sync-origin"
    "task"
    "task-to-pr"
    "tsr"
    "wezterm"

    # --- external skills ---
    "agent-browser"
    "gh-address-comments"
    "gh-fix-ci"
    "skill-creator"
    "ui-ux-pro-max"
    "web-design-guidelines"
  ];
}
