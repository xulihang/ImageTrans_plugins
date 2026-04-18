#!/usr/bin/env python3
"""
批量图片检测脚本 - 只检测文字位置，不识别内容
充分利用CPU多核能力
"""

import os
import time
import json
import argparse
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from paddleocr import PaddleOCR
import multiprocessing as mp

# 全局模型实例（每个进程独立）
_ocr_instance = None

def get_ocr(lang='ch'):
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
            cpu_threads=4,        # 每个进程的线程数（根据核心数调整）
            use_mp=False,         # 多进程模式由外部控制
            # 检测参数
            det_db_thresh=0.9,
            det_db_box_thresh=0.6,
            # 识别参数（这里不需要识别，设为False节省资源）
            rec=False
        )
    return _ocr_instance

def process_single_image(args):
    """
    处理单张图片
    参数: (image_path, output_dir, lang)
    返回: (image_name, result_data, success)
    """
    image_path, output_dir, lang = args
    
    try:
        # 获取当前进程的OCR实例
        ocr = get_ocr(lang)
        
        # 执行检测（不识别文字）
        result = ocr.ocr(image_path, rec=False, cls=True)[0]
        
        # 转换结果格式
        text_lines = []
        for line in result:
            text_line = {}
            for idx, coord in enumerate(line):
                text_line[f"x{idx}"] = int(coord[0])
                text_line[f"y{idx}"] = int(coord[1])
            text_line["text"] = ""  # 检测模式不返回文字
            text_lines.append(text_line)
        
        # 保存结果到JSON文件
        image_name = Path(image_path).stem
        output_file = Path(output_dir) / f"{image_name}.json"
        
        result_data = {
            "image": image_path,
            "detected_boxes": text_lines,
            "box_count": len(text_lines),
            "process_time": time.strftime("%Y-%m-%d %H:%M:%S")
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result_data, f, ensure_ascii=False, indent=2)
        
        print(f"✓ 完成: {image_name} (检测到 {len(text_lines)} 个文本框)")
        return (image_name, result_data, True)
        
    except Exception as e:
        print(f"✗ 失败: {Path(image_path).name} - 错误: {str(e)}")
        return (Path(image_path).name, None, False)

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
            images.extend([str(p) for p in input_path.glob(f"**/*{ext}")])
            images.extend([str(p) for p in input_path.glob(f"**/*{ext.upper()}")])
    
    return sorted(set(images))  # 去重并排序

def batch_detect(input_path, output_dir, lang='ch', num_workers=None):
    """
    批量检测图片中的文字位置
    
    Args:
        input_path: 输入图片路径（文件或文件夹）
        output_dir: 输出JSON文件的目录
        lang: OCR语言，默认中文
        num_workers: 并行进程数，默认CPU核心数
    """
    # 查找所有图片
    print(f"🔍 扫描图片: {input_path}")
    images = find_images(input_path)
    
    if not images:
        print("❌ 未找到支持的图片文件 (支持格式: jpg, jpeg, png, bmp, tiff)")
        return
    
    print(f"📸 找到 {len(images)} 张图片")
    
    # 创建输出目录
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"📁 输出目录: {output_dir}")
    
    # 设置进程数
    if num_workers is None:
        num_workers = mp.cpu_count()
    num_workers = min(num_workers, len(images), mp.cpu_count())
    print(f"⚙️  使用 {num_workers} 个进程并行处理")
    print(f"🧠 每个进程使用 4 个线程")
    print(f"💾 预计内存占用: ~{num_workers * 1.5:.0f}GB\n")
    
    # 准备任务参数
    tasks = [(img, str(output_dir), lang) for img in images]
    
    # 开始处理
    start_time = time.time()
    success_count = 0
    
    # 使用进程池执行
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        # 提交所有任务
        futures = {executor.submit(process_single_image, task): task for task in tasks}
        
        # 处理完成的任务
        for future in as_completed(futures):
            _, _, success = future.result()
            if success:
                success_count += 1
    
    # 统计结果
    elapsed_time = time.time() - start_time
    print(f"\n{'='*50}")
    print(f"✅ 处理完成!")
    print(f"📊 成功: {success_count}/{len(images)} 张")
    print(f"⏱️  总耗时: {elapsed_time:.2f} 秒")
    print(f"⚡ 平均速度: {len(images)/elapsed_time:.2f} 张/秒")
    print(f"📁 结果保存在: {output_dir}")

def main():
    parser = argparse.ArgumentParser(
        description='批量检测图片中的文字位置（不识别文字内容），充分利用CPU多核'
    )
    parser.add_argument('input', help='输入图片文件或文件夹路径')
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
    
    args = parser.parse_args()
    
    # 检查输入路径是否存在
    if not os.path.exists(args.input):
        print(f"❌ 错误: 路径不存在 '{args.input}'")
        return
    
    # 动态修改线程数（通过修改get_ocr函数中的参数）
    # 注意：这里通过全局方式修改比较hacky，更优雅的方式是传递参数
    import sys
    # 临时保存线程数设置
    global _thread_count
    _thread_count = args.threads
    
    # 重新定义get_ocr函数以使用命令行参数
    def get_ocr_with_threads(lang='ch'):
        global _ocr_instance
        if _ocr_instance is None:
            _ocr_instance = PaddleOCR(
                lang=lang,
                use_angle_cls=True,
                use_gpu=False,
                enable_mkldnn=True,
                cpu_threads=args.threads,
                use_mp=False,
                det_db_thresh=0.9,
                det_db_box_thresh=args.threshold,
                rec=False
            )
        return _ocr_instance
    
    # 替换全局函数
    globals()['get_ocr'] = get_ocr_with_threads
    
    print(f"🚀 批量检测工具启动")
    print(f"📖 语言: {args.lang}")
    print(f"🎯 检测阈值: {args.threshold}")
    print(f"⚙️  每个进程线程数: {args.threads}")
    print()
    
    # 执行批量检测
    batch_detect(
        input_path=args.input,
        output_dir=args.output,
        lang=args.lang,
        num_workers=args.workers
    )

if __name__ == "__main__":
    # 设置多进程启动方式（对Linux/macOS友好）
    mp.set_start_method('spawn', force=True)
    main()