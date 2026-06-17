---
description: Generic ticket/issue work cycle — Init → Read → Brief, then gated phases (Scope/Plan/Build/Verify/Review/Land/Clean state). Stops after the brief and after each phase for approval. Project-agnostic; discovers repo specifics.
argument-hint: <issue url | KEY-1234 | 1234 | freeform task>
---

WORK CYCLE: Init → Read → Brief → Scope → Plan → Build → Verify → Review → Land → Clean state

Operating principles (apply to EVERY phase below):
@~/.claude/prompts/_operating-principles.md

Task / issue reference: $ARGUMENTS
(If empty, fall back to clipboard. If still empty/ambiguous, ask before guessing.)

# 0.5 INIT GATE (run before any build/verify work; report PASS/FAIL, don't fix silently)
- Repo + branch: confirm cwd repo, current branch, and `git status` is clean
  (or report what's dirty). Not on the default branch before a Land phase.
- Discover, don't assume: read this repo's README / CLAUDE.md / AGENTS.md /
  Makefile / package.json scripts to learn the real build, test, lint, and dev
  commands and any local service dependencies (DB ports, docker, etc.). Use what
  you find in later phases — never hardcode another project's commands or ports.
- Environment health: confirm the deps this task needs are actually reachable
  BEFORE running anything against them (services up, ports open, env vars set).
  If a check fails, surface it and propose the fix — don't discover a broken env
  mid-verify.
- If any gate fails, STOP and report — do not run tests against a broken env.

# 1. Read (fetch)
- If the reference is an issue tracker key/URL and an issue-tracker tool/skill is
  available, use it to fetch the ticket. Otherwise treat $ARGUMENTS as a freeform
  task description and proceed.

# 2. Brief (give me back, in this exact order)
- Title
- Key + status (if from a tracker; else "freeform task")
- Type / priority (if available)
- Reporter / assignee (if available)
- Summary: 2-4 sentences, plain English, what's actually being asked
- Acceptance: bullets verbatim from an AC field if present, else "none stated"
- Linked work: blocking / blocked-by / related, one-line context each (if available)
- Last activity: latest comment author + 1-line gist + date (if available)
- My read: one paragraph — what it looks like, what's ambiguous, what I'd want
  clarified before scoping

# 3. State (re-entry)
Append a one-line entry to your tickets index (default ~/notes/tickets/INDEX.md;
override to wherever you keep it):  - YYYY-MM-DD · <KEY|task> · <title> · <status>
If already present, note "previously seen on <date>" in the brief and skip the append.

# 4. STOP after the brief
- Do NOT scope, plan, implement, comment on the ticket, or change any field.
- Wait for my next instruction. Everything below runs only when I say go, and
  only the phase I name.

# 5. Scope (only when I ask)
- Map the code first (§0). Then surface scope-changing ambiguities as ONE batched
  question. Resolve everything else with stated defaults.

# 6. Plan (only when I ask)
- Dispatch manifest for subagents: explicit steps, parallel-vs-sequential marked,
  exact files/lines, function names, enumerated test cases, done = passes §8.
  Store in your plans dir (default ~/notes/plans/YYYY/). Re-verify any choice I
  made against the code before locking. Present it; wait for go.

# 7. Build (only when I ask)
- WIP=1. Delegate independent steps to subagents; you orchestrate and review.
- If I say "review each file", STOP after every file edit and wait for my OK
  before the next.

# 8. Verify (before claiming anything is done — show output for each)
Run the checks THIS repo actually defines (discovered in §0.5), e.g.:
- Type check (e.g. tsc --noEmit / build)
- Lint
- Unit tests (confirm new tests RAN, not skipped)
- Integration/snapshot tests (only if touched; READ the generated artifact)
- Any project-specific linters / codegen (only if the relevant inputs changed)
On failure: report it with the output, do NOT auto-retry destructive fixes,
hand back to me.

# 9. Review (only when I ask)
- Run whatever deep-review skill/command is installed (e.g. /deepreview-uncommitted),
  or do a structured self-review. Synthesize critical/high/medium + consensus;
  separate real bugs from scope decisions; recommend an action per finding.

# 10. Land (only when I ask — never push, never open a PR without my explicit OK)
- Branch per this repo's naming convention off the default branch.
- Commit message via temp file (single-line command), no co-author line.
- Show final state: HEAD, branch, clean tree. Stop. Push/PR are mine to trigger.

# 11. CLEAN STATE (before declaring the session done)
- Build green · all tests green (incl. pre-existing — didn't break anything).
- Working tree clean; intended changes committed, nothing stray staged.
- Temp artifacts removed (/tmp scratch files, debug logs, commented-out code).
- No stray git worktrees polluting test runs (`git worktree list` — flag stale).
- State updated: tickets index, plan file status, progress notes (done /
  in-progress + state / next, each with its pass-gate).
- Standard startup path still works (next session can boot without manual fixes).
- Report: what changed (commits + drafts), what's verified, what's left. Then stop.
