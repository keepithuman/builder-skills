# Customizing Foundational Skills

Every skill under `skills/` is foundational — owned and updated by Itential. Customers should never edit a skill's `SKILL.md` directly: doing so gets silently overwritten or produces merge conflicts the next time that skill is updated upstream.

Instead, each skill has a `custom/` folder reserved for customer-owned content. The skill's own `SKILL.md` reads it before acting. This document is the shared reference every skill's pointer line links back to — read it once, apply it everywhere.

This applies no matter which vendor tool you use (Claude Code, Codex CLI, Cursor, GitHub Copilot) — the mechanism lives in the canonical `skills/` tree, not in any vendor-specific mirror.

**This is the per-skill half of a two-layer system.** There's also a repo-wide `customizations/{org,team,developer}/` at the repo root, for rules that apply to every skill uniformly rather than just one — see `AGENTS.md`'s Customization Layers section for how the two combine and their full precedence order. The repo-wide layer is meant for an Itential-internal team customizing their own copy of this repo (its `org`/`team` files are tracked in git); the per-skill layer below is meant for a customer's own copy of the repo, committed there like any other file.

## Structure

```
skills/<skill-name>/
├── SKILL.md               ← foundational, Itential-owned, never edited by customers
└── custom/
    ├── org/                ← company-wide (e.g. all of ACME Corp)
    │   ├── naming-conventions.md
    │   └── security-policies.md
    ├── team/               ← this team only (e.g. Network Automation)
    │   └── task-id-format.md
    └── dev/                ← this individual developer only
        └── scratch-overrides.md
```

Any of `org/`, `team/`, `dev/` may be empty or absent. Each may contain zero, one, or several `.md` files — split by topic/owner as the layer grows, rather than forcing everything into one file.

**Always edit the canonical copy under `skills/<name>/custom/`, never a mirror.** `.claude/skills/`, `.agents/skills/`, and `.github/skills/` are generated copies — the `Generate Vendor Mirrors` pipeline (`.github/workflows/generate-mirrors.yml`) copies your `custom/` files into all three when you push. You never run the conversion yourself.

## Precedence

When multiple layers speak to the same rule, **more specific wins**: `dev` overrides `team` overrides `org` overrides the foundational skill. Non-conflicting additions from every layer that exists still apply — this is layering, not replacement.

Files within the same layer should not conflict with each other. If they do, that's an authoring error in that layer to fix directly, not something to resolve by guessing which one "wins."

## Where does a given customization belong?

The organizing question isn't "how specific is this" — it's **who needs to agree to it, or be aware of it, for it to be safe.** Match the blast radius of the change to the layer:

| Ask yourself... | If yes → | Why |
|---|---|---|
| Is this a fact about *my* environment (a sandbox URL, a personal cluster ID, my own test device, a secret path only I use) — not an opinion about how things should be done? | `dev/` | Nobody else needs to agree to this; it's a config detail that happens to differ per person, not a convention. |
| Is this something I want to try before I know if it works, with real intent to promote or delete it soon? | `dev/`, temporary | Team/org shouldn't be affected by something unproven. This should have an expiration, not live here forever. |
| Does this apply to everyone on my team, and would a teammate be confused if they didn't know about it? | `team/` | The blast radius is "my team" — the review bar is "my team agrees," not "I decided alone." |
| Does this represent a company-wide policy (security, compliance, branding) — or would it be actively wrong for one team to do differently from another? | `org/` | The blast radius is everyone; silent divergence per team has organization-level consequences. |

**Examples:**
- "My sandbox IAG cluster is `cluster_dev_ankit`" → `dev/` — a config fact, mine alone
- "Let me try requiring a ticket number in every task description before proposing it to the team" → `dev/`, temporary
- "Our team always names workflows `NETAUTO_<usecase>`" → `team/` — everyone on the team needs to follow it
- "No workflow may ever call `runAutoRemediation`" → `org/` — a policy line, wrong for even one team to cross

### A caution on `dev/`

`dev/` is for environment/config differences and temporary drafts pending promotion — **not** a general-purpose personal override of team or org conventions. If you find yourself permanently overriding a `team/`-level rule in your own `dev/` file because you personally disagree with it, that override belongs in a conversation with your team (and, if adopted, in `team/`), not in an unreviewed file only you ever see. A `dev/` layer used that way quietly recreates the exact fragmentation problem this whole structure exists to prevent — just scoped to one person instead of the whole org.

