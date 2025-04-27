#!/bin/bash

# 设置 UTF-8 编码
export LANG=en_US.UTF-8

# 检查并创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建 Python 3.11 虚拟环境..."
    python3.11 -m venv venv
    source venv/bin/activate
    
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
    source venv/bin/activate
    
    # 检查 PyTorch 是否已安装
    if python -c "import torch" &> /dev/null; then
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

# 安装其他依赖项
echo "正在安装其他依赖项..."
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 启动服务
echo "服务已启动..."
python funasr_server.py

# 保持终端运行（可选）
read -p "按回车键退出..."