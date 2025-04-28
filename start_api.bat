@echo off
:: 强制使用UTF-8编码并禁用回显
>nul chcp 65001
setlocal enabledelayedexpansion

:: 检查虚拟环境目录
if not exist "venv\" (
    echo [ERROR] Virtual environment not found
    echo Run setup.bat first to create it
    pause
    exit /b 1
)

:: 安全激活虚拟环境（英文路径）
echo [INFO] Activating virtual environment...
if exist "venv\Scripts\activate.bat" (
    call "venv\Scripts\activate.bat" || (
        echo [ERROR] Failed to activate virtual environment
        pause
        exit /b 1
    )
) else (
    echo [ERROR] Missing activate.bat in venv
    pause
    exit /b 1
)

:: 检查Python文件
if not exist "to_api.py" (
    echo [ERROR] to_api.py not found
    pause
    exit /b 1
)

:: 启动服务（带错误处理）
:start_service
echo [INFO] Starting to_api.py...
title API Service - to_api.py
python to_api.py

if %errorlevel% neq 0 (
    echo [WARNING] Service exited with code %errorlevel%
    timeout /t 5 /nobreak >nul
    goto start_service
)

echo [INFO] Service stopped normally
pause