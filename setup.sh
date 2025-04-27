#!/bin/bash

# 设置 UTF-8 编码
export LANG=en_US.UTF-8

# 检查 Python 命令是否存在
if ! command -v python3 &> /dev/null; then
    echo "未检测到 Python 3，请先安装 Python 3"
    exit 1
fi

# 检查并创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建 Python 3.11 虚拟环境..."
    python3.11 -m venv venv
    . venv/bin/activate
    
    # 安装 PyTorch
    echo "请选择 PyTorch 版本："
    echo "1. GPU 版本（需要 NVIDIA 显卡）"
    echo "2. CPU 版本"
    read -p "请选择 (1/2): " choice
    
    if [ "$choice" = "1" ]; then
        echo "安装 GPU 版本的 PyTorch..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    else
        echo "安装 CPU 版本的 PyTorch..."
        pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
    fi
else
    echo "激活现有虚拟环境..."
    . venv/bin/activate
    
    # 检查 PyTorch 是否已安装
    if python3 -c "import torch" &> /dev/null; then
        echo "PyTorch 已安装，跳过安装步骤..."
    else
        # 安装 PyTorch
        echo "请选择 PyTorch 版本："
        echo "1. GPU 版本（需要 NVIDIA 显卡）"
        echo "2. CPU 版本"
        read -p "请选择 (1/2): " choice
        
        if [ "$choice" = "1" ]; then
            echo "安装 GPU 版本的 PyTorch..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
        else
            echo "安装 CPU 版本的 PyTorch..."
            pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
        fi
    fi
fi

# 安装系统依赖
echo "安装系统依赖..."
sudo apt-get update
sudo apt-get install -y portaudio19-dev libasound2-dev python3-dev

# 安装其他依赖项
echo "正在安装其他依赖项..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 启动服务
echo "服务已启动..."
python3 funasr_server.py

# 保持终端运行
read -p "按回车键退出..." dummy