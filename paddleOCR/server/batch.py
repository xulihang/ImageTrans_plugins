#!/usr/bin/env python3
"""
批量图片检测脚本 - 只检测文字位置，不识别内容
支持图像裁剪功能，充分利用CPU多核能力
支持中文路径
"""

import os
import time
import json
import argparse
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from paddleocr import PaddleOCR
import multiprocessing as mp
import cv2
import numpy as np
from PIL import Image

# 全局模型实例（每个进程独立）
_ocr_instance = None

def imread_chinese(image_path):
    """
    支持中文路径的图片读取函数
    
    Args:
        image_path: 图片路径（支持中文）
    
    Returns:
        numpy array格式的图片，失败返回None
    """
    try:
        # 方法1: 使用PIL读取，然后转换为OpenCV格式
        img = Image.open(image_path)
        # 转换为RGB模式（如果不是）
        if img.mode != 'RGB':
            img = img.convert('RGB')
        # 转换为numpy数组，然后转为BGR（OpenCV格式）
        img_np = np.array(img)
        img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
        return img_bgr
    except Exception as e:
        print(f"读取图片失败 {image_path}: {str(e)}")
        return None

def imwrite_chinese(image_path, img):
    """
    支持中文路径的图片保存函数
    
    Args:
        image_path: 保存路径（支持中文）
        img: numpy array格式的图片
    
    Returns:
        成功返回True，失败返回False
    """
    try:
        # 将BGR转换为RGB
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        # 使用PIL保存
        img_pil = Image.fromarray(img_rgb)
        img_pil.save(image_path)
        return True
    except Exception as e:
        print(f"保存图片失败 {image_path}: {str(e)}")
        return False

def crop_image(image_path, crop_params):
    """
    裁剪图像（支持中文路径）
    
    Args:
        image_path: 图片路径（支持中文）
        crop_params: 裁剪参数 (x, y, width, height) 或 None
    
    Returns:
        裁剪后的图像路径（如果是临时裁剪文件），原始路径（如果不需要裁剪）
    """
    if crop_params is None:
        return image_path, False
    
    x, y, w, h = crop_params
    
    # 使用支持中文路径的函数读取图像
    img = imread_chinese(image_path)
    if img is None:
        raise ValueError(f"无法读取图像: {image_path}")
    
    h_img, w_img = img.shape[:2]
    
    # 验证裁剪参数
    if x < 0 or y < 0 or x + w > w_img or y + h > h_img:
        raise ValueError(f"裁剪区域超出图像边界: 图像大小({w_img}x{h_img}), 裁剪区域({x},{y},{w},{h})")
    
    # 执行裁剪
    cropped_img = img[y:y+h, x:x+w]
    
    # 保存临时文件（临时文件路径使用英文，避免重复问题）
    temp_dir = Path("./temp_cropped")
    temp_dir.mkdir(exist_ok=True)
    # 使用时间戳和随机数避免文件名冲突
    timestamp = int(time.time() * 1000)
    random_suffix = np.random.randint(0, 10000)
    temp_filename = f"cropped_{Path(image_path).stem}_{timestamp}_{random_suffix}{Path(image_path).suffix}"
    temp_path = temp_dir / temp_filename
    
    # 使用支持中文路径的函数保存
    if not imwrite_chinese(str(temp_path), cropped_img):
        raise ValueError(f"保存裁剪图像失败: {temp_path}")
    
    return str(temp_path), True

def adjust_coordinates(boxes, crop_params):
    """
    调整检测框坐标，将裁剪后的坐标映射回原图坐标
    
    Args:
        boxes: 检测到的文本框列表
        crop_params: 裁剪参数 (x, y, width, height)
    
    Returns:
        调整后的文本框列表
    """
    if crop_params is None:
        return boxes
    
    x_offset, y_offset, _, _ = crop_params
    
    adjusted_boxes = []
    for box in boxes:
        adjusted_box = {}
        for idx in range(4):  # 每个框有4个点
            if f"x{idx}" in box and f"y{idx}" in box:
                adjusted_box[f"x{idx}"] = box[f"x{idx}"] + x_offset
                adjusted_box[f"y{idx}"] = box[f"y{idx}"] + y_offset
        adjusted_box["text"] = box.get("text", "")
        adjusted_boxes.append(adjusted_box)
    
    return adjusted_boxes

