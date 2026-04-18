#!/usr/bin/env python3

import os
import time
import datetime
import json
import argparse
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from bottle import route, run, template, request, static_file
import multiprocessing as mp
import cv2
import numpy as np
from PIL import Image
from paddleocr import PaddleOCR
import uuid
from threading import Lock

# ============ 全局进度管理 ============
class ProgressManager:
    """进度管理器（线程安全）"""
    def __init__(self):
        self.tasks = {}  # task_id -> progress_info
        self.lock = Lock()
    
    def create_task(self, total_images):
        """创建新任务，返回task_id"""
        task_id = str(uuid.uuid4())
        with self.lock:
            self.tasks[task_id] = {
                'task_id': task_id,
                'total': total_images,
                'processed': 0,
                'success': 0,
                'failed': 0,
                'status': 'running',
                'start_time': time.time(),
                'current_image': '',
                'results': [],
                'output_dir': None
            }
        return task_id
    
    def update_progress(self, task_id, processed, success, failed, current_image='', result=None):
        """更新任务进度"""
        with self.lock:
            if task_id in self.tasks:
                self.tasks[task_id]['processed'] = processed
                self.tasks[task_id]['success'] = success
                self.tasks[task_id]['failed'] = failed
                if current_image:
                    self.tasks[task_id]['current_image'] = current_image
                if result:
                    self.tasks[task_id]['results'].append(result)
                
                # 检查是否完成
                if processed >= self.tasks[task_id]['total']:
                    self.tasks[task_id]['status'] = 'completed'
                    self.tasks[task_id]['end_time'] = time.time()
    
    def update_error(self, task_id, error_message):
        """更新任务错误状态"""
        with self.lock:
            if task_id in self.tasks:
                self.tasks[task_id]['status'] = 'failed'
                self.tasks[task_id]['error'] = error_message
                self.tasks[task_id]['end_time'] = time.time()
    
    def get_progress(self, task_id):
        """获取任务进度"""
        with self.lock:
            task = self.tasks.get(task_id)
            if not task:
                return None
            
            elapsed = time.time() - task['start_time']
            progress_percent = (task['processed'] / task['total'] * 100) if task['total'] > 0 else 0
            
            return {
                'task_id': task_id,
                'total': task['total'],
                'processed': task['processed'],
                'success': task['success'],
                'failed': task['failed'],
                'progress_percent': round(progress_percent, 2),
                'status': task['status'],
                'current_image': task['current_image'],
                'elapsed_time': round(elapsed, 2),
                'estimated_remaining': round((elapsed / task['processed']) * (task['total'] - task['processed']), 2) if task['processed'] > 0 else 0,
                'output_dir': task.get('output_dir'),
                'error': task.get('error', '')
            }
    
    def get_all_tasks(self):
        """获取所有任务列表"""
        with self.lock:
            return {tid: {'status': task['status'], 'progress': f"{task['processed']}/{task['total']}"} 
                   for tid, task in self.tasks.items()}
    
    def cleanup_old_tasks(self, max_age_seconds=3600):
        """清理旧任务（默认1小时）"""
        with self.lock:
            current_time = time.time()
            to_delete = []
            for tid, task in self.tasks.items():
                if task['status'] in ['completed', 'failed']:
                    task_age = current_time - task.get('end_time', task['start_time'])
                    if task_age > max_age_seconds:
                        to_delete.append(tid)
            for tid in to_delete:
                del self.tasks[tid]

# 全局进度管理器
progress_manager = ProgressManager()

# ============ 批量处理相关函数 ============
# 进程级全局OCR实例（每个进程独立）
_ocr_instance = None
_ocr_config = None

def init_worker(lang, threshold, threads):
    """
    进程初始化函数，在每个工作进程启动时调用
    为每个进程创建独立的OCR实例
    """
    global _ocr_instance, _ocr_config
    _ocr_config = {
        'lang': lang,
        'threshold': threshold,
        'threads': threads
    }
    _ocr_instance = PaddleOCR(
        lang=lang,
        use_angle_cls=True,
        use_gpu=False,
        enable_mkldnn=True,
        cpu_threads=threads,
        use_mp=False,
        det_db_thresh=0.9,
        det_db_box_thresh=threshold,
        rec=False
    )
    print(f"Worker {os.getpid()} initialized with lang={lang}, threshold={threshold}")

