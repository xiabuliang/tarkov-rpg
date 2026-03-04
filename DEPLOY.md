# 部署到 GitHub Pages

## 步骤

### 1. 创建 GitHub 仓库
- 登录 GitHub
- 新建仓库，命名为 `tarkov-rpg`（或其他名字）
- 选择 Public（免费）

### 2. 上传代码
```bash
cd tarkov-rpg
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/tarkov-rpg.git
git push -u origin main
```

### 3. 导出 Web 版本
在 Godot 中：
- 项目 → 导出 → Web
- 导出路径: `web_export/index.html`
- 点击"导出项目"

### 4. 上传 web_export
```bash
git add web_export/
git commit -m "Add web build"
git push
```

### 5. 启用 GitHub Pages
- 打开 GitHub 仓库页面
- Settings → Pages
- Source: GitHub Actions
- 等待几分钟

### 6. 访问游戏
网址格式: `https://YOUR_USERNAME.github.io/tarkov-rpg/`

## 自动部署
每次推送代码后，GitHub Actions 会自动重新部署。