def process_single_image(args):
    """
    处理单张图片
    参数: (image_path, output_dir, lang, crop_params, threshold, threads)
    返回: (image_name, result_data, success)
    """
    image_path, output_dir, lang, crop_params, threshold, threads = args
    
    temp_file = None
    is_temp = False
    
    try:
        # 裁剪图像（如果需要）
        process_path, is_temp = crop_image(image_path, crop_params)
        
        # 获取当前进程的OCR实例
        ocr = get_ocr(lang, threshold, threads)
        
        # 执行检测（不识别文字）
        # PaddleOCR的ocr方法支持中文路径（内部已处理）
        result = ocr.ocr(process_path, rec=False, cls=True)
        
        # 处理结果（result可能是None或空列表）
        text_lines = []
        if result and result[0]:  # 确保有检测结果
            for line in result[0]:
                text_line = {}
                for idx, coord in enumerate(line):
                    text_line[f"x{idx}"] = int(coord[0])
                    text_line[f"y{idx}"] = int(coord[1])
                text_line["text"] = ""
                text_lines.append(text_line)
            
            # 如果是裁剪的图像，调整坐标回原图
            if crop_params is not None:
                text_lines = adjust_coordinates(text_lines, crop_params)
        
        # 保存结果到JSON文件
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
        
        print(f"✓ 完成: {image_name} (检测到 {len(text_lines)} 个文本框)" + 
              (f" [裁剪区域: {crop_params}]" if crop_params else ""))
        return (image_name, result_data, True)
        
    except Exception as e:
        print(f"✗ 失败: {Path(image_path).name} - 错误: {str(e)}")
        import traceback
        traceback.print_exc()
        return (Path(image_path).name, None, False)
    
    finally:
        # 清理临时文件
        if is_temp and process_path and os.path.exists(process_path):
            try:
                os.remove(process_path)
            except Exception as e:
                print(f"清理临时文件失败 {process_path}: {e}")

def get_ocr(lang='ch', threshold=0.6, threads=4):
    """获取当前进程的OCR实例（每个进程只初始化一次）"""
    global _ocr_instance
    if _ocr_instance is None:
        # 开启多线程和MKL-DNN加速
        _ocr_instance = PaddleOCR(
            lang=lang,
            use_angle_cls=True,  # 开启文本方向分类
            use_gpu=False,
            # CPU优化参数
            enable_mkldnn=True,   # 开启Intel CPU加速
            cpu_threads=threads,  # 每个进程的线程数
            use_mp=False,         # 多进程模式由外部控制
            # 检测参数
            det_db_thresh=0.9,
            det_db_box_thresh=threshold,
            rec=False
        )
    return _ocr_instance

def find_images(input_path):
    """查找所有支持的图片文件（支持中文路径）"""
    supported_formats = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif'}
    images = []
    
    input_path = Path(input_path)
    
    if input_path.is_file():
        if input_path.suffix.lower() in supported_formats:
            images.append(str(input_path))
    else:
        # 使用glob查找，支持中文路径
        for ext in supported_formats:
            # 使用rglob进行递归查找
            images.extend([str(p) for p in input_path.rglob(f"*{ext}")])
            images.extend([str(p) for p in input_path.rglob(f"*{ext.upper()}")])
    
    return sorted(set(images))  # 去重并排序