def get_ocr_instance():
    """获取当前进程的OCR实例"""
    global _ocr_instance
    if _ocr_instance is None:
        # 如果未初始化，使用默认配置创建（兼容旧代码）
        _ocr_instance = PaddleOCR(
            lang='ch',
            use_angle_cls=True,
            use_gpu=False,
            enable_mkldnn=True,
            cpu_threads=4,
            use_mp=False,
            det_db_thresh=0.9,
            det_db_box_thresh=0.6,
            rec=False
        )
    return _ocr_instance

def imread_chinese(image_path):
    """支持中文路径的图片读取函数"""
    try:
        img = Image.open(image_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img_np = np.array(img)
        img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
        return img_bgr
    except Exception as e:
        print(f"读取图片失败 {image_path}: {str(e)}")
        return None

def imwrite_chinese(image_path, img):
    """支持中文路径的图片保存函数"""
    try:
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_pil = Image.fromarray(img_rgb)
        img_pil.save(image_path)
        return True
    except Exception as e:
        print(f"保存图片失败 {image_path}: {str(e)}")
        return False

def crop_image(image_path, crop_params):
    """裁剪图像（支持中文路径）"""
    if crop_params is None:
        return image_path, False
    
    x, y, w, h = crop_params
    img = imread_chinese(image_path)
    if img is None:
        raise ValueError(f"无法读取图像: {image_path}")
    
    h_img, w_img = img.shape[:2]
    
    if x < 0 or y < 0 or x + w > w_img or y + h > h_img:
        raise ValueError(f"裁剪区域超出图像边界: 图像大小({w_img}x{h_img}), 裁剪区域({x},{y},{w},{h})")
    
    cropped_img = img[y:y+h, x:x+w]
    
    temp_dir = Path("./temp_cropped")
    temp_dir.mkdir(exist_ok=True)
    timestamp = int(time.time() * 1000)
    random_suffix = np.random.randint(0, 10000)
    temp_filename = f"cropped_{Path(image_path).stem}_{timestamp}_{random_suffix}{Path(image_path).suffix}"
    temp_path = temp_dir / temp_filename
    
    if not imwrite_chinese(str(temp_path), cropped_img):
        raise ValueError(f"保存裁剪图像失败: {temp_path}")
    
    return str(temp_path), True

def adjust_coordinates(boxes, crop_params):
    """调整检测框坐标，将裁剪后的坐标映射回原图坐标"""
    if crop_params is None:
        return boxes
    
    x_offset, y_offset, _, _ = crop_params
    
    adjusted_boxes = []
    for box in boxes:
        adjusted_box = {}
        for idx in range(4):
            if f"x{idx}" in box and f"y{idx}" in box:
                adjusted_box[f"x{idx}"] = box[f"x{idx}"] + x_offset
                adjusted_box[f"y{idx}"] = box[f"y{idx}"] + y_offset
        adjusted_box["text"] = box.get("text", "")
        adjusted_boxes.append(adjusted_box)
    
    return adjusted_boxes

def process_single_image_batch(args):
    """
    批量处理单张图片（用于多进程）
    参数: (image_path, output_dir, lang, crop_params, threshold, threads)
    注意：lang和threshold参数主要用于传递配置，实际使用进程级OCR实例
    """
    image_path, output_dir, lang, crop_params, threshold, threads = args
    
    # 临时文件标记
    process_path = image_path
    is_temp = False
    
    try:
        # 裁剪图像（如果需要）
        process_path, is_temp = crop_image(image_path, crop_params)
        
        # 使用进程级全局OCR实例（已在init_worker中创建）
        ocr = get_ocr_instance()
        
        # 执行检测
        result = ocr.ocr(process_path, rec=False, cls=True)
        
        # 处理结果
        text_lines = []
        if result and result[0]:
            for line in result[0]:
                text_line = {}
                for idx, coord in enumerate(line):
                    text_line[f"x{idx}"] = int(coord[0])
                    text_line[f"y{idx}"] = int(coord[1])
                text_line["text"] = ""
                text_lines.append(text_line)
            
            if crop_params is not None:
                text_lines = adjust_coordinates(text_lines, crop_params)
        
        # 保存结果
        image_name = Path(image_path).stem
        output_file = Path(output_dir) / f"{image_name}.json"
        
        result_data = {
            "image": str(Path(image_path).absolute()),
            "cropped": crop_params is not None,
            "crop_params": crop_params if crop_params else None,
            "detected_boxes": text_lines,
            "box_count": len(text_lines),
            "process_time": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result_data, f, ensure_ascii=False, indent=2)
        
        # 清理临时文件
        if is_temp and process_path and os.path.exists(process_path):
            try:
                os.remove(process_path)
            except:
                pass
        
        return {
            "image": image_name,
            "image_path": image_path,
            "success": True,
            "box_count": len(text_lines),
            "output_file": str(output_file)
        }
        
    except Exception as e:
        # 清理临时文件
        if is_temp and process_path and os.path.exists(process_path):
            try:
                os.remove(process_path)
            except:
                pass
        
        return {
            "image": Path(image_path).name,
            "image_path": image_path,
            "success": False,
            "error": str(e)
        }

def find_images(input_path):
    """查找所有支持的图片文件"""
    supported_formats = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif'}
    images = []
    input_path = Path(input_path)
    
    if input_path.is_file():
        if input_path.suffix.lower() in supported_formats:
            images.append(str(input_path))
    else:
        for ext in supported_formats:
            images.extend([str(p) for p in input_path.rglob(f"*{ext}")])
            images.extend([str(p) for p in input_path.rglob(f"*{ext.upper()}")])
    
    return sorted(set(images))

def parse_crop_params(crop_str):
    """解析裁剪参数"""
    if not crop_str:
        return None
    
    if os.path.isfile(crop_str):
        with open(crop_str, 'r', encoding='utf-8') as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        params_list = []
        for line in lines:
            if ',' in line:
                parts = line.split(',')
            else:
                parts = line.split()
            if len(parts) == 4:
                params_list.append(tuple(int(p) for p in parts))
        return params_list if params_list else None
    
    if ',' in crop_str:
        parts = crop_str.split(',')
    else:
        parts = crop_str.split()
    
    if len(parts) == 4:
        return [(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]))]
    else:
        raise ValueError(f"无效的裁剪参数格式: {crop_str}")

