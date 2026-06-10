## Session naming

- `/rename` is a UI-only command — you cannot invoke it via the Skill tool or any other tool. Only the user can run it.
- After the first substantive exchange (once the task is clear), **suggest** a rename to the user by outputting a single line they can copy-paste, e.g.: `Suggested session name: /rename cloudflare-waf-onetrust-allowlist`. Do not attempt to run `/rename` yourself.
- Keep titles under ~40 chars, kebab-case, descriptive of the task not the project.
- Only suggest once per session unless the task pivots meaningfully.

## Pull requests Descriptions

- Always use /jobber-pr skill
- Use an existing PR template if one is available.
- PR title: one line, imperative mood, <72 chars
- Body: 5 bullets max — what changed, why, any risks
- Keep the description concise and easy to read. Avoid excessive bullets, headings, or formatting. No fluff, no "This PR introduces...", no summaries of every commit
- Focus on why the change was made, not a list of what changed. Only mention specific files if they are necessary for the explanation.
- Link the issue, nothing else
- Always open pull requests in draft mode so they can be reviewed before requesting team feedback.

## Code Comments

- Do NOT add comments to code. Especially avoid large comment blocks and comments that restate what the code obviously does.
- Only add a comment when it is genuinely necessary (e.g. non-obvious rationale, a workaround, or context that cannot be inferred from the code) and keep it to a single concise line.
- Match the surrounding file's existing comment density and style.

## GIT Commits

- Keep commit messages precise and small: a concise subject line capturing the _why_. Omit detailed bodies, bullet lists, ticket IDs/links, and file-by-file summaries — that level of detail belongs in the PR description, not the commit.
- Always ensure you use verified commits. If pre-commits are available, always run the full suite against the files that have changed before committing.
- Never add `Co-Authored-By: Claude` (or any Claude co-author trailer) to commit messages. The engineer is the author of record.

## AWS CLI & Profiles

- **Always ask before running any `aws` CLI command.** Never invoke it (or the `aws-api` MCP) unprompted — confirm the intent and the target profile/account first.
- **SSO must be initiated first.** Auth is SSO-only (start URL `https://d-9067538235.awsapps.com/start`, `us-east-1`). If a call fails with expired/missing credentials, stop and ask me to log in — suggest I run `! assume <profile>` myself (it's an interactive login that opens a browser).
- **I use Granted/`assume` to set the profile in my shell**, not raw `AWS_PROFILE` exports or `aws sso login`. Profiles are synced from the `GetJobber/granted-profile-registry` (registries: `On-Call`, `Base`, `McCloud`).
- **Prefix every `aws` command with `AWS_PROFILE=<profile>` inline** (e.g. `AWS_PROFILE=systems-teams-readonly-prod aws ec2 describe-instances`). Each Bash call is a fresh shell, so `assume`'s exported env vars don't persist across my tool calls — setting it inline guarantees the right profile is used and makes the target explicit for me to confirm.
- **Before using a profile, figure out what it grants** so you pick the right one:
  - Read the synced profile defs locally first: `~/.aws/config` (each `[profile …]` lists `granted_sso_account_id` + `granted_sso_role_name`) and the cached registry at `~/.granted/registries/<registry>/`. Map account IDs → accounts via `~/workspace/terraform-aws-accounts/` (per-account dirs under `jobberorg/`).
  - Only if those are stale/missing, fall back to the repo: `gh repo view GetJobber/granted-profile-registry` (per Code Lookups, prefer local + `gh` over WebFetch).
- Profile naming signals scope — e.g. `*-prod*`/`production*` = prod, `staging*`/`*-dev*` = nonprod, `*-readonly-*` = read-only, `*-terraform-access`/`*-global-access` = broad. Treat anything prod as higher-risk and confirm explicitly.

## Code Lookups

- **Look in `~/workspace/` first.** Most Jobber repos are already cloned locally. Before any `WebFetch`, `gh api` content lookup, or other remote fetch, check `~/workspace/<repo>/` and pull latest from the default branch.
- If the repo isn't local, prefer the repo-sync skill in `~/workspace/agent-toolbox` over manual cloning. If that fails (known SSH/HTTPS scheme mismatches), fall back to `gh repo clone GetJobber/<repo> ~/workspace/<repo>` — `gh` respects whichever remote scheme is configured.
- **Prefer `gh` CLI over `WebFetch` for GitHub operations** (issues, PRs, comments, file contents, repo metadata). Faster, authenticated, and works for private repos. Reserve `WebFetch` for non-GitHub documentation.
- Never hardcode SSH (`git@github.com:`) or HTTPS (`https://github.com/`) clone URLs in scripts or examples — use `gh repo clone <org>/<repo>` which honors the user's git config.
