---
description: Generic PR comment triage work cycle — Init → fetch all comment sources → priority/engagement triage → per-item plans or reply drafts → implement → verify → clean-state hand-back. Drafts only; never posts, pushes, or merges. Project-agnostic.
argument-hint: <PR url | PR number>
---

WORK CYCLE: Init → PR Triage → Plan/Draft → Implement → Verify → Hand-back → Clean state

Operating principles (apply to EVERY phase below):
@~/.claude/prompts/_operating-principles.md

PR reference: $ARGUMENTS
(If empty, ask for the PR link/number before fetching.)

# 0.5 INIT GATE (before any build/verify; report PASS/FAIL, don't fix silently)
- Repo + branch correct; know whether the PR branch is checked out locally.
- `git status` clean (or report what's dirty) before touching files.
- Discover, don't assume: read this repo's README / CLAUDE.md / AGENTS.md /
  Makefile / package.json scripts for the real build/test/lint/dev commands and
  local service dependencies. Use those in §5 — never hardcode another project's.
- Environment health: deps this PR's tests need are reachable BEFORE running them
  (services up, ports open). If a gate fails, STOP and report — don't verify on a
  broken env.
- Forge CLI auth/host reachable before any forge API call (e.g. `gh auth status`).

# 1. Fetch context (use ALL comment sources — they surface different feedback)
- Inline review comments:  gh api repos/<owner>/<repo>/pulls/<N>/comments
- Top-level conversation:   gh pr view <N> --json comments,reviews
- PR diff:                  gh pr diff <N>
(If a gh-cli helper skill is installed, use it first — avoids inline-comment and
enterprise-host pitfalls.) Skip already-resolved threads.

# 2. Triage (main thread, no delegation)
Read the code each comment references before classifying it (§0).
Rank by priority AND classify engagement type:
  Priority:   P0 blocking | P1 design | P2 nit
  Engagement: fix | fix+ack | reply-only | disagree | defer | already-addressed
Output a markdown table:
  id | author | file:line | summary | priority | engagement | proposed action
For `disagree`, the action cell carries the one-line evidence (file:line).
Stop. Wait for my approval of the triage.

# 3. Plan / draft (per item I select, after triage approval)
- fix / fix+ack → implementation plan in your plans dir (default
  ~/notes/plans/YYYY/YYYY-MM-DD-<short>.md) as a dispatch manifest for subagents:
  parallel/sequential markers, explicit tool calls, file paths, function names,
  line numbers, enumerated test cases, done = passes §5. PR link in front matter.
  Re-verify the fix against the code before locking.
- reply-only / disagree / defer → reply text in your replies dir (default
  ~/notes/replies/YYYY/YYYY-MM-DD-<short>.md), one file per thread, tagged with
  comment id + PR link. Match my voice: friendly, direct, concise.
- already-addressed → reply draft includes the resolving commit sha to paste.
Stop. Wait for my approval of each plan / reply.

# 4. Environment (parallelism + isolation)
If multiple plans run concurrently:
- Default: each subagent writes a small state file (status, current_step,
  last_command, blockers) under a per-run dir.
- git worktrees ONLY when fixes touch overlapping files.
- Otherwise stay on the branch; agents commit sequentially.

# 5. Verify (what "done" means — show output for each)
Run the checks THIS repo defines (discovered in §0.5): type check, lint, unit
tests (confirm new tests RAN), integration/snapshot (only if touched; READ the
artifact), project linters/codegen (only if inputs changed), and a deep-review
skill/command if installed.
On failure: report it with the output, do NOT auto-retry destructive fixes, hand
back to me. Separate real review findings from scope decisions.

# 6. Stop conditions
- Do NOT push, amend, or merge.
- Do NOT POST replies — drafts only. I post.
- Do NOT mark comments resolved.
- After §5 passes: report what changed (commits + reply drafts); commit + push +
  post are mine to trigger.

# 7. Re-entrancy
If a comment is already addressed by a commit on this branch, mark it
"already addressed" in the triage table (with the sha) and skip it.

# 8. Clarifying questions (ask before triage only if unclear)
- Which environments to test against
- Batch multiple comments into one commit, or split
- Any P2 nits to skip wholesale

# 9. CLEAN STATE (before hand-back)
- Build green · all tests green incl. pre-existing.
- Working tree clean; each addressed comment maps to a commit (note the sha).
- Temp artifacts + scratch state files removed; no stale git worktrees
  (`git worktree list` — flag stale).
- Per-run state files final; reply drafts complete and tagged with comment id + sha.
- Standard startup path intact.
- Report: commits + reply drafts + which comments are addressed/replied/deferred.
  Commit + push + post stay mine.
