# github-backup.sh — quick info

Small Bash script to download all GitHub repositories (public, private and archived) for a user.

Prerequisites: bash, curl, jq. Create a PAT with `repo` scope and set it in the script or via environment variable `AUTHORIZATION_TOKEN`.

Configuration (top of `github-backup.sh`):
- `AUTHORIZATION_TOKEN` — personal access token
- `USER` — GitHub username (or org if you adapt the URL)
- `WORK_FOLDER` — backup root (default `./tmp`)

Quick run:

```bash
chmod +x github-backup.sh
AUTHORIZATION_TOKEN="ghp_xxx" USER="myuser" WORK_FOLDER="./backups" ./github-backup.sh
```

Notes:
- The script pages the API (100 repos/page), downloads repository file trees and stores them under `WORK_FOLDER/current/<owner--repo>`.
- Previous run copies are moved to `WORK_FOLDER/archived` and `.last-updated` files are used to skip unchanged repos.
- For organizations change the API endpoint to `/orgs/ORG/repos?type=all` and set an `ORG` variable.

That's it — run the script in Bash (WSL/Git Bash on Windows) and check `WORK_FOLDER` for results.

