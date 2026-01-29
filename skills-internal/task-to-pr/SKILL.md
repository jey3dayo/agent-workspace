---
name: task-to-pr
description: Verify a task or request (or a GitHub issue), create a git worktree, implement the fix, run checks, and open a PR using the repository's PR template. Use when asked to validate a task/request and carry it through to a PR.
---

# Task to PR

## Purpose

Turn a task/request (or issue) into a validated fix with a PR, end-to-end.

## Inputs

Collect inputs (as available):

- `request`: user request text or an issue URL
- `repo`: path to the repo (default `.`)
- `base`: base branch name (default: repo default)
- `worktree`: worktree name/path (optional)
- `pr_title`: optional PR title (can be derived from request)
- `pr_labels`: optional labels (if allowed by repo)

## Workflow

1. Gather context and verify the request.
   - If the request is an issue URL and remote data is needed, follow the environment policy for network actions; if permission is required, ask for it before using `gh`, `curl`, or any network access.
   - If permission is not granted, ask the user to paste the issue body/comments.
   - Restate the requirement and define acceptance criteria.
   - Decide if the claim/request is correct. If incorrect or ambiguous, explain why and stop to ask how to proceed.

2. Plan if the change is non-trivial.
   - For larger or risky changes, propose a short plan and wait for approval.

3. Create a worktree.
   - Prefer `git wt` if it exists; otherwise use `git worktree`.
     - Check availability with `command -v git-wt` or `git wt --help`.
     - If `git wt` is not found, fall back to `git worktree`.
     - If using `git wt`, see `references/git-wt.md` for quick commands and copy flags.
   - Choose a branch name (prefer `feat/<short-slug>` in kebab-case; e.g., `feat/<short-slug>`).
   - Create the worktree:
     - `git worktree add -b <branch> <path> <base>`
   - `cd` into the worktree and verify `git status`.

4. Initialize the worktree (when applicable).
   - **Dependency install (Node projects):**
     - If `package.json` exists, detect the package manager and install deps.
     - Prefer the `packageManager` field in `package.json` when present.
     - Otherwise infer by lockfile in repo root (prefer one that exists):
       - `pnpm-lock.yaml` → `pnpm install`
       - `yarn.lock` → `yarn install`
       - `package-lock.json` or `npm-shrinkwrap.json` → `npm install`
     - If no lockfile but `package.json` exists, use `ni` (if available) or ask the user.
   - **Env files (.env / .env.keys):**
     - If the parent repo has `.env` and the worktree does not, copy `.env` into the worktree root.
     - If the parent repo has `.env.keys`, copy it into the worktree root (even when `.env` is committed).
     - Do not commit secrets.

5. Implement the fix.
   - Follow any `AGENTS.md` or project rules in scope.
   - Keep changes minimal and scoped to the request.

6. Run checks.
   - Run the repo’s standard `lint`, `type-check`, `test`, and `build` (or the closest equivalents).
   - Report results and failures clearly.

7. Prepare PR content using the template.
   - Locate a PR template in this order:
     - `.github/PULL_REQUEST_TEMPLATE.md`
     - `.github/PULL_REQUEST_TEMPLATE/*.md` (if multiple, ask which to use)
     - `PULL_REQUEST_TEMPLATE.md`
   - Fill sections with:
     - What was verified (request correctness)
     - What changed
     - Tests run and results
     - Any risks or follow-ups

8. Create the PR.
   - Ensure `gh` is authenticated; if not, ask the user to log in.
   - Follow the environment policy for network actions; ask permission only if required.
   - Use `gh pr create` with the template-filled body.
   - Share the PR URL.

## Output Expectations

- Respond in Japanese.
- If the request cannot be validated, explain why and ask for next steps.
- If multiple PR templates exist, ask which one to use.
- Do not commit unless explicitly requested.
