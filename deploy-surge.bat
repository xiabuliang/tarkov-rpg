@echo off
chcp 65001 >nul
echo ==========================================
echo Tarkov RPG - Surge.sh 快速部署
echo ==========================================
echo.

REM 检查是否安装了 surge
where surge >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未安装 Surge.sh CLI
    echo.
    echo 请先安装:
    echo   npm install -g surge
    echo.
    pause
    exit /b 1
)

REM 检查 web_export 目录是否存在
if not exist "web_export\index.html" (
    echo [错误] 未找到 web_export/index.html
    echo.
    echo 请先在 Godot 中导出 Web 版本到 web_export 文件夹
    echo.
    pause
    exit /b 1
)

echo [1/3] 正在部署到 Surge.sh...
cd web_export
call surge --project . --domain tarkov-rpg-%RANDOM%.surge.sh
if %errorlevel% neq 0 (
    echo.
    echo [错误] 部署失败
    pause
    exit /b 1
)

cd ..
echo.
echo ==========================================
echo [成功] 部署完成！
echo ==========================================
echo.
echo 你的游戏地址已显示在上面的输出中
echo.
pause