# ============ Web服务部分 ============

# 全局变量
current_lang = "ch"
ocr = None

def get_web_ocr_instance(lang, threshold=0.6):
    """获取或创建Web服务的OCR实例（单例模式）"""
    global current_lang, ocr
    if ocr is None or current_lang != lang:
        current_lang = lang
        ocr = PaddleOCR(
            lang=current_lang,
            use_angle_cls=True,
            use_gpu=False,
            enable_mkldnn=True,
            cpu_threads=4,
            use_mp=False,
            det_db_thresh=0.9,
            det_db_box_thresh=threshold,
            rec=False
        )
    return ocr

@route('/ocr', method='POST')
def ocr_endpoint():
    """原有的OCR接口（识别文字）"""
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    print(lang)
    
    # 使用Web服务的OCR实例
    ocr = get_web_ocr_instance(lang)
        
    name, ext = os.path.splitext(upload.filename)
    print(ext.lower())
    if ext.lower() not in ('.png','.jpg','.jpeg'):
        return "File extension not allowed."
    timestamp = str(int(time.time()*1000))
    savedName = timestamp + ext
    save_path = "./uploaded/"
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    file_path = "{path}/{file}".format(path=save_path, file=savedName)
    if os.path.exists(file_path) == True:
        os.remove(file_path)
    upload.save(file_path)        
    ret = {}
    result = ocr.ocr(file_path)[0]
    print(result)
    text_lines = []
    for line in result:
        text_line = {}
        index = 0
        for coord in line[0]:
            text_line["x"+str(index)] = int(coord[0])
            text_line["y"+str(index)] = int(coord[1])
            index = index + 1
        text_line["text"] = line[1][0]
        text_lines.append(text_line)
    os.remove(file_path)
    ret["text_lines"] = text_lines
    return ret

