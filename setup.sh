#!/bin/bash

export LANG=en_US.UTF-8

install_pytorch() {
    echo "请选择PyTorch版本："
    echo "1. GPU版本（需要NVIDIA显卡）"
    echo "2. CPU版本"
    read -p "请选择 (1/2): " choice

    case $choice in
        1)
            echo "安装GPU版本的PyTorch..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
            ;;
        2)
            echo "安装CPU版本的PyTorch..."
            pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
            ;;
        *)
            echo "无效选择，默认安装CPU版本"
            pip install torch torchvision torchaudio -i https://pypi.tuna.tsinghua.edu.cn/simple
            ;;
    esac

    install_others
}

install_others() {
    echo "正在安装其他依赖项..."
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    
    # 启动服务
    echo "服务已启动..."
    python3 funasr_server.py 2>&1 | tee server.log &
    
    echo "按Ctrl+C退出..."
    wait
}

# 主程序
if [ ! -d "venv" ]; then
    echo "创建Python 3.11虚拟环境..."
    python3.11 -m venv venv
    source venv/bin/activate
    install_pytorch
else
    echo "激活现有虚拟环境..."
    source venv/bin/activate
    python3 -c "import torch" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "PyTorch已安装，跳过安装步骤..."
        install_others
    else
        install_pytorch
    fi
fi