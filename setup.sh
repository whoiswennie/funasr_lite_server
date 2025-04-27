#!/bin/bash

# 设置 UTF-8 编码
export LANG=en_US.UTF-8

# 安装系统级依赖（解决编译问题）
echo "安装系统依赖..."
sudo apt-get update
sudo apt-get install -y build-essential libportaudio2 portaudio19-dev python3-dev swig libffi-dev libssl-dev

# 检查并创建虚拟环境
if [ ! -d "venv" ]; then
    echo "创建 Python 3.11 虚拟环境..."
    python3.11 -m venv venv
    source venv/bin/activate
    
    # 安装 setuptools 和 wheel 的兼容版本
    pip install --upgrade setuptools==65.5.0 wheel
    
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
        # 安装 PyTorch（同上逻辑）
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

# 安装其他依赖项（使用清华源加速）
echo "正在安装其他依赖项..."
pip install -r requirements_linux.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn

# 处理 ali-cloud-sdk-core 的兼容性问题
echo "安装 aliyun-python-sdk-core（兼容性修复）..."
pip install aliyun-python-sdk-core==2.13.33 --no-cache-dir

# 处理 crcmod 的兼容性问题
echo "安装 crcmod（兼容性修复）..."
pip install crcmod==2.4 --no-cache-dir

# 启动服务
echo "服务已启动..."
nohup python funasr_server.py > app.log 2>&1 &

# 保持终端运行（可选）
read -p "按回车键退出..."