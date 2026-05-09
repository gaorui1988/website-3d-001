#!/bin/bash
# ==========================================
# 标准化 GitHub Pages 部署脚本
# 使用方式: GITHUB_TOKEN=ghp_xxx bash deploy.sh
# ==========================================
set -e

# ---- 配置 ----
REPO_NAME="website-3d-001"
BRANCH="main"
WORK_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- 检查 token ----
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ 请设置 GITHUB_TOKEN 环境变量"
  echo "   用法: GITHUB_TOKEN=ghp_xxx bash deploy.sh"
  exit 1
fi

# ---- 获取 GitHub 用户名 ----
echo "🔍 验证 GitHub 身份..."
USERNAME=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'login' in data:
    print(data['login'])
else:
    print('error: ' + data.get('message', 'unknown'))
" 2>/dev/null)

if [[ "$USERNAME" =~ ^error: ]]; then
  echo "❌ Token 验证失败: $USERNAME"
  exit 1
fi
echo "✅ 身份验证通过: $USERNAME"

# ---- 创建/检查 GitHub 仓库 ----
echo "📝 检查仓库 $USERNAME/$REPO_NAME ..."
REPO_EXISTS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME" 2>/dev/null)

if [ "$REPO_EXISTS" = "404" ]; then
  echo "📝 创建新仓库: $REPO_NAME ..."
  curl -s -X POST https://api.github.com/user/repos \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"name\":\"$REPO_NAME\",\"description\":\"NOVA X1 Pro - 3D Product Showcase\",\"private\":false}" > /dev/null
  echo "✅ 仓库创建成功"
else
  echo "ℹ️  仓库已存在"
fi

# ---- 清理旧的 git 状态 ----
cd "$WORK_DIR"
rm -f .git/index.lock
rm -rf .git/refs/heads/main .git/HEAD 2>/dev/null || true

# ---- 初始化 git ----
echo "📦 初始化本地仓库..."
git init --initial-branch="$BRANCH" 2>/dev/null || {
  git init
  git branch -m "$BRANCH"
}
git config user.name "Deploy Bot"
git config user.email "deploy@example.com"

# ---- 清理不需要的文件 ----
echo "🧹 清理不必要的文件..."
rm -f push_to_github.sh vite.config.js tailwind.config.js postcss.config.js package.json package-lock.json
rm -rf src/ node_modules/ dist/
ls -la

# ---- 只保留核心文件 ----
if [ -f .gitignore ]; then
  echo ".gitignore 已存在"
else
  echo "node_modules/" > .gitignore
  echo "dist/" >> .gitignore
  echo ".DS_Store" >> .gitignore
fi

# ---- 提交 ----
echo "💾 提交代码..."
git add -A
git commit --allow-empty -m "feat: NOVA X1 Pro 3D product showcase

- Interactive 3D product model with Three.js
- Real-time animated screen display
- 5 color variants with live switching
- OrbitControls for drag/zoom interaction
- Floating particle system
- Scroll-triggered animations
- Fully responsive design
- Single HTML file, zero build dependencies" 2>&1 | tail -1

# ---- 推送到 GitHub ----
echo "🚀 推送到 GitHub..."
REMOTE_URL="https://oauth2:${GITHUB_TOKEN}@github.com/${USERNAME}/${REPO_NAME}.git"

git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"
git push -u origin "$BRANCH" --force

# ---- 完成 ----
echo ""
echo "🎉 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   部署完成!"
echo "   仓库: https://github.com/${USERNAME}/${REPO_NAME}"
echo "   pages: https://${USERNAME}.github.io/${REPO_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
