## Global Development Principles

### Simplicity First

- Simple > clever. Obvious > elegant.
- No abstraction > wrong abstraction. Abstract only after 3+ instances AND full understanding.
- Boring tech works; skeptical of new tech. Don't refactor without a measured problem.

### Chesterton's Fence

Before removing code: check `git log`/`git blame`, search for related issues/PRs, and articulate the code's purpose. **If you can't explain why it exists, don't touch it.** Red flags: "looks unnecessary", "we don't need this", "just tech debt".

### Code Changes

- Leave 2 similar functions alone until you need a 3rd.
- No large refactors unless forced. Don't optimize without measurement.
- Bug fixes: change the fewest lines that solve the problem.
- Exceptions (when above rules yield): measured perf problem, clear pain point, or security issue.
- Check present state before making changes. Read files before creating them, check if branches exist before creating them, and verify current configurations before modifying them.

### Git Commits

- Never commit to default branches (main/master/trunk); branch off `origin/HEAD` with a relevant name.
- When fixing functionality from the previous commit, prefer amending existing commits for functionality fixes; update the message to note the fix rather than stacking follow-ups.
- Message format: subject/body with dash-list body. Subject < 51 chars, imperative. Body lines < 73 chars, focused on `why` over `how`/`what`. Wrap filenames/identifiers/snippets in backticks. Never add `Co-Authored-By` lines.
- Use real newlines, never literal `\n`. For multi-line messages use `git commit -F - <<'EOF' ... EOF` (not `-m`). Verify with `git log -1 --format=%B`.
- Disable signing inside Claude: `git -c commit.gpgsign=false commit [--amend] ...`.
- If a commit fails unexpectedly, fail fast and report the exact command, exit status, and stderr — don't paper over it.

### General

- Inline variables/functions used only once. Follow YAGNI/DRY. Keep diffs small.
- Never remove comments. Prefer self-documenting code over explanatory comments.
- Re-read files after each prompt; preserve user edits.
- Red-green TDD for bug fixes and regressions.
- Use `&>/dev/null` instead of `>/dev/null 2>&1`.
- May run as `sandvault-<user>` inside a macOS sandbox.
- When asked to make targeted changes, stay focused on the specific scope. Do not broaden the scope (e.g., scanning all directories when only one is requested, adding recursive finds that pull in node_modules, or making unsolicited fixes to unrelated code).

### Communication Style

- Motivating but realistic — no toxic positivity, shame, or sycophancy.
- Clear, concise descriptions. Explain the `why` behind choices.
- Use ASCII emoticons or nerd font symbols for expression.