## Writing an override — required format

Every override (not addition) must state what it's replacing and why, so it stays auditable as layers accumulate:

```markdown
## OVERRIDE: task ID format
Original rule: "Task IDs are hex-only [0-9a-f]{1,4}"
Replacement: Task IDs must start with a letter a-f, not a digit — our
ticket-numbering scheme is purely numeric, and we don't want task IDs
that look like ticket numbers. Valid: `a1b2`. Invalid: `1a2b`.
```

Pure additions don't need this format — just state the new rule under an `## ADD:` heading.

## Why Itential's updates never conflict with your customizations

Itential never commits real content under any skill's `custom/` folder — a CI check (`.github/workflows/guard-custom.yml`) fails any upstream PR that tries. Only `.gitkeep` placeholders ship. Your `custom/` files live in paths Itential never touches, so merging an Itential update into your copy can't conflict with them or overwrite them.

## Setting up, customizing, and updating

The conversion from `skills/` to each vendor's folder is owned by a pipeline, `.github/workflows/generate-mirrors.yml`, which comes with the repo. You write markdown files and push; the pipeline does the rest.

### 1. Make your own copy (once)

Use a **private copy**, not GitHub's Fork button — a fork of a public repo can't be made private, and your org's rules usually shouldn't be public:

```bash
gh repo create acme/builder-skills --private
git clone --bare https://github.com/itential/builder-skills.git
cd builder-skills.git && git push --mirror https://github.com/acme/builder-skills.git
cd .. && rm -rf builder-skills.git
```

(Or use GitHub's **Import repository** page with `https://github.com/itential/builder-skills`.)

Then in your copy:
- Open the **Actions** tab and make sure workflows are enabled (GitHub leaves them off in some copied repos). Itential's own repo-maintenance workflows (version bump, release notes, PR labels) skip themselves automatically outside `itential/builder-skills`; only the mirror pipeline runs.
- **If your `main` is branch-protected**, also turn on **Settings → Actions → General → Workflow permissions → "Allow GitHub Actions to create and approve pull requests"**. It's off by default, and the pipeline needs it to open its regeneration PR when it can't push to `main` directly. Without protection, the pipeline pushes straight to `main` and this setting doesn't matter.

### 2. Add a customization

```bash
git clone https://github.com/acme/builder-skills.git && cd builder-skills
mkdir -p skills/builder-agent/custom/org
echo "## ADD: workflow naming
All workflows must be prefixed ACME_." > skills/builder-agent/custom/org/naming.md
git add skills/builder-agent/custom/org/naming.md
git commit -m "org: add ACME workflow naming convention"
git push
```

(The GitHub web editor works just as well.) Within a minute the pipeline copies the file into `.claude/skills/`, `.agents/skills/`, and `.github/skills/` and commits it — directly to `main`, or, if your `main` is branch-protected, as a PR titled `chore: regenerate vendor mirrors` for you to merge.

### 3. Use it

Either work from a clone of your copy (`git pull` to pick up the pipeline's commit) — every vendor reads its folder straight from the checkout — or install it as a plugin **from your repo, not Itential's**:

```bash
/plugin marketplace add acme/builder-skills                      # Claude Code
codex plugin marketplace add acme/builder-skills                 # Codex CLI
codex plugin add itential-builder@itential-builder
gh skill install acme/builder-skills --agent <agent> --all       # Copilot / Cursor / others
```

Because your customizations are committed in your repo, every install and every update re-fetches them along with the skills — regardless of how the vendor's update mechanism handles its local cache.

### 4. Get Itential's updates

Pull from `itential/builder-skills` the way your team normally syncs from an upstream — for example:

```bash
git remote add upstream https://github.com/itential/builder-skills.git   # once
git pull upstream main
git push
```

The push touches `skills/`, so the pipeline regenerates the vendor folders with your customizations included. Nothing else to run. Then update your installs as usual (`git pull`, `/plugin update`, `codex plugin marketplace upgrade` + `codex plugin add`, or `gh skill install ... --force`).
