# Tarkov RPG - Web 版本构建指南

## 快速开始

### 1. 导出 Web 版本

在 Godot 编辑器中：
1. 点击 **项目 → 导出**
2. 选择 **Web** 预设
3. 设置导出路径为 `web_export/index.html`
4. 点击 **导出项目**

### 2. 本地测试

#### 方法 1: 使用 Python (推荐)
```bash
cd tarkov-rpg
python serve_web.py
```
然后在浏览器打开: http://localhost:8000

#### 方法 2: 使用 Node.js
```bash
npx serve web_export
```

#### 方法 3: 使用 VS Code Live Server
安装 Live Server 插件，右键点击 `web_export/index.html` → "Open with Live Server"

### 3. 部署到网站

将 `web_export` 文件夹中的所有文件上传到你的 Web 服务器即可。

## 注意事项

### 浏览器要求
- Chrome/Edge 90+
- Firefox 90+
- Safari 15+
- 需要支持 WebAssembly

### 首次加载
- 游戏文件较大（约 10-20MB），首次加载可能需要几秒钟
- 建议使用 WiFi 网络

### 移动端浏览器
- 支持 iOS Safari 和 Android Chrome
- 会自动显示触摸控制界面
- 建议横屏游玩

### 已知限制
- Web 版本不支持存档功能（使用内存存储）
- 音效可能有延迟
- 性能比原生版本略低

## 故障排除

### 页面空白
1. 检查浏览器控制台是否有错误
2. 确保使用了 HTTP 服务器（不能直接用 file:// 打开）
3. 检查 .wasm 文件的 MIME 类型是否正确

### 控制无响应
- 点击游戏画布获取焦点
- 检查是否有 JavaScript 错误

### 性能问题
- 关闭浏览器的"省电模式"
- 降低画质设置（如果有）