def parse_crop_params(crop_str):
    """
    解析裁剪参数
    支持格式:
    - "x,y,width,height" (例如: "100,50,800,600")
    - "x y width height" (例如: "100 50 800 600")
    - 文件路径: 从txt文件读取（每行一个裁剪参数）
    """
    if not crop_str:
        return None
    
    # 如果是文件路径，读取文件中的参数
    if os.path.isfile(crop_str):
        with open(crop_str, 'r', encoding='utf-8') as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        params_list = []
        for line in lines:
            # 支持逗号或空格分隔
            if ',' in line:
                parts = line.split(',')
            else:
                parts = line.split()
            if len(parts) == 4:
                params_list.append(tuple(int(p) for p in parts))
            else:
                print(f"警告: 跳过无效的裁剪参数行: {line}")
        return params_list if params_list else None
    
    # 直接解析参数
    if ',' in crop_str:
        parts = crop_str.split(',')
    else:
        parts = crop_str.split()
    
    if len(parts) == 4:
        return [(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3]))]
    else:
        raise ValueError(f"无效的裁剪参数格式: {crop_str}，应为 'x,y,width,height'")

def batch_detect(input_path, output_dir, lang='ch', num_workers=None, 
                 crop_params=None, threshold=0.6, threads_per_worker=4):
    """
    批量检测图片中的文字位置
    
    Args:
        input_path: 输入图片路径（文件或文件夹）
        output_dir: 输出JSON文件的目录
        lang: OCR语言，默认中文
        num_workers: 并行进程数，默认CPU核心数
        crop_params: 裁剪参数列表，每个元素为(x, y, w, h)或None
        threshold: 检测框阈值
        threads_per_worker: 每个进程的线程数
    """
    # 查找所有图片
    print(f"🔍 扫描图片: {input_path}")
    images = find_images(input_path)
    
    if not images:
        print("❌ 未找到支持的图片文件 (支持格式: jpg, jpeg, png, bmp, tiff)")
        return
    
    print(f"📸 找到 {len(images)} 张图片")
    
    # 显示前5个图片路径（用于调试中文路径）
    if len(images) > 0:
        print(f"📋 示例路径: {Path(images[0]).name}")
        if len(images) > 1:
            print(f"            {Path(images[1]).name}")
    
    # 处理裁剪参数
    crop_params_list = None
    if crop_params:
        crop_params_list = parse_crop_params(crop_params)
        if crop_params_list:
            if len(crop_params_list) == 1:
                # 单个裁剪参数，应用到所有图片
                crop_params_list = crop_params_list * len(images)
                print(f"📐 应用相同的裁剪区域到所有图片")
            elif len(crop_params_list) == len(images):
                # 每个图片对应不同的裁剪参数
                print(f"📐 使用 {len(crop_params_list)} 个不同的裁剪区域")
            else:
                print(f"⚠️  裁剪参数数量({len(crop_params_list)})与图片数量({len(images)})不匹配")
                print(f"   将应用第一个裁剪参数到所有图片")
                crop_params_list = [crop_params_list[0]] * len(images)
        else:
            print(f"⚠️  未找到有效的裁剪参数，将不进行裁剪")
            crop_params_list = [None] * len(images)
    else:
        crop_params_list = [None] * len(images)
    
    # 创建输出目录
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"📁 输出目录: {output_dir}")
    
    # 设置进程数
    if num_workers is None:
        num_workers = mp.cpu_count()
    num_workers = min(num_workers, len(images), mp.cpu_count())
    print(f"⚙️  使用 {num_workers} 个进程并行处理")
    print(f"🧠 每个进程使用 {threads_per_worker} 个线程")
    print(f"🎯 检测阈值: {threshold}")
    print(f"💾 预计内存占用: ~{num_workers * 1.5:.0f}GB")
    
    if crop_params and crop_params_list and any(p is not None for p in crop_params_list[:3]):
        print(f"✂️  启用图像裁剪")
        for i, params in enumerate(crop_params_list[:3]):  # 只显示前3个
            if params:
                print(f"   - 图片{i+1}: 裁剪区域 x={params[0]}, y={params[1]}, w={params[2]}, h={params[3]}")
        if len(crop_params_list) > 3:
            print(f"   ... 共 {len(crop_params_list)} 个裁剪区域")
    print()
    
    # 准备任务参数
    tasks = [(img, str(output_dir), lang, crop_params_list[i], threshold, threads_per_worker) 
             for i, img in enumerate(images)]
    
    # 开始处理
    start_time = time.time()
    success_count = 0
    
    # 使用进程池执行
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        # 提交所有任务
        futures = {executor.submit(process_single_image, task): task for task in tasks}
        
        # 处理完成的任务
        for future in as_completed(futures):
            try:
                _, _, success = future.result(timeout=300)  # 5分钟超时
                if success:
                    success_count += 1
            except Exception as e:
                print(f"任务执行异常: {e}")
    
    # 统计结果
    elapsed_time = time.time() - start_time
    print(f"\n{'='*50}")
    print(f"✅ 处理完成!")
    print(f"📊 成功: {success_count}/{len(images)} 张")
    print(f"⏱️  总耗时: {elapsed_time:.2f} 秒")
    if len(images) > 0:
        print(f"⚡ 平均速度: {len(images)/elapsed_time:.2f} 张/秒")
    print(f"📁 结果保存在: {output_dir}")
    
    # 清理临时目录
    temp_dir = Path("./temp_cropped")
    if temp_dir.exists():
        import shutil
        try:
            shutil.rmtree(temp_dir)
            print(f"🧹 已清理临时文件")
        except Exception as e:
            print(f"清理临时目录失败: {e}")

