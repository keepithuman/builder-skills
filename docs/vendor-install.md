# Vendor Install And Command Guide

Canonical skill content: `skills/{skill-name}/SKILL.md`. Root manifest: `plugin.json` (agent-plugins.org v1.0.0).

## Quick Install / Update (any agent)

```bash
scripts/install-for-agent.sh                       # interactive picker, times the install
scripts/install-for-agent.sh claude-code            # non-interactive
scripts/install-for-agent.sh cursor user            # scope: project (default) or user
scripts/install-for-agent.sh codex project --update # re-fetch latest
scripts/install-for-agent.sh codex project --version v1.6.7  # pin a version
```

One script, one flag for update — not two scripts. Both install and update go through `gh skill install itential/builder-skills --agent <agent> --all`, adding `--force` for `--update`. Requires a `gh` version with `gh skill` support (`gh skill --help`). Supported `--agent` values: `github-copilot`, `claude-code`, `cursor`, `codex`, plus 40+ others `gh skill install --help` lists.

## Update, if not using the script

| Vendor | Command |
|---|---|
| Claude Code | Auto-updates in the background, or `/plugin marketplace update itential-builder` to force a refresh |
| Codex CLI | `codex plugin marketplace upgrade itential-builder` then `codex plugin add itential-builder@itential-builder` |
| Cursor | Marketplace UI |
| GitHub Copilot | `copilot plugin update itential-builder` |
| Any local clone | `git pull` |

These genuinely differ per vendor — Claude Code auto-updates, Codex needs two steps, Copilot is one command. `scripts/install-for-agent.sh --update` sidesteps this entirely by always going through `gh skill install`, which handles per-agent placement itself.

## Per-Vendor (manual)

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
codex plugin add itential-builder@itential-builder
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

Or clone the repo. `copilot` reads `.github/skills/`, `.agents/skills/`, and `.claude/skills/` — all three are committed and ready; no install step needed.

Invoke:
```text
/builder-agent
```
Or describe the task and let Copilot auto-route.

Verified live (`copilot skill list`, `copilot --plugin-dir . skill list`): all 17 skills load with zero errors.

## Regenerate Local-Repo Mirrors

After editing `skills/`:
```bash
scripts/generate-vendor-wrappers.sh
scripts/check-generated.sh
```

## Customize & Maintain Your Fork

Don't edit a skill's `SKILL.md` directly — those edits get overwritten on update. Each skill has a `skills/<name>/custom/{org,team,dev}/` folder for your own content instead. Full framework (precedence, decision guide, override format) and the per-vendor durability findings: **`docs/customization.md`**.

Short version:
```bash
gh repo fork itential/builder-skills --clone
cd builder-skills
# add files under skills/<name>/custom/{org,team,dev}/
scripts/generate-vendor-wrappers.sh   # propagate into .claude/skills, .agents/skills, .github/skills
git add -f skills/<name>/custom/org/your-file.md   # only if you want it tracked/shared
git commit -m "org: add customization"
```

To pull new Itential releases into your fork later:
```bash
scripts/update-fork.sh                 # rebase onto upstream/main, regenerate mirrors, validate
scripts/update-fork.sh --merge         # merge instead of rebase
```

**This clone/fork path is the only one verified safe for `custom/` content across every vendor.** Claude Code's own plugin installer also preserves it (git-based, verified), but Codex's plugin installer does not (verified — it deletes the entire versioned install directory on update). See `docs/customization.md` for the full per-vendor table.

## Reference

| Vendor | Install | Local clone path | Invoke |
|---|---|---|---|
| Claude Code | `claude plugin install` | `.claude/skills/` | `/skill-name` |
| Codex CLI | `codex plugin add` | `.agents/skills/` | `$skill-name`, `/skills`, or auto-route |
| Cursor | Plugin marketplace | `.agents/skills/` | `/skill-name` |
| GitHub Copilot | `gh skill install` | `.github/skills/` | `/skill-name` or auto-route |