@route('/detect', method='POST')
def detect_endpoint():
    """原有的检测接口（只检测位置）"""
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    path = request.forms.get('path')
    threshold = float(request.forms.get('threshold', 0.6))

    # 使用Web服务的OCR实例
    ocr = get_web_ocr_instance(lang, threshold)
    
    file_path = ""
    if path != None and path != "":
        if os.path.exists(path):
            print(path)
            file_path = path
    
    is_temp_file = False
    if file_path == "":
        name, ext = os.path.splitext(upload.filename)
        print(ext.lower())
        if ext.lower() not in ('.png','.jpg','.jpeg'):
            return "File extension not allowed."
        timestamp = str(int(time.time()*1000))
        savedName = timestamp + ext
        save_path = "./uploaded/"
        if not os.path.exists(save_path):
            os.makedirs(save_path)
        file_path = "{path}/{file}".format(path=save_path, file=savedName)
        if os.path.exists(file_path) == True:
            os.remove(file_path)
        upload.save(file_path)
        is_temp_file = True
        
    ret = {}
    result = ocr.ocr(file_path, rec=False, cls=True)[0]
    print(result)
    text_lines = []
    for line in result:
        text_line = {}
        index = 0
        for coord in line:
            text_line["x"+str(index)] = int(coord[0])
            text_line["y"+str(index)] = int(coord[1])
            index = index + 1
        text_line["text"] = ""
        text_lines.append(text_line)
    
    if is_temp_file and os.path.exists(file_path):
        os.remove(file_path)
    
    ret["text_lines"] = text_lines
    return ret

@route('/batch_detect', method='POST')
def batch_detect_endpoint():
    """
    批量检测接口（异步模式，立即返回task_id）
    """
    import threading
    
    try:
        # 解析请求参数
        data = request.json
        if not data:
            return {"error": "请提供JSON格式的请求参数"}, 400
        
        folder_path = data.get('folder_path')
        if not folder_path:
            return {"error": "缺少必填参数: folder_path"}, 400
        
        # 检查文件夹是否存在
        if not os.path.exists(folder_path):
            return {"error": f"文件夹不存在: {folder_path}"}, 400
        
        # 查找所有图片
        images = find_images(folder_path)
        if not images:
            return {"error": "未找到支持的图片文件"}, 400
        
        # 创建任务
        task_id = progress_manager.create_task(len(images))
        
        # 获取参数（设置默认值）
        output_dir = data.get('output_dir', './batch_results')
        lang = data.get('lang', 'ch')
        crop_params = data.get('crop_params', None)
        threshold = float(data.get('threshold', 0.6))
        workers = data.get('workers', mp.cpu_count())
        threads_per_worker = data.get('threads_per_worker', 4)
        
        # 在后台线程中执行批量处理
        def process_in_background():
            success_count = 0
            try:
                # 处理裁剪参数
                crop_params_list = None
                if crop_params:
                    try:
                        crop_params_list = parse_crop_params(crop_params)
                        if crop_params_list:
                            if len(crop_params_list) == 1:
                                crop_params_list = crop_params_list * len(images)
                            elif len(crop_params_list) != len(images):
                                crop_params_list = [crop_params_list[0]] * len(images)
                        else:
                            crop_params_list = [None] * len(images)
                    except Exception as e:
                        error_msg = f"解析裁剪参数失败: {str(e)}"
                        progress_manager.update_error(task_id, error_msg)
                        return
                else:
                    crop_params_list = [None] * len(images)
                
                # 创建输出目录
                output_path = Path(output_dir)
                output_path.mkdir(parents=True, exist_ok=True)
                
                # 更新任务信息
                with progress_manager.lock:
                    if task_id in progress_manager.tasks:
                        progress_manager.tasks[task_id]['output_dir'] = str(output_path)
                
                # 限制进程数
                actual_workers = min(workers, len(images), mp.cpu_count())
                
                # 准备任务
                # 注意：lang和threshold参数虽然传递但不会被重新创建OCR实例
                tasks = [(img, str(output_path), lang, crop_params_list[i], threshold, threads_per_worker) 
                         for i, img in enumerate(images)]
                
                # 执行批量处理，使用进程初始化函数
                processed_count = 0
                
                with ProcessPoolExecutor(
                    max_workers=actual_workers,
                    initializer=init_worker,
                    initargs=(lang, threshold, threads_per_worker)
                ) as executor:
                    futures = {executor.submit(process_single_image_batch, task): task for task in tasks}
                    
                    for future in as_completed(futures):
                        result = future.result()
                        processed_count += 1
                        
                        if result.get('success'):
                            success_count += 1
                        
                        # 更新进度
                        progress_manager.update_progress(
                            task_id, 
                            processed_count, 
                            success_count, 
                            processed_count - success_count,
                            current_image=result.get('image', ''),
                            result=result
                        )
                
                # 清理临时目录
                temp_dir = Path("./temp_cropped")
                if temp_dir.exists():
                    import shutil
                    try:
                        shutil.rmtree(temp_dir)
                    except:
                        pass
                        
            except Exception as e:
                import traceback
                traceback.print_exc()
                error_msg = f"批量处理失败: {str(e)}"
                progress_manager.update_error(task_id, error_msg)
        
        # 启动后台线程
        thread = threading.Thread(target=process_in_background)
        thread.daemon = True
        thread.start()
        
        # 立即返回task_id
        return {
            "success": True,
            "task_id": task_id,
            "message": "批量处理任务已启动",
            "total_images": len(images),
            "status_url": f"/batch_progress/{task_id}"
        }
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {"error": f"启动批量处理失败: {str(e)}"}, 500

