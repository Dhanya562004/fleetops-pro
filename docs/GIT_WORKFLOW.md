# Git Workflow

## Intended Branching

Use one focused branch per reviewable change, for example `feature/vehicle-csv-report`, `feature/lot-capacity`, and `feature/parts-shortages`. Keep commits descriptive and allow PR reviewers to follow the implementation in order. Open a pull request against the repository's default branch, fill in `.github/pull_request_template.md`, wait for CI, then merge without squash so the reviewable commits remain visible.

## Merge Conflict Exercise Status

The merge conflict was created and resolved locally in this work session.

- Target branch: `feature/rails-foundation` (`9f9ccaf`)
- Merged branch: `exercise/conflict-a` (`3d6938c`)
- Conflicting file: `docs/GIT_WORKFLOW.md`
- Competing intent: both branches replaced this section's status sentence with different descriptions of the same conflict exercise.
- Resolution: kept one factual summary of the branches, competing edits, and final resolution rather than preserving either temporary status sentence.
- Commands: `git switch -c exercise/conflict-a`, commit the first edit, switch back to `feature/rails-foundation`, commit the competing edit, then `git merge exercise/conflict-a` and resolve the file.

The merge is recorded on the feature branch as a genuine resolution commit. The temporary branch remains local; the final feature branch contains the resolved documentation.

## Current Repository State

The implementation is on `feature/rails-foundation`, pushed to `https://github.com/Dhanya562004/fleetops-pro.git`. Pull request #1 is open and mergeable. Its latest CI run passed on commit `ad638d4`.
