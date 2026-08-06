# GitHub Actions — Feature Tour

A deliberately small repo that exercises the GitHub Actions concepts that matter,
with nothing deployed anywhere. Every job is `echo` and `sleep`; the point is the
mechanics, not the work.

Built as a study artifact while moving from GitLab CI. Each concept is annotated
inline with its GitLab equivalent.

---

## What's here

```
.github/
  workflows/
    demo.yml               # the feature tour — 7 jobs
    reusable-deploy.yml    # on: workflow_call
    scheduled.yml          # cron + timezone
  actions/
    greet/action.yml       # composite action
  dependabot.yml           # keeps action pins fresh
deps.lock                  # feeds the cache key via hashFiles()
```

---

## Concept → where to look

| Concept | File · job | GitLab equivalent |
|---|---|---|
| Triggers, path filters | `demo.yml` · `on:` | `only` / `except` / `rules` |
| Typed manual inputs | `demo.yml` · `workflow_dispatch` | `when: manual` + variables |
| **Booleans arrive as strings** | `demo.yml` · job 1 | — (a real trap) |
| Contexts (`github`, `runner`, `needs`) | `demo.yml` · job 1 | `CI_*` variables |
| `$GITHUB_OUTPUT` / `$GITHUB_ENV` | `demo.yml` · job 1 | `dotenv` artifacts |
| `$GITHUB_STEP_SUMMARY` | everywhere | — (no equivalent) |
| Dynamic matrix via `fromJSON` | `demo.yml` · jobs 1→2 | `parallel: matrix` |
| Matrix `include` / `fail-fast` | `demo.yml` · job 2 | `parallel: matrix` |
| Cache + `restore-keys` | `demo.yml` · job 2 | `cache:` |
| Artifacts up/download | `demo.yml` · jobs 2, 7 | `artifacts:` (but automatic there) |
| Composite action | `.github/actions/greet` | `extends:` / anchors |
| Container job + services | `demo.yml` · job 3 | `image:` + `services:` |
| **OIDC token claims** | `demo.yml` · job 4 | `id_tokens:` |
| **Script injection & the safe pattern** | `demo.yml` · job 4 | same risk, same fix |
| `permissions:` scoping | `demo.yml` · job 4 | `CI_JOB_TOKEN` scope |
| `outcome` vs `conclusion` | `demo.yml` · job 5 | `allow_failure` |
| `if:` / `always()` / `failure()` | `demo.yml` · job 5 | `when:` |
| Reusable workflow | `reusable-deploy.yml` | `include:` |
| Environment gate + scoped secrets | `reusable-deploy.yml` | protected environments |
| Concurrency (cancel vs queue) | both | `interruptible` / `resource_group` |
| Scheduled runs + `timezone:` | `scheduled.yml` | pipeline schedules |
| DAG via `needs:` | `demo.yml` throughout | `stages:` / `needs:` |

---

## Run it

```bash
gh workflow run "00 · Feature Tour" \
  -f target_env=production \
  -f release_name='hello world' \
  -f run_slow_tests=true

gh run watch
```

Or use the **Actions** tab → *00 · Feature Tour* → **Run workflow**.

---

## Five things to actually look at afterwards

1. **The run summary page.** Four jobs write to `$GITHUB_STEP_SUMMARY`. There's no
   GitLab equivalent and it's genuinely useful — build reports, test results,
   diffs, anything you'd otherwise dig out of logs.

2. **Job 4's OIDC claims.** The `sub` value is what an AWS/Azure/GCP trust policy
   matches on. Check which format this repo got:
   - `repo:OWNER/REPO:ref:refs/heads/main` — the old, name-based form
   - `repo:OWNER@123456/REPO@456789:ref:...` — the immutable form, for repos
     created after 15 July 2026

   The migration trap: trust policies written for the old form silently stop
   matching newly created repos, and the first deploy fails looking like a
   permissions bug.

3. **Re-run the workflow.** Job 2 flips from cache MISS to cache HIT. Then edit
   `deps.lock`, push, and watch it miss again — the key tracks the lockfile hash.

4. **The job graph.** Jobs 2–5 run in parallel because they only depend on job 1.
   There are no stages; the shape comes entirely from `needs:`.

5. **Job 7 downloads artifacts.** That's the only way files crossed a job boundary.
   `needs:` moved ordering and strings — nothing else.

---

## Optional: see the approval gate

1. Settings → Environments → **New environment** → `production`
2. Add yourself under **Required reviewers**
3. Re-run with `target_env=production`

Job 6 now pauses and waits for you to approve. That's the Actions answer to
"how do you gate production" — and the approval, the branch rule, and the secret
scope are one object rather than three settings.

---

## Deliberately not enabled

Two features are recent enough to be worth verifying against current docs before
use. Both are noted in comments at the bottom of `demo.yml`:

- **Parallel steps** (`background` / `wait` / `cancel` / `parallel`) — June 2026
- **`$/` self-repository syntax** — July 2026, needs runner ≥ 2.336.0

---

## Production differences

This repo is a teaching artifact. Three things would change for real work:

- **Pin every action to a full commit SHA**, not a tag. `@v5` is mutable — the
  owner can move it and you run new code with no change on your side. Dependabot
  (already configured here) turns pins into reviewable PRs.
- **Org-level allow-list** of permitted actions — the CI equivalent of registry
  admission policy.
- **Branch protection on `.github/workflows/`** plus CODEOWNERS. Anyone who can
  push a workflow can read any secret that branch can reach.
