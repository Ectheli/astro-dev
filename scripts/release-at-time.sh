#!/usr/bin/env bash
set -euo pipefail

# Automated one-shot release job for the astro repository.
# Intended to run from systemd at a specific wall-clock time.

REPO_DIR="${REPO_DIR:-/home/miro/IOAA-Website/astro}"
BRANCH="${BRANCH:-master}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-Scheduled content release}"
LOCK_FILE="${LOCK_FILE:-/tmp/ioaa-astro-release.lock}"
LOG_FILE="${LOG_FILE:-$REPO_DIR/release.log}"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
  local msg="$1"
  printf '[%s] %s\n' "$(timestamp)" "$msg" | tee -a "$LOG_FILE"
}

fatal() {
  local msg="$1"
  log "ERROR: $msg"
  exit 1
}

ensure_git_identity() {
  if ! git var GIT_AUTHOR_IDENT >/dev/null 2>&1; then
    fatal "git author identity is not configured for this run; set GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL (and committer) in the systemd service or configure git user.name/user.email"
  fi
}

mkdir -p "$(dirname "$LOCK_FILE")"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  fatal "another release job is already running (lock: $LOCK_FILE)"
fi

if [[ ! -d "$REPO_DIR/.git" ]]; then
  fatal "repo directory is not a git repository: $REPO_DIR"
fi

cd "$REPO_DIR"
touch "$LOG_FILE"

log "starting scheduled release in $REPO_DIR"

if ! git diff --quiet || ! git diff --cached --quiet; then
  log "detected local changes to commit"
else
  log "no local changes found; exiting without push"
  exit 0
fi

ensure_git_identity

if ! git remote get-url origin >/dev/null 2>&1; then
  fatal "missing git remote 'origin'"
fi

log "fetching remote metadata"
git fetch --prune origin

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse "origin/$BRANCH" || true)"
BASE_HEAD="$(git merge-base HEAD "origin/$BRANCH" || true)"

if [[ -z "$REMOTE_HEAD" || -z "$BASE_HEAD" ]]; then
  fatal "could not inspect remote branch origin/$BRANCH"
fi

if [[ "$REMOTE_HEAD" != "$LOCAL_HEAD" ]]; then
  fatal "local HEAD is not equal to origin/$BRANCH; sync manually before scheduling"
fi

if [[ "$LOCAL_HEAD" != "$BASE_HEAD" ]]; then
  fatal "local branch has commits not on origin/$BRANCH; rebase manually before scheduling"
fi

log "staging and committing changes"
git add --all
git commit -m "$COMMIT_MESSAGE"

log "pushing to origin/$BRANCH"
git push origin "HEAD:$BRANCH"

NEW_HEAD="$(git rev-parse HEAD)"
log "release finished successfully at commit $NEW_HEAD"
