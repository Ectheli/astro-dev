#!/bin/bash
set -e

# Build and deploy the Hugo site to astro (deployment repo).
# Run from astro-dev directory.
# Preserves CNAME in the deploy folder (for GitHub Pages custom domain).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${SCRIPT_DIR}/../astro"

cd "$SCRIPT_DIR"

# Build with production env so robots.txt allows all
echo "Building site (HUGO_ENV=production)..."
HUGO_ENV=production hugo

if [[ ! -d "$DEPLOY_DIR" ]]; then
  echo "Error: astro (deployment folder) not found at $DEPLOY_DIR"
  exit 1
fi

# Preserve CNAME (GitHub Pages custom domain)
CNAME_BACKUP=""
[[ -f "$DEPLOY_DIR/CNAME" ]] && CNAME_BACKUP=$(cat "$DEPLOY_DIR/CNAME")

# Sync public/ to deploy folder, excluding .git
echo "Syncing to astro..."
rsync -av --delete public/ "$DEPLOY_DIR/" --exclude='.git'

# Restore CNAME
[[ -n "$CNAME_BACKUP" ]] && echo "$CNAME_BACKUP" > "$DEPLOY_DIR/CNAME"

echo "Done. To publish: cd ../astro && git add -A && git commit -m 'Deploy' && git push"
