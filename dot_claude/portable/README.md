# Portable Claude Code harness

A self-contained, employer-agnostic harness to carry to a personal machine.
Nothing here references Twilio/Segment, Bedrock, the work plugins, `~/todos`, or
any specific repo's ports/Makefile. Work-coupled config was deliberately left out
(see "What was intentionally excluded").

## Contents

```
portable/
├── CLAUDE.md                      # global preferences (iron rules, style) — no work specifics
├── settings.sample.json           # portable settings only (model, vim, statusline, effort)
├── prompts/
│   └── _operating-principles.md   # shared §0, @-mentioned by both commands
└── commands/
    ├── ticket.md                  # /ticket — generic issue work cycle
    ├── pr-triage.md               # /pr-triage — generic PR comment triage
    └── catchup.md                 # /catchup — branch-vs-default diff summary
```

## Install on a personal machine

1. Copy files to live locations:
   - `cp CLAUDE.md ~/.claude/CLAUDE.md`
   - `cp -R commands/. ~/.claude/commands/`
   - `cp -R prompts/. ~/.claude/prompts/`
   - Merge `settings.sample.json` into `~/.claude/settings.json` (don't blind-copy
     if you already have one).

2. **The @-mention dependency.** Both `ticket.md` and `pr-triage.md` contain
   `@~/.claude/prompts/_operating-principles.md`, expanded at runtime. The
   `prompts/` file MUST be present or the §0 block silently vanishes. Keep all
   three together.

3. **Pick your workspace dir.** The commands + CLAUDE.md default plans/reports to
   `~/notes/plans|reports|tickets/`. If you prefer another (e.g. `~/todos/`),
   find-replace `~/notes/` once. `mkdir -p ~/notes/{plans,reports,replies,tickets}`.

4. **Auth.** A personal machine uses the Anthropic API directly — set `ANTHROPIC_API_KEY`
   (or run `claude login`). Do NOT carry the work `settings.json` `env`/`awsAuthRefresh`
   (those are Twilio Bedrock SSO).

## Dotfiles tracking gotcha (carried over from the work machine)

If your global gitignore has a bare `.claude` rule, everything under any
`.claude/` is ignored — so copying these into a dotfiles repo won't track them.
Force past it: `git add -f .claude/commands/*.md .claude/prompts/*.md .claude/CLAUDE.md`.

## How the commands stay portable

They DISCOVER each repo's specifics instead of hardcoding:
- §0.5 Init Gate reads the repo's README/CLAUDE.md/AGENTS.md/Makefile/package.json
  to learn the real build/test/lint/dev commands and local service deps.
- The verify phase runs "the checks THIS repo defines", not fixed commands.
- The Jira/issue-tracker step is optional — falls back to treating the arg as a
  freeform task if no tracker tool is installed.

Put project-specific facts (build commands, dev ports, repo conventions) in each
repo's own CLAUDE.md / AGENTS.md — that's where they belong (repo as system of
record), and it keeps this global harness clean.

## What was intentionally excluded (work-only)

- Bedrock auth: `awsAuthRefresh`, `env` (AWS_PROFILE/REGION, CLAUDE_CODE_USE_BEDROCK)
- All `@twilio` plugins (jira-inator, buildkite, observability, datadog, sight,
  pir-*, segment-*, code-review-personae, …) and `sight` MCP + its SessionStart hook
- Skills `engineering-laptop-setup`, `staging-workspace-cleanup`
- Command `fix-papi` (Segment public-api; was empty anyway)
- CLAUDE.md "Service Directory" (the segmentio/* repo table)
- `settings.local.json` (machine-local bash allowlist — regenerate per machine)

Re-add personal equivalents (your own plugins/MCP servers) on the new machine as
you like — they're additive and don't belong in this baseline.
