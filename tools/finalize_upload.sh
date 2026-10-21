#!/usr/bin/env bash
# The whole block-cell upload in one command, for the Mac (Decision B47; Overnight job 40). Run from anywhere in the repo:
#
#   tools/finalize_upload.sh
#
# 1. checks the Open Cloud key is in this shell (ROBLOX_OPEN_CLOUD_KEY or ROBLOX_API_KEY) without printing it, and the creator
#    (ROBLOX_CREATOR_USER_ID or ROBLOX_CREATOR_GROUP_ID; when neither is set, Ethan's public user id from docs/vault Handoff)
# 2. plans: python3 -I tools/upload_assets.py --blocky --dry-run
# 3. uploads: --blocky (the block-cell models, their sheets, the pixel sprites and the world tiles; what has an id is skipped),
#    which resolves the Image ids and runs the fill. A file whose content changed since its upload (the ids files keep a sha256)
#    goes up again without --redo. The Image ids resolve through Open Cloud asset delivery with the key (it needs the scope
#    legacy-asset:manage; Launch-Steps step 2), else the anonymous route. Exit 3 there means every upload went through but some
#    Image ids are not resolved yet (moderation, or the scope missing): the script goes on and says how to finish at the end.
# 4. fills again (--fill-blocky; a no-op when step 3 filled) so the data files match the ids files
# 5. checks: analyze, tests, lint, data lint, model_assets --check, rigs --check, export_models --check
# 6. prints a summary and the git commands to commit and push the ids
#
# It stops at the first failure. It never prints the key, never writes it, never publishes and spends no Robux. Running it
# again is safe: nothing already uploaded goes up twice.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
export PATH="$HOME/.rokit/bin:$HOME/.local/bin:$PATH"

step() { printf '\n== %s\n' "$*"; }
fail() { printf '\nfinalize_upload: stopped at "%s"; fix it and run tools/finalize_upload.sh again (nothing uploaded goes up twice)\n' "$1" >&2; exit 1; }

step "1/6 key and creator"
if [[ -z "${ROBLOX_OPEN_CLOUD_KEY:-}" && -z "${ROBLOX_API_KEY:-}" ]]; then
  echo "finalize_upload: ROBLOX_OPEN_CLOUD_KEY is not set in this shell. It lives only in the Mac's shell (~/.zshrc), never in" >&2
  echo "the repo; open a new terminal or run: source ~/.zshrc" >&2
  exit 2
fi
echo "key: set (not shown)"
if [[ -z "${ROBLOX_CREATOR_USER_ID:-}" && -z "${ROBLOX_CREATOR_GROUP_ID:-}" ]]; then
  export ROBLOX_CREATOR_USER_ID=1492992374 # Ethan (EDankashin), the experience's owner; a public user id, not a secret
  echo "creator: user $ROBLOX_CREATOR_USER_ID (default: Ethan)"
else
  echo "creator: ${ROBLOX_CREATOR_USER_ID:+user $ROBLOX_CREATOR_USER_ID}${ROBLOX_CREATOR_GROUP_ID:+group $ROBLOX_CREATOR_GROUP_ID}"
fi

step "2/6 plan (dry run)"
python3 -I tools/upload_assets.py --blocky --dry-run || fail "plan"

step "3/6 upload, resolve the Image ids, fill"
set +e
python3 -I tools/upload_assets.py --blocky
UPLOAD=$?
set -e
RESOLVE_PENDING=0
case "$UPLOAD" in
  0) ;;
  3) RESOLVE_PENDING=1; echo "(some Image ids are not resolved yet; going on, the steps to finish are at the end)" ;;
  *) fail "upload (exit $UPLOAD)" ;;
esac

step "4/6 fill"
python3 -I tools/upload_assets.py --fill-blocky || fail "fill"

step "5/6 checks"
./tools/analyze.sh || fail "analyze"
./tools/test.sh || fail "tests"
./tools/lint.sh || fail "lint"
python3 -I tools/lint_data.py || fail "data lint"
python3 -I tools/model_assets.py --check || fail "model_assets --check"
python3 -I tools/blocky/rigs.py --check || fail "rigs --check"
python3 -I tools/blocky/export_models.py --check || fail "export_models --check"

step "6/6 summary"
python3 -I tools/upload_assets.py --blocky --dry-run | grep -E '^(block-cell folders|blocky dry run|stays 0|dry run)' || true
FILES=(assets/models/asset_ids.json assets/models/image_ids.json assets/icons/asset_ids.json
       assets/textures/blocky_tiles/asset_ids.json tools/studio/install_models.luau src/shared/data)
git status --short -- "${FILES[@]}"
if [[ "$RESOLVE_PENDING" == 1 ]]; then
  cat <<'EOF'

Some Image ids are still missing (a Decal in moderation, or the key lacking the scope legacy-asset:manage). Commit what is
here now. If the upload step said "Open Cloud asset delivery refused the key": add that scope to the key (Launch-Steps step 2)
and run tools/finalize_upload.sh again; it resolves them. Otherwise (or without the scope) finish with the Studio route when
the Decals are approved:
  python3 -I tools/upload_assets.py --emit-decals-luau | pbcopy
  (paste between the PASTE markers of tools/studio/resolve_decals.luau, run it in Studio in Edit mode, save the Output to a file)
  python3 -I tools/upload_assets.py --from-studio <that file>
  tools/finalize_upload.sh          (uploads nothing, fills the new Image ids, runs the checks again)
EOF
fi
cat <<'EOF'

All checks passed. Commit and push the ids:
  git add assets/models/asset_ids.json assets/models/image_ids.json assets/icons/asset_ids.json tools/studio/install_models.luau src/shared/data
  git add assets/textures/blocky_tiles/asset_ids.json 2>/dev/null || true
  git commit -m "Upload: block-cell models, sheets, sprites and tiles; ids filled (B47)"
  git push origin claude/alien-system-research
EOF
