# Git Workflow

## Intended Branching

Use one focused branch per reviewable change, for example `feature/vehicle-csv-report`, `feature/lot-capacity`, and `feature/parts-shortages`. Keep commits descriptive and allow PR reviewers to follow the implementation in order. Open a pull request against the repository's default branch, fill in `.github/pull_request_template.md`, wait for CI, then merge without squash so the reviewable commits remain visible.

## Merge Conflict Exercise Status

A genuine merge conflict has **not** yet been created and resolved in this work session. This document does not claim otherwise. The local repository started with no commits on `main`, so the exercise must happen after the first branch commit and a base branch exist.

When performed, record the actual branch names, conflicting file, competing intent, resolution, and commands here. Do not manufacture a conflict description or screenshot. A normal way to perform the exercise is to make two short-lived branches that edit the same documentation heading differently, commit each, merge one into the other, resolve the conflict deliberately, rerun checks, and retain the resolution commit.

## Current Repository State

The implementation is on `feature/rails-foundation`. The GitHub remote is configured as `https://github.com/Dhanya562004/fleetops-pro.git`. No commits, push, PR, or CI run are claimed until verified.
