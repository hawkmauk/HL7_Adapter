## Software Development Lifecycle

This workflow describes how to move work from a GitHub issue through implementation into the `dev` and `main` branches.

### Per-issue development workflow

- **1. Take ownership of a GitHub issue**
  - Assign the issue to yourself and confirm scope, acceptance criteria, and milestone.

- **2. Start from the `dev` branch**
  - Fetch the latest changes and check out `dev`.

- **3. Create a feature branch for the issue**
  - Create a new local branch from `dev`, named after the issue (for example, `feature/issue-123-short-description`).

- **4. Implement the issue**
  - Make the required model, documentation, and/or code changes.
  - Keep commits small and focused; reference the issue ID in commit messages where appropriate.

- **5. Perform a dev review**
  - Run relevant tests, linters, and generators locally.
  - Self-review the diff to ensure changes are scoped to the issue and follow project conventions.

- **6. Push the branch to GitHub**
  - Push your feature branch to the remote repository.

- **7. Open a pull request into `dev`**
  - Create a PR from your feature branch into `dev`.
  - Link the PR to the GitHub issue (e.g. via “Closes #123” in the PR description).

- **8. Resolve review comments and conflicts**
  - Address review feedback.
  - Resolve any merge conflicts with `dev`, keeping `dev` as the source of truth.

- **9. Merge the pull request and close the issue**
  - Once approvals and checks pass, merge the PR into `dev`.
  - Ensure the issue is closed (either via the linked PR or manually) and that the PR description references the issue.

### Milestone completion and release promotion

- **1. Create a release tag on `dev`**
  - When a milestone is complete and `dev` is in a releasable state, create a version tag on `dev` (for example, `v0.1.0`).

- **2. Open a pull request from `dev` to `main`**
  - Create a PR merging `dev` into `main` for the tagged release.

- **3. Resolve any conflicts**
  - Resolve conflicts in favor of the intended release state on `dev`, unless there is a specific reason to override.

- **4. Merge the pull request into `main`**
  - After reviews and checks pass, merge the PR.
  - Confirm that CI/CD runs successfully on `main` and that release artifacts (e.g. docs) are published as expected.