def main():
    parser = argparse.ArgumentParser(
        description='批量检测图片中的文字位置（不识别文字内容），支持图像裁剪，充分利用CPU多核',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 基本用法（支持中文路径）
  python batch_detect.py ./中文文件夹
  
  # 使用裁剪区域（单个区域应用到所有图片）
  python batch_detect.py ./images --crop "100,50,800,600"
  
  # 使用不同的裁剪区域（从文件读取）
  python batch_detect.py ./images --crop crops.txt
  
  # 指定输出目录和语言
  python batch_detect.py ./images -o ./results -l en
  
  # 性能调优：8个进程，每个进程6个线程
  python batch_detect.py ./images -w 8 --threads 6
  
  # 调整检测阈值
  python batch_detect.py ./images --threshold 0.5

裁剪参数文件格式（crops.txt）:
  每行一个裁剪区域，支持逗号或空格分隔，支持#注释
  100,50,800,600
  200,100,400,300
  0,0,1920,1080
        """
    )
    
    parser.add_argument('input', help='输入图片文件或文件夹路径（支持中文）')
    parser.add_argument('-o', '--output', default='./detect_results', 
                       help='输出JSON文件目录 (默认: ./detect_results)')
    parser.add_argument('-l', '--lang', default='ch',
                       help='OCR语言 (默认: ch, 可选: en, fr, de, jp, ko 等)')
    parser.add_argument('-w', '--workers', type=int, default=None,
                       help=f'并行进程数 (默认: CPU核心数 = {mp.cpu_count()})')
    parser.add_argument('--threads', type=int, default=4,
                       help='每个进程的线程数 (默认: 4)')
    parser.add_argument('--threshold', type=float, default=0.6,
                       help='检测框阈值 (默认: 0.6)')
    parser.add_argument('--crop', type=str, default=None,
                       help='裁剪区域，格式: "x,y,width,height" 或包含多个区域的txt文件路径')
    
    args = parser.parse_args()
    
    # 检查输入路径是否存在
    if not os.path.exists(args.input):
        print(f"❌ 错误: 路径不存在 '{args.input}'")
        return
    
    # 检查裁剪参数文件
    if args.crop and os.path.isfile(args.crop):
        print(f"📄 从文件读取裁剪参数: {args.crop}")
    
    print(f"🚀 批量检测工具启动")
    print(f"📖 语言: {args.lang}")
    print(f"🎯 检测阈值: {args.threshold}")
    print(f"⚙️  每个进程线程数: {args.threads}")
    if args.crop:
        print(f"✂️  裁剪模式: 启用")
    print()
    
    # 执行批量检测
    batch_detect(
        input_path=args.input,
        output_dir=args.output,
        lang=args.lang,
        num_workers=args.workers,
        crop_params=args.crop,
        threshold=args.threshold,
        threads_per_worker=args.threads
    )

if __name__ == "__main__":
    # 设置多进程启动方式
    try:
        mp.set_start_method('spawn', force=True)
    except RuntimeError:
        pass
    main()