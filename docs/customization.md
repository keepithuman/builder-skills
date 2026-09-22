# Customizing Foundational Skills

Every skill under `skills/` is foundational — owned and updated by Itential. Customers should never edit a skill's `SKILL.md` directly: doing so gets silently overwritten or produces merge conflicts the next time that skill is updated upstream.

Instead, each skill has a `custom/` folder reserved for customer-owned content. The skill's own `SKILL.md` reads it before acting. This document is the shared reference every skill's pointer line links back to — read it once, apply it everywhere.

This applies no matter which vendor tool you use (Claude Code, Codex CLI, Cursor, GitHub Copilot) — the mechanism lives in the canonical `skills/` tree, not in any vendor-specific mirror.

**This is the per-skill half of a two-layer system.** There's also a repo-wide `customizations/{org,team,developer}/` at the repo root, for rules that apply to every skill uniformly rather than just one — see `AGENTS.md`'s Customization Layers section for how the two combine and their full precedence order. The repo-wide layer is meant for an Itential-internal team customizing their own copy of this repo (its `org`/`team` files are tracked in git); the per-skill layer below is meant for a customer's own fork (gitignored by default, force-trackable — see Path B below).

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

**Always edit the canonical copy under `skills/<name>/custom/`, never a mirror.** `.claude/skills/`, `.agents/skills/`, and `.github/skills/` are generated copies (see `docs/multi-vendor-architecture.md`) — after adding or changing a `custom/` file, run `scripts/generate-vendor-wrappers.sh` to propagate it into all three mirrors so every vendor tool sees it.

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

## Why customer content never lives in the foundational repo's tracked history

`skills/*/custom/**` is gitignored in this repo (see `.gitignore`) except for placeholder files. Itential's own commits never contain real content under a `custom/` path, so pulling an upstream update can never conflict with or overwrite a customer's override — there's nothing there to conflict with.

## How to consume this repo, and how to update each way

There are two ways to get these skills onto your machine, and the update procedure — and how safely it preserves your `custom/` content — genuinely differs per vendor. Don't assume one vendor's behavior generalizes to another; the findings below were each verified directly, not inferred.

### Path A — Installed via a vendor's plugin/marketplace mechanism

```bash
# Claude Code
/plugin marketplace add itential/builder-skills
/plugin install itential-builder@itential-builder
/plugin update itential-builder@itential-builder      # to update

# Codex CLI
codex plugin marketplace add itential/builder-skills
codex plugin add itential-builder@itential-builder
codex plugin marketplace upgrade itential-builder      # to update, then re-run `plugin add`

# Cursor
# cursor.com/marketplace → Add to Cursor; update via the marketplace UI

# GitHub Copilot / any of 40+ agents gh skill supports
gh skill install itential/builder-skills --agent <agent> --all
gh skill install itential/builder-skills --agent <agent> --all --force   # to update
```

**Whether your `custom/` content survives an update through this path depends entirely on the vendor:**

| Vendor | Verified behavior | Does `custom/` survive an update? |
|---|---|---|
| **Claude Code** | Its plugin marketplace mechanism keeps each installed marketplace as a real local git clone (`.git/` and all), updated via `git fetch`/`merge` from upstream — not a wholesale re-download. Confirmed directly: planted an untracked file in an installed marketplace clone, ran a real fetch+merge that pulled in genuine new upstream commits, and the untracked file came through completely untouched. | **Yes.** `git` only touches what it's syncing, never a file sitting outside its tracked set — and `custom/**/*` content is exactly that: untracked (gitignored) in this repo. |
| **Codex CLI** | Confirmed directly the opposite: `codex plugin marketplace upgrade` + `codex plugin add` creates a **new, separate version-tagged cache directory** and deletes the old one entirely. Planted a customization file in a v1.6.7 install, bumped to v1.6.8, and the entire v1.6.7 directory — customization included — was gone. | **No, never**, tracked or not. There is no durable in-place customization for a Codex plugin install. Use Path B if you're on Codex and want customization to survive updates. |
| **Cursor** | Not independently verified this session — the marketplace UI's update mechanism internals aren't published. | **Unknown — don't rely on it.** Use Path B for a guarantee. |
| **GitHub Copilot** | Not independently verified for `copilot plugin update`/`gh skill install --force`'s internals. However, Copilot also reads `.github/skills/`, `.agents/skills/`, and `.claude/skills/` directly from a local clone with **no plugin manager involved at all** — Path B works natively with zero extra tooling. | **Unknown via the plugin path — but Path B is trivially available**, so prefer it if customization matters to you. |

### Path B — Clone or fork directly (the only cross-vendor guarantee)

This is the **only path with a verified durability guarantee for every vendor**, because it relies solely on each vendor's local-project skill discovery (`.claude/skills/`, `.agents/skills/`, `.github/skills/` — see `docs/vendor-install.md`), not on any vendor's divergent package manager.

```bash
git clone https://github.com/itential/builder-skills.git
# or, if you want your own remote to push customizations to:
gh repo fork itential/builder-skills --clone
```

Add your `org/`/`team/`/`dev/` files under the relevant skills' `skills/<name>/custom/` folders as usual, then run `scripts/generate-vendor-wrappers.sh` to propagate them into the three vendor mirrors. By default `custom/` files are gitignored (per this repo's `.gitignore`), so they exist on your disk but `git status` won't offer to commit them — fine for solo, local-only customization.

**If you want your `org/`/`team/` files version-controlled and shared with your team**, force-track them past the ignore rule (no need to edit `.gitignore` itself):

```bash
git add -f skills/iag/custom/org/naming-conventions.md
git commit -m "org: add IAG naming convention"
```
Once a file is tracked this way, normal `git add`/`git commit` works on it going forward — `git` doesn't re-apply `.gitignore` to files it's already tracking.

**Protect those tracked files from ever being touched by an upstream merge.** This repo ships a `.gitattributes` rule for exactly this at the root:
```
skills/*/custom/** merge=ours
```
Enable it once per clone:
```bash
git config merge.ours.driver true
```

**To update from Itential's upstream, run `scripts/update-fork.sh`** — it fetches upstream, rebases (or merges, with `--merge`) your fork on top, regenerates the three vendor mirrors, validates them, and commits the regeneration if anything changed:

```bash
scripts/update-fork.sh                 # rebase onto upstream/main (default)
scripts/update-fork.sh --merge         # merge instead of rebase
scripts/update-fork.sh --branch v1.7.0 # pull from a specific branch/tag
```

Or do it by hand:
```bash
git remote add upstream https://github.com/itential/builder-skills.git   # one-time
git fetch upstream
git merge upstream/main            # or: git rebase upstream/main
scripts/generate-vendor-wrappers.sh
scripts/check-vendor-skills.sh
```

Because Itential's own commits never touch `custom/` paths, and your `merge=ours` rule protects any of your own tracked files there even if that ever changed, this should be conflict-free by construction — you're not depending on manual conflict resolution to keep your customizations intact.
