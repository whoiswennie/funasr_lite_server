from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import os
import time
import threading
import wave
import logging
import sys
from queue import Queue
import torch
from funasr import AutoModel
import shutil

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stdout,
    force=True
)
logger = logging.getLogger(__name__)

# 配置模型存储路径
RUNTIME_DIR = os.path.join(os.getcwd(), "runtime")
PRETRAINED_DIR = os.path.join(RUNTIME_DIR, "pretrained_models")
os.makedirs(PRETRAINED_DIR, exist_ok=True)

# 设置环境变量
os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'
os.environ['HF_HOME'] = PRETRAINED_DIR
os.environ['MODELSCOPE_CACHE'] = PRETRAINED_DIR

# 设备设置
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
os.environ["CUDA_VISIBLE_DEVICES"] = "0" if DEVICE == "cuda" else ""
logger.info(f"当前运行设备: {DEVICE}")

# 初始化ASR模型
#asr_model = AutoModel(model="paraformer-zh", model_revision="v2.0.4")
asr_model = AutoModel(model="iic/SenseVoiceSmall")
asr_model.model.to(DEVICE)
logger.info("ASR 模型加载完成")

# 存储路径
AUDIO_STORAGE = "./templates/stt"
os.makedirs(AUDIO_STORAGE, exist_ok=True)

# 任务队列和结果存储
task_queue = Queue()
results = {}

app = FastAPI()


class ResponseItem(BaseModel):
    file_id: int
    text: str
    status: str  # 'processing' or 'ready'


def process_worker():
    while True:
        if not task_queue.empty():
            file_id, file_path = task_queue.get()
            try:
                # 语音识别
                with torch.no_grad():
                    res = asr_model.generate(input=file_path, device=DEVICE)

                text = res[0]["text"] if res else ""
                logger.info(f"识别结果: {text}")

                # 存储结果
                results[file_id] = {
                    "file_id": file_id,
                    "text": text,
                    "status": "ready"
                }

                logger.info(f"处理完成文件 {file_id}")
            except Exception as e:
                logger.error(f"处理文件 {file_id} 时出错: {e}")
                results[file_id] = {
                    "file_id": file_id,
                    "text": f"处理出错: {str(e)}",
                    "status": "ready"
                }
        time.sleep(0.1)


# 启动处理线程
threading.Thread(target=process_worker, daemon=True).start()


@app.post("/upload_audio")
async def upload_audio(
        file: UploadFile = File(...),
        file_id: int = Form(...)
):
    try:
        # 保存上传的音频文件
        file_path = os.path.join(AUDIO_STORAGE, f"{file_id}.wav")
        with open(file_path, "wb") as f:
            f.write(await file.read())

        # 添加到处理队列
        task_queue.put((file_id, file_path))
        results[file_id] = {
            "file_id": file_id,
            "text": "",
            "status": "processing"
        }

        return JSONResponse(
            content={"status": "success", "file_id": file_id},
            status_code=200
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"上传文件出错: {str(e)}"
        )


@app.get("/stt/{file_id}")
async def get_response(file_id: int):
    if file_id not in results:
        raise HTTPException(
            status_code=404,
            detail="文件ID不存在"
        )

    return JSONResponse(
        content=results[file_id],
        status_code=200
    )

@app.post("/clean_templates")
async def clean_templates():
    try:
        # 检查templates文件夹是否存在
        if os.path.exists("./templates"):
            # 删除整个templates文件夹及其内容
            shutil.rmtree("./templates")
            logger.info("成功清理缓存文件夹")
            os.makedirs(f"templates/stt", exist_ok=True)
            os.makedirs(f"templates/audio_output", exist_ok=True)
            return JSONResponse(
                content={"status": "success", "message": "templates文件夹已成功清理"},
                status_code=200
            )
        else:
            return JSONResponse(
                content={"status": "success", "message": "templates文件夹不存在，无需清理"},
                status_code=200
            )
    except Exception as e:
        logger.error(f"清理templates文件夹时出错: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"清理templates文件夹时出错: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8085)