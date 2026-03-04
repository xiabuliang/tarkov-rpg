# Tarkov RPG - 快速部署方案

## 方案1: Tiiny.host（最简单，推荐）

**步骤：**
1. 在 Godot 中导出 Web 版本到 `web_export` 文件夹
2. 将 `web_export` 文件夹压缩为 zip
3. 访问 https://tiiny.host
4. 上传 zip 文件
5. 获得免费网址（如 `xxx.tiiny.site`）

**优点：**
- 无需注册账号
- 30秒完成部署
- 支持自定义域名
- 免费版够用

---

## 方案2: Surge.sh（命令行）

**准备：**
```bash
npm install -g surge
```

**部署：**
1. 在 Godot 中导出 Web 版本
2. 双击运行 `deploy-surge.bat`
3. 按提示操作
4. 获得网址（如 `xxx.surge.sh`）

---

## 方案3: Netlify Drop（拖拽上传）

**步骤：**
1. 访问 https://app.netlify.com/drop
2. 将 `web_export` 文件夹拖放到页面
3. 立即获得网址

**优点：**
- 无需注册
- 自动 HTTPS
- 全球 CDN

---

## 方案4: Cloudflare Pages

**步骤：**
1. 访问 https://pages.cloudflare.com
2. 注册/登录 Cloudflare 账号
3. 创建新项目，上传 `web_export` 文件夹
4. 获得网址

**优点：**
- 无限带宽
- 全球加速
- 完全免费

---

## 推荐顺序

| 方案 | 难度 | 稳定性 | 推荐度 |
|------|------|--------|--------|
| Tiiny.host | ⭐ 极简 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Netlify Drop | ⭐ 简单 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Surge.sh | ⭐⭐ 中等 | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Cloudflare | ⭐⭐⭐ 较复杂 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 手机测试注意事项

1. **横屏模式**：游戏设计为横屏，请锁定横屏
2. **触摸控制**：移动端会自动显示虚拟摇杆和按钮
3. **首次加载**：可能需要几秒钟加载资源
4. **浏览器推荐**：Chrome、Safari、Edge
