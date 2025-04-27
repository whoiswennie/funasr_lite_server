@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 检查并创建虚拟环境
if not exist "venv\" (
    echo 创建 Python 3.11 虚拟环境...
    python -m venv venv
    call venv\Scripts\activate
    goto :install_pytorch
) else (
    echo 激活现有虚拟环境...
    call venv\Scripts\activate
    :: 检查 PyTorch 是否已安装
    python -c "import torch" >nul 2>&1
    if %errorlevel% == 0 (
        echo PyTorch 已安装，跳过安装步骤...
        goto :install_others
    ) else (
        goto :install_pytorch
    )
)

:: 安装 PyTorch 的选择
:install_pytorch
echo 请选择 PyTorch 版本：
echo 1. GPU 版本（需要 NVIDIA 显卡）
echo 2. CPU 版本
choice /C 12 /N /M "请选择 (1/2): "
set "CHOICE=%errorlevel%"

if %CHOICE%==1 (
    echo 安装 GPU 版本的 PyTorch...
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
) else (
    echo 安装 CPU 版本的 PyTorch...
    pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
)

:: 安装其他依赖项
:install_others
echo 正在安装其他依赖项...
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

:: 启动服务并保持终端打开
echo 服务已启动，终端保持打开...
start python funasr_server.py
echo 按任意键退出或保持终端运行...
pause >nul