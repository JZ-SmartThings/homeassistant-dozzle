#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Bump HA Dozzle app version across the repo (run from project root).
# Usage:   ./update_version.sh <new_version>
#          ./update_version.sh <new_version> --tag-push
#
# Updated files:
#   1. dozzle/config.yaml     — version (manifest Supervisor / store)
#   2. dozzle/Dockerfile      — ARG BUILD_VERSION (default image label / local builds)
#
# Optional (if present):
#   3. README.md              — shields.io style version-vX.Y.Z-blue
#   4. dozzle/README.md       — same pattern if badge exists
#
# Commit message file (edit before committing):
#   5. commit-message.txt     — git commit -F commit-message.txt
#
# Options:
#   --tag-push   After bump: commit (if dirty), create tag v<NEW>, push branch & tag.
#
# Not auto-updated (do manually):
#   - dozzle/CHANGELOG.md
#   - ARG DOZZLE_VERSION in Dockerfile (upstream Dozzle binary — separate concern)
# ──────────────────────────────────────────────────────────────────────────────

set -e

# ── ANSI colors (disable if not a TTY) ───────────────────────────────────────
if [ -t 1 ]; then
  R="\033[0m"
  B="\033[1m"
  G="\033[32m"
  Y="\033[33m"
  C="\033[36m"
  M="\033[35m"
  RED="\033[31m"
else
  R="" B="" G="" Y="" C="" M="" RED=""
fi

# ── Repo root (script at repository root) ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
cd "$REPO_ROOT"

CONFIG_YAML="$REPO_ROOT/dozzle/config.yaml"
DOCKERFILE="$REPO_ROOT/dozzle/Dockerfile"
ROOT_README="$REPO_ROOT/README.md"
DOZZLE_README="$REPO_ROOT/dozzle/README.md"
COMMIT_MSG_FILE="$REPO_ROOT/commit-message.txt"

# ── Current version from dozzle/config.yaml ─────────────────────────────────
if [ ! -f "$CONFIG_YAML" ]; then
  echo -e "${RED}Error:${R} $CONFIG_YAML not found"
  exit 1
fi

CURRENT=$(grep -E '^version:' "$CONFIG_YAML" | head -1 | sed -n 's/^version:[[:space:]]*"\([^"]*\)".*/\1/p')
if [ -z "$CURRENT" ]; then
  CURRENT=$(grep -E '^version:' "$CONFIG_YAML" | head -1 | sed -n 's/^version:[[:space:]]*\([^[:space:]#]*\).*/\1/p')
fi
CURRENT=$(echo "$CURRENT" | tr -d '[:space:]')
if [ -z "$CURRENT" ]; then
  echo -e "${RED}Error:${R} could not read version from dozzle/config.yaml"
  exit 1
fi

# ── Args: new version + optional --tag-push ─────────────────────────────────
NEW=""
TAG_PUSH=""
for arg in "$@"; do
  if [ "$arg" = "--tag-push" ]; then
    TAG_PUSH="1"
  elif [ -z "$NEW" ]; then
    NEW="$arg"
  fi
done

if [ -z "$NEW" ]; then
  SUGGESTED=$(echo "$CURRENT" | awk -F. '{$NF=$NF+1; print $0}' OFS=.)
  echo ""
  echo -e "  ${B}Current version:${R} ${C}${CURRENT}${R}"
  echo ""
  echo "  Usage: $0 <new_version> [--tag-push]"
  echo ""
  echo "  Examples:"
  echo -e "    ${C}$0 ${SUGGESTED}${R}              # bump only"
  echo -e "    ${C}$0 ${SUGGESTED} --tag-push${R}   # bump + commit + tag + push"
  echo ""
  exit 0
fi

# ── sed in-place (macOS / Linux) ────────────────────────────────────────────
sedi() {
  local file="$1"
  shift
  sed -i.bak "$@" "$file" && rm -f "${file}.bak"
}

SEMVER_PATTERN='[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*'
CURRENT_ESC=$(echo "$CURRENT" | sed 's/\./\\./g')

# ═══════════════════════════════════════════════════════════════════════════
#  Version bump (skip file edits if already at NEW, unless only --tag-push)
# ═══════════════════════════════════════════════════════════════════════════

if [ "$NEW" = "$CURRENT" ] && [ -z "$TAG_PUSH" ]; then
  echo -e "${Y}Warning:${R} new version ($NEW) equals current ($CURRENT). Nothing to do."
  exit 0
