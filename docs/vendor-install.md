# Vendor Install And Command Guide

Canonical skill content: `skills/{skill-name}/SKILL.md`. Root manifest: `plugin.json` (agent-plugins.org v1.0.0).

## Claude Code

Install:
```text
/plugin marketplace add itential/builder-skills
/plugin install itential-builder@itential-builder
```

Or clone the repo. `.claude/skills/<name>/SKILL.md` is committed and ready.

Invoke:
```text
/builder-agent
/spec-agent
```

## Codex CLI

Install:
```bash
codex plugin marketplace add itential/builder-skills
codex plugin add itential-builder-skills
```

Or clone the repo. `.agents/skills/<name>/SKILL.md` is committed and ready.

Invoke:
```text
$builder-agent
```
Or `/skills` to pick from a list. Or describe the task and let Codex auto-route.

## Cursor

Install: cursor.com/marketplace → "Add to Cursor".

Or clone the repo. `.agents/skills/<name>/SKILL.md` is committed and ready (same file Codex uses).

Invoke:
```text
/builder-agent
```

## GitHub Copilot

Install:
```bash
gh skill install itential/builder-skills <skill-name>
```

Or clone the repo. `.github/skills/<name>/SKILL.md` is committed and ready.

Invoke:
```text
/builder-agent
```
Or describe the task and let Copilot auto-route.

## Regenerate Local-Repo Mirrors

After editing `skills/`:
```bash
scripts/generate-vendor-wrappers.sh
scripts/check-generated.sh
```

## Reference

| Vendor | Install | Local clone path | Invoke |
|---|---|---|---|
| Claude Code | `claude plugin install` | `.claude/skills/` | `/skill-name` |
| Codex CLI | `codex plugin add` | `.agents/skills/` | `$skill-name`, `/skills`, or auto-route |
| Cursor | Plugin marketplace | `.agents/skills/` | `/skill-name` |
| GitHub Copilot | `gh skill install` | `.github/skills/` | `/skill-name` or auto-route |
