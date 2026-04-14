#!/bin/bash
set -e

APP_DISPLAY="Magicer"
BINARY_NAME="WorkStop"
VERSION=$(cat VERSION | tr -d '[:space:]')
DMG_NAME="${APP_DISPLAY}-${VERSION}.dmg"
TMP_DIR="/tmp/${APP_DISPLAY}_dmg_tmp"
DIST_DIR="dist"

echo "▶ Version: ${VERSION}"

# Update Info.plist version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" Info.plist

echo "▶ Building app..."
./build.sh

echo "▶ Cleaning up old DMGs in project root..."
ls *.dmg 2>/dev/null | grep -v "^${DMG_NAME}$" | xargs rm -f || true

echo "▶ Creating DMG..."
rm -f "${DMG_NAME}"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cp -r "${BINARY_NAME}.app" "${TMP_DIR}/${APP_DISPLAY}.app"
ln -s /Applications "${TMP_DIR}/Applications"

hdiutil create \
  -volname "${APP_DISPLAY} ${VERSION}" \
  -srcfolder "${TMP_DIR}" \
  -ov \
  -format UDZO \
  -o "${DMG_NAME}"

rm -rf "${TMP_DIR}"

echo "▶ Saving to dist/..."
mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}"/*.dmg
cp "${DMG_NAME}" "${DIST_DIR}/${DMG_NAME}"

echo "▶ Copying to Desktop..."
rm -f ~/Desktop/Magicer-*.dmg ~/Desktop/WorkStop-*.dmg
cp "${DMG_NAME}" ~/Desktop/

echo ""
echo "✅ v${VERSION} 安装包已生成"
echo "   Desktop: ~/Desktop/${DMG_NAME}"
echo "   Dist:    dist/${DMG_NAME}"
echo ""

# ── Git ─────────────────────────────────────────────────────────────────
echo "▶ Git commit & push..."
git add -A
git commit -m "v${VERSION}: release" || echo "  (nothing new to commit)"
git push

echo "▶ Git tag v${VERSION}..."
git tag -f "v${VERSION}"
git push origin "v${VERSION}" --force

# ── GitHub Release ────────────────────────────────────────────────────────
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  echo "▶ Creating GitHub Release v${VERSION}..."
  # Delete existing release if it exists
  gh release delete "v${VERSION}" --yes 2>/dev/null || true
  gh release create "v${VERSION}" \
    "${DMG_NAME}" \
    --title "${APP_DISPLAY} v${VERSION}" \
    --notes "## ${APP_DISPLAY} v${VERSION}

安装方式：下载 \`${DMG_NAME}\`，将 \`${APP_DISPLAY}.app\` 拖入 \`/Applications\` 即可。" \
    --latest
  echo "✅ GitHub Release v${VERSION} 已创建"
  echo "   https://github.com/whoishzp/magicer/releases/tag/v${VERSION}"
else
  echo "⚠️  跳过 GitHub Release（gh CLI 未登录）"
  echo "   运行 'gh auth login' 后，执行以下命令手动创建 Release："
  echo "   gh release create v${VERSION} ${DMG_NAME} --title '${APP_DISPLAY} v${VERSION}' --latest"
fi
