# MacanOS development workflow

- Before changing code, read `ROADMAP.md` and `HANDOFF.md`, then inspect the current branch, checkpoint commit, and Git status.
- Resume from the verified checkpoint. Preserve unrelated work and make incremental changes within the authorized milestone.
- Run the relevant Debian WSL2 checks. Use `sh scripts/check.sh` for the full desktop suite and save generated evidence under `artifacts/`.
- Before finishing, update the validation report, roadmap and handoff with actual results, remaining blockers, and the exact next task.
- Stage explicit paths for local checkpoints. Exclude the isolated v0.6 checkout, builds, temporary evidence, and unrelated files.
- Preserve Git history and original design and recovery assets. Pushes and merges require explicit approval.
