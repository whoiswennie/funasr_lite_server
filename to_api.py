import pyaudio
import wave
import threading
import time
import os
import webrtcvad
from queue import Queue
import requests
import logging
import sys

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stdout,
    force=True
)
logger = logging.getLogger(__name__)

# 参数设置
AUDIO_RATE = 16000
AUDIO_CHANNELS = 1
CHUNK = 1024
VAD_MODE = 3
OUTPUT_DIR = "./templates/audio_output"
NO_SPEECH_THRESHOLD = 1
SERVER_URL = "http://localhost:8085"  # 修改为你的服务器地址

# 初始化 WebRTC VAD
vad = webrtcvad.Vad()
vad.set_mode(VAD_MODE)

os.makedirs(OUTPUT_DIR, exist_ok=True)
audio_queue = Queue()
last_active_time = time.time()
recording_active = True
segments_to_save = []
audio_file_count = 0

def audio_recorder():
    global segments_to_save, recording_active, last_active_time

    p = pyaudio.PyAudio()
    stream = p.open(
        format=pyaudio.paInt16,
        channels=AUDIO_CHANNELS,
        rate=AUDIO_RATE,
        input=True,
        frames_per_buffer=CHUNK
    )

    audio_buffer = []
    logger.info("麦克风已开启，开始监听...")

    while recording_active:
        data = stream.read(CHUNK)
        audio_buffer.append(data)

        if len(audio_buffer) * CHUNK / AUDIO_RATE >= 0.3:
            raw_audio = b''.join(audio_buffer)
            if check_vad_activity(raw_audio):
                logger.debug("检测到语音")
                last_active_time = time.time()
                segments_to_save.append((raw_audio, time.time()))
            audio_buffer = []

        if time.time() - last_active_time > NO_SPEECH_THRESHOLD:
            if segments_to_save:
                save_audio()
                last_active_time = time.time()

    stream.stop_stream()
    stream.close()
    p.terminate()
    logger.info("麦克风已关闭")

def check_vad_activity(audio_data):
    step = int(AUDIO_RATE * 0.02)
    required = 0.4 * len(audio_data) // step

    active = 0
    for i in range(0, len(audio_data), step):
        chunk = audio_data[i:i + step]
        if len(chunk) == step and vad.is_speech(chunk, AUDIO_RATE):
            active += 1
    return active > required

def save_audio():
    global segments_to_save, audio_file_count

    if not segments_to_save:
        return

    audio_file_count += 1
    filename = f"{OUTPUT_DIR}/speech_{audio_file_count}.wav"
    audio_frames = [seg[0] for seg in segments_to_save]

    with wave.open(filename, "wb") as wf:
        wf.setnchannels(AUDIO_CHANNELS)
        wf.setsampwidth(2)
        wf.setframerate(AUDIO_RATE)
        wf.writeframes(b''.join(audio_frames))

    logger.info(f"已保存语音片段: {filename}")
    segments_to_save.clear()

    # 将音频文件发送到服务器
    send_audio_to_server(filename, audio_file_count)

def send_audio_to_server(file_path, file_id):
    try:
        with open(file_path, 'rb') as f:
            files = {'file': f}
            data = {'file_id': file_id}
            response = requests.post(
                f"{SERVER_URL}/upload_audio",
                files=files,
                data=data
            )
            if response.status_code == 200:
                logger.info(f"成功发送音频文件 {file_id} 到服务器")
                # 启动接收回复的线程
                threading.Thread(
                    target=check_server_response,
                    args=(file_id,)
                ).start()
            else:
                logger.error(f"发送音频文件失败: {response.text}")
    except Exception as e:
        logger.error(f"发送音频到服务器时出错: {e}")

def check_server_response(file_id):
    while True:
        try:
            response = requests.get(
                f"{SERVER_URL}/stt/{file_id}"
            )
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'ready':
                    logger.info(f"收到服务器回复: {data.get('text')}")
                    # 这里可以添加播放回复音频的逻辑
                    break
            time.sleep(0.5)  # 每隔0.5秒检查一次
        except Exception as e:
            logger.error(f"获取服务器回复时出错: {e}")
            break

if __name__ == "__main__":
    try:
        audio_thread = threading.Thread(target=audio_recorder)
        audio_thread.start()
        logger.info("实时语音系统已启动，按 Ctrl+C 停止...")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("\n正在关闭系统...")
        recording_active = False
        audio_thread.join()
        logger.info("系统已安全关闭")