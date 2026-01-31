# Repository Guidelines

## CRITICAL: Never Commit Directly to Main

**NEVER commit directly to the main branch.** All changes must go through pull requests.

When asked to commit changes:
1. Create a new branch first: `git checkout -b $USER/<feature-name>` (e.g., `jkakar/new-skill`)
2. Commit your changes to that branch
3. Push the branch and open a pull request
4. Return the PR URL to the user

This applies to ALL changes, no matter how small. No exceptions.

## Commit & PR Guidelines
- Keep commits focused, rebase on main, and run checks before pushing.
- PRs should note intent, affected files, and user-visible updates.
- Leave PRs in draft until CI succeeds.
