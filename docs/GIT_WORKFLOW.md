# Git Workflow

## Intended Branching

Use one focused branch per reviewable change, for example `feature/vehicle-csv-report`, `feature/lot-capacity`, and `feature/parts-shortages`. Keep commits descriptive and allow PR reviewers to follow the implementation in order. Open a pull request against the repository's default branch, fill in `.github/pull_request_template.md`, wait for CI, then merge without squash so the reviewable commits remain visible.

## Merge Conflict Exercise Status

Conflict exercise preparation: one branch records reviewer-facing guidance while another records the operational resolution. The outcome will be written after those edits collide in Git.

When performed, record the actual branch names, conflicting file, competing intent, resolution, and commands here. Do not manufacture a conflict description or screenshot. A normal way to perform the exercise is to make two short-lived branches that edit the same documentation heading differently, commit each, merge one into the other, resolve the conflict deliberately, rerun checks, and retain the resolution commit.

## Current Repository State

The implementation is on `feature/rails-foundation`. The GitHub remote is configured as `https://github.com/Dhanya562004/fleetops-pro.git`. No commits, push, PR, or CI run are claimed until verified.
