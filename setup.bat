@echo off

:: 检查是否已经存在venv虚拟环境
if not exist "venv\" (
    echo Creating Python 3.11 virtual environment...
    python -m venv venv
    call venv\Scripts\activate
    echo Installing requirements from requirements.txt with Tsinghua mirror...
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
) else (
    echo Virtual environment already exists. Activating...
    call venv\Scripts\activate
    echo Installing/updating requirements from requirements.txt with Tsinghua mirror...
    pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
)

echo Running funasr_server.py...
python funasr_server.py
cmd /k