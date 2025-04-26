#!/bin/bash

# 检查是否已经存在venv虚拟环境
if [ ! -d "venv" ]; then
    echo "Creating Python 3.11 virtual environment..."
    python3.11 -m venv venv
    source venv/bin/activate
    echo "Installing requirements from requirements.txt with Tsinghua mirror..."
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
else
    echo "Virtual environment already exists. Activating..."
    source venv/bin/activate
    echo "Installing/updating requirements from requirements.txt with Tsinghua mirror..."
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
fi

echo "Running funasr_server.py..."
python funasr_server.py