fi

if [ "$NEW" != "$CURRENT" ]; then
  echo ""
  echo -e "${M}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo -e "${M}${B}  Bump HA Dozzle app: ${CURRENT} → ${NEW}${R}"
  echo -e "${M}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo ""
  echo -e "  ${B}── Version bump ──${R}"

  # 1. dozzle/config.yaml
  if [ -f "$CONFIG_YAML" ]; then
    sedi "$CONFIG_YAML" "s/^version:.*/version: \"${NEW}\"/"
    echo -e "  ${G}✓${R} dozzle/config.yaml        ${C}version: \"${NEW}\"${R}"
  else
    echo -e "  ${RED}✗${R} dozzle/config.yaml        ${RED}(missing)${R}"
  fi

  # 2. dozzle/Dockerfile — ARG BUILD_VERSION only (not DOZZLE_VERSION upstream)
  if [ -f "$DOCKERFILE" ]; then
    sedi "$DOCKERFILE" "s/^ARG BUILD_VERSION=.*/ARG BUILD_VERSION=${NEW}/"
    echo -e "  ${G}✓${R} dozzle/Dockerfile         ${C}ARG BUILD_VERSION=${NEW}${R}"
  else
    echo -e "  ${RED}✗${R} dozzle/Dockerfile         ${RED}(missing)${R}"
  fi

  # 3. README.md (root) — shields badge
  if [ -f "$ROOT_README" ] && grep -q "version-v${SEMVER_PATTERN}-blue" "$ROOT_README" 2>/dev/null; then
    sedi "$ROOT_README" "s/version-v${SEMVER_PATTERN}-blue/version-v${NEW}-blue/g"
    sedi "$ROOT_README" "s|releases/tag/v${SEMVER_PATTERN}|releases/tag/v${NEW}|g"
    sedi "$ROOT_README" "s/\`${CURRENT_ESC}\`/\`${NEW}\`/g"
    echo -e "  ${G}✓${R} README.md                 ${C}(badge / links)${R}"
  elif [ -f "$ROOT_README" ]; then
    echo -e "  ${Y}○${R} README.md                 ${Y}(no version-v*-blue badge)${R}"
  else
    echo -e "  ${Y}○${R} README.md                 ${Y}(not found)${R}"
  fi

  # 4. dozzle/README.md
  if [ -f "$DOZZLE_README" ] && grep -q "version-v${SEMVER_PATTERN}-blue" "$DOZZLE_README" 2>/dev/null; then
    sedi "$DOZZLE_README" "s/version-v${SEMVER_PATTERN}-blue/version-v${NEW}-blue/g"
    echo -e "  ${G}✓${R} dozzle/README.md          ${C}(badge)${R}"
  elif [ -f "$DOZZLE_README" ]; then
    echo -e "  ${Y}○${R} dozzle/README.md          ${Y}(no badge pattern)${R}"
  else
    echo -e "  ${Y}○${R} dozzle/README.md          ${Y}(not found)${R}"
  fi

  echo ""
  echo -e "  ${B}── commit-message.txt ──${R}"
  if [ -f "$COMMIT_MSG_FILE" ]; then
    if grep -qE "v${NEW}|${NEW}" "$COMMIT_MSG_FILE" 2>/dev/null; then
      echo -e "  ${G}✓${R} commit-message.txt        ${C}(mentions v${NEW})${R}"
    else
      echo -e "  ${Y}⚠${R} commit-message.txt        ${Y}(update for v${NEW})${R}"
    fi
  else
    cat > "$COMMIT_MSG_FILE" << CMEOF
release: v${NEW}

- <change 1>
- <change 2>
CMEOF
    echo -e "  ${G}✓${R} commit-message.txt        ${C}(template — edit before commit)${R}"
  fi

  echo ""
  echo -e "${G}${B}Done.${R} App version is now ${B}${NEW}${R}."
  echo ""
  echo -e "  ${B}── Also update manually ──${R}"
  echo -e "  ${C}  dozzle/CHANGELOG.md${R}"
  echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════
#  --tag-push
# ═══════════════════════════════════════════════════════════════════════════

do_commit_tag_push() {
  local branch

  if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Erreur :${R} la commande ${C}git${R} est introuvable (PATH)."
    echo -e "  Installez Git ou ouvrez un terminal où Git est disponible."
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}Erreur :${R} ce dossier n’est pas un dépôt Git (pas de ${C}.git${R} à cet endroit)."
    echo -e "  ${Y}Cause fréquente :${R} copie sur NAS / partage sans historique, ou script hors racine du clone."
    echo -e "  ${Y}Pistes :${R}"
    echo -e "    • ${C}git clone <url>${R} le dépôt puis relancer le script dans le clone."
    echo -e "    • Ou ${C}git init${R} à la racine du projet, ${C}git remote add origin …${R}, puis premier commit."
    echo -e "  Répertoire utilisé : ${C}$(pwd)${R}"
    return 1
  fi

  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [ "$branch" = "HEAD" ]; then
    echo -e "${RED}Erreur :${R} HEAD détaché — placez-vous sur une branche avant le push."
    echo -e "  Exemple : ${C}git checkout main${R} ou ${C}git switch main${R}"
    return 1
  fi
  if [ -z "$branch" ]; then
    echo -e "${RED}Erreur :${R} impossible de lire la branche courante (${C}git rev-parse${R})."
    return 1
  fi

  local tag_name="v${NEW}"

  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "  ${B}Uncommitted changes — staging and commit...${R}"
    git add -A
    if [ -f "$COMMIT_MSG_FILE" ] && grep -qE "v${NEW}|${NEW}" "$COMMIT_MSG_FILE" 2>/dev/null; then
      git commit -F "$COMMIT_MSG_FILE" || { echo -e "${RED}Commit failed.${R}"; return 1; }
      echo -e "  ${G}✓${R} Committed with ${C}commit-message.txt${R}"
    else
      git commit -m "release: v${NEW}" || { echo -e "${RED}Commit failed.${R}"; return 1; }
      echo -e "  ${G}✓${R} Committed ${C}release: v${NEW}${R} ${Y}(fallback — fix commit-message.txt next time)${R}"
    fi
    echo ""
  else
    echo -e "  ${G}✓${R} Working tree clean — no commit."
    echo ""
  fi

  if git rev-parse "$tag_name" >/dev/null 2>&1; then
    echo -e "  ${Y}⚠${R} Tag ${C}${tag_name}${R} exists locally."
  else
    git tag -a "$tag_name" -m "Release ${tag_name}" || { echo -e "${RED}Tag failed.${R}"; return 1; }
    echo -e "  ${G}✓${R} Tag ${C}${tag_name}${R} created."
  fi

  echo -e "  ${B}Pushing branch ${C}${branch}${R}...${R}"
  git push origin "$branch" || { echo -e "${RED}Push branch failed.${R}"; return 1; }
  echo -e "  ${G}✓${R} Branch pushed."

  if git ls-remote origin "refs/tags/${tag_name}" 2>/dev/null | grep -q .; then
    echo -e "  ${Y}○${R} Tag ${C}${tag_name}${R} already on remote — skip."
  else
    git push origin "$tag_name" || { echo -e "${RED}Push tag failed.${R}"; return 1; }
    echo -e "  ${G}✓${R} Tag ${C}${tag_name}${R} pushed."
  fi
  echo ""
  echo -e "  ${G}✓${R} Done."
  return 0
}

if [ -n "$TAG_PUSH" ]; then
  echo ""
  echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo -e "${C}${B}  Commit, tag and push (--tag-push)${R}"
  echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo ""
  do_commit_tag_push || exit 1
  exit 0
fi

# ═══════════════════════════════════════════════════════════════════════════
#  Manual next steps (no --tag-push)
# ═══════════════════════════════════════════════════════════════════════════

if [ "$NEW" != "$CURRENT" ]; then
  echo ""
  echo -e "${Y}→${R} Edit ${B}commit-message.txt${R} and ${B}dozzle/CHANGELOG.md${R} for v${NEW}."
  echo ""
  echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo -e "${C}${B}  Commands (copy / paste)${R}"
  echo -e "${C}${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo ""
  echo -e "  ${G}git add -A && git commit -F commit-message.txt && git push${R}"
  echo ""
  echo -e "  ${G}git tag -a v${NEW} -m \"Release v${NEW}\" && git push origin v${NEW}${R}"
  echo ""
  echo -e "  ${B}Or:${R} ${C}$0 ${NEW} --tag-push${R}"
  echo ""
fi