@route('/batch_progress/<task_id>', method='GET')
def batch_progress(task_id):
    """查询批量处理进度"""
    progress = progress_manager.get_progress(task_id)
    if not progress:
        return {"error": f"任务不存在: {task_id}"}, 404
    
    return {
        "success": True,
        "progress": progress
    }

@route('/batch_tasks', method='GET')
def batch_tasks():
    """获取所有任务列表"""
    tasks = progress_manager.get_all_tasks()
    return {
        "success": True,
        "tasks": tasks,
        "total_tasks": len(tasks)
    }

@route('/batch_status', method='GET')
def batch_status():
    """获取服务状态"""
    return {
        "status": "ready",
        "supported_formats": ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif'],
        "cpu_count": mp.cpu_count(),
        "active_tasks": sum(1 for t in progress_manager.get_all_tasks().values() if t['status'] == 'running')
    }

@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

# ============ 主程序 ============

if __name__ == "__main__":
    # 初始化Web服务的OCR实例
    ocr = get_web_ocr_instance(current_lang)
    
    print("🚀 服务器启动")
    print(f"📖 默认语言: {current_lang}")
    print(f"💻 CPU核心数: {mp.cpu_count()}")
    print(f"🌐 访问地址: http://127.0.0.1:8080")
    print(f"📡 API接口:")
    print(f"   POST /batch_detect           - 启动批量检测任务")
    print(f"   GET  /batch_progress/<task_id> - 查询任务进度")
    print(f"   GET  /batch_tasks             - 获取所有任务列表")
    print(f"   POST /ocr                    - 识别图片中的文字")
    print(f"   POST /detect                 - 检测文字位置")
    print(f"   GET  /batch_status           - 获取服务状态")
    print()
    
    # 定期清理旧任务（每小时）
    import threading
    def cleanup_worker():
        while True:
            time.sleep(3600)  # 每小时清理一次
            progress_manager.cleanup_old_tasks()
    
    cleanup_thread = threading.Thread(target=cleanup_worker, daemon=True)
    cleanup_thread.start()
    
    run(server="paste", host='127.0.0.1', port=8080)