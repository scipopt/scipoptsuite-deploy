#!/usr/bin/env bash
set -euo pipefail

WORKFLOW=".github/workflows/build_binaries.yml"

# --- Pre-flight checks ---

if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI is not installed. Install it from https://cli.github.com"
    exit 1
fi

if ! gh auth status &>/dev/null; then
    echo "Error: gh CLI is not authenticated. Run 'gh auth login' first."
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Error: working directory has uncommitted changes. Commit or stash them first."
    exit 1
fi

# --- Helper functions ---

# Read current default for a given input key
current_default() {
    sed -n "/${1}:/,/default:/{s/.*default: \"\(.*\)\"/\1/p;}" "$WORKFLOW"
}

# Validate version format and that the tag exists upstream
validate_version() {
    local version="$1" repo="$2" tag="$3"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: '$version' is not a valid version (expected X.Y.Z)"
        exit 1
    fi
    if ! gh api "repos/${repo}/git/ref/tags/${tag}" &>/dev/null; then
        echo "Error: tag '${tag}' not found in ${repo}"
        exit 1
    fi
}

# Prompt for a version, keeping current value if enter is pressed.
# Writes result to the variable named by $5.
prompt_version() {
    local label="$1" key="$2" repo="$3" tag_prefix="$4" outvar="$5"
    local current
    current=$(current_default "$key")
    read -rp "${label} [${current}]: " value
    value="${value:-$current}"
    validate_version "$value" "$repo" "${tag_prefix}${value}"
    printf -v "$outvar" '%s' "$value"
}

# --- Prompt for versions ---

echo "This script will:"
echo "  1. Prompt for new component versions (press enter to keep current)"
echo "  2. Create a release-X.Y.Z branch from main"
echo "  3. Update version defaults in build_binaries.yml, commit, and push"
echo "  4. Open a PR and trigger the build workflow"
echo "  5. Docker deploy will auto-trigger after builds succeed"
echo ""
echo "Current versions from ${WORKFLOW}:"
echo ""

OLD_SCIP=$(current_default "scip_version")
OLD_SOPLEX=$(current_default "soplex_version")
OLD_GCG=$(current_default "gcg_version")
OLD_IPOPT=$(current_default "ipopt_version")

prompt_version "SCIP" "scip_version" "scipopt/scip" "v" SCIP_VERSION
prompt_version "SoPlex" "soplex_version" "scipopt/soplex" "v" SOPLEX_VERSION
prompt_version "GCG" "gcg_version" "scipopt/gcg" "v" GCG_VERSION
prompt_version "IPOPT" "ipopt_version" "coin-or/Ipopt" "releases/" IPOPT_VERSION

echo ""
echo "Versions: SCIP=${SCIP_VERSION} SoPlex=${SOPLEX_VERSION} GCG=${GCG_VERSION} IPOPT=${IPOPT_VERSION}"
read -rp "Proceed? [Y/n] " confirm
[[ "${confirm:-Y}" =~ ^[Nn] ]] && exit 0

# --- Create release branch ---

BRANCH="release-${SCIP_VERSION}"

git checkout main
git pull --ff-only

if git show-ref --verify --quiet "refs/heads/${BRANCH}" || git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
    echo "Error: branch '${BRANCH}' already exists locally or on remote."
    echo "Delete it first if you want to recreate it, or check it out manually."
    exit 1
fi

git checkout -b "$BRANCH"

# --- Update version defaults ---

update_default() {
    local key="$1" value="$2" file="$3"
    sed -i.bak "/${key}:/,/default:/{s/default: \".*\"/default: \"${value}\"/;}" "$file"
    rm -f "${file}.bak"
}

update_default "scip_version" "$SCIP_VERSION" "$WORKFLOW"
update_default "soplex_version" "$SOPLEX_VERSION" "$WORKFLOW"
update_default "gcg_version" "$GCG_VERSION" "$WORKFLOW"
update_default "ipopt_version" "$IPOPT_VERSION" "$WORKFLOW"

# --- Commit and push ---

changes=()
[[ "$SCIP_VERSION" == "$OLD_SCIP" ]] || changes+=("SCIP to ${SCIP_VERSION}")
[[ "$SOPLEX_VERSION" == "$OLD_SOPLEX" ]] || changes+=("SoPlex to ${SOPLEX_VERSION}")
[[ "$GCG_VERSION" == "$OLD_GCG" ]] || changes+=("GCG to ${GCG_VERSION}")
[[ "$IPOPT_VERSION" == "$OLD_IPOPT" ]] || changes+=("IPOPT to ${IPOPT_VERSION}")

if [[ ${#changes[@]} -eq 0 ]]; then
    echo "No versions changed. Aborting."
    git checkout main
    git branch -d "$BRANCH"
    exit 0
fi

MSG="update $(IFS=', '; echo "${changes[*]}")"

git add "$WORKFLOW"
git commit -m "$MSG"
git push -u origin "$BRANCH"

# --- Create PR and trigger build workflow ---

echo "Creating pull request..."
PR_URL=$(gh pr create --title "$MSG" --body "Automated release branch created by release.sh" --base main)

echo "Triggering build workflow..."
gh workflow run build_binaries.yml --ref "$BRANCH"

echo ""
echo "Done! Release branch '${BRANCH}' created and builds triggered."
echo "PR: ${PR_URL}"
echo "Docker deploy will run automatically after builds succeed."
echo "Monitor at: gh run list --workflow=build_binaries.yml"
