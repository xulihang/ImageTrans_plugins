#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from onnxtr.io import DocumentFile
from onnxtr.models import db_mobilenet_v3_large, crnn_vgg16_bn, ocr_predictor, EngineConfig
    
@route('/ocr', method='POST')
def ocr():
    upload = request.files.get('upload')
    name, ext = os.path.splitext(upload.filename)
    if ext.lower() not in ('.png','.jpg','.jpeg'):
        return "File extension not allowed."
    timestamp=str(int(time.time()*1000))
    savedName=timestamp+ext
    save_path = "./uploaded/"
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    file_path = "{path}/{file}".format(path=save_path, file=savedName)
    if os.path.exists(file_path)==True:
        os.remove(file_path)
    upload.save(file_path)
    f = open(file_path,"rb")
    image = f.read()
    f.close()
    doc = DocumentFile.from_images([image])
    ret = {}
    result = predictor(doc)
    text_lines=[]
    blocks = []
    words = []
    for page in result.pages:
        h, w = page.dimensions
        for block in page.blocks:
            block_text = ""
            for line in block.lines:
                top_left_x = int(line.geometry[0][0] * w)
                top_left_y = int(line.geometry[0][1] * h)
                bottom_right_x = int(line.geometry[1][0] * w)
                bottom_right_y = int(line.geometry[1][1] * h)
                text_line = {}
                text_line["x0"] = top_left_x
                text_line["y0"] = top_left_y
                text_line["x1"] = bottom_right_x
                text_line["y1"] = top_left_y
                text_line["x2"] = bottom_right_x
                text_line["y2"] = bottom_right_y
                text_line["x3"] = top_left_x
                text_line["y3"] = bottom_right_y
                text_line["text"]= " ".join(word.value for word in line.words)
                text_lines.append(text_line)
                block_text = block_text + "\n" + text_line["text"]
                for word in line.words:
                    word_dict = {}
                    if word.confidence < 0.3:
                        continue
                    word_top_left_x = int(word.geometry[0][0] * w)
                    word_top_left_y = int(word.geometry[0][1] * h)
                    word_bottom_right_x = int(word.geometry[1][0] * w)
                    word_bottom_right_y = int(word.geometry[1][1] * h)
                    word_dict["x0"] = word_top_left_x
                    word_dict["y0"] = word_top_left_y
                    word_dict["x1"] = word_bottom_right_x
                    word_dict["y1"] = word_top_left_y
                    word_dict["x2"] = word_bottom_right_x
                    word_dict["y2"] = word_bottom_right_y
                    word_dict["x3"] = word_top_left_x
                    word_dict["y3"] = word_bottom_right_y
                    word_dict["text"] = word.value
                    words.append(word_dict)
        block_dict = {}
        block_top_left_x = int(block.geometry[0][0] * w)
        block_top_left_y = int(block.geometry[0][1] * h)
        block_bottom_right_x = int(block.geometry[1][0] * w)
        block_bottom_right_y = int(block.geometry[1][1] * h)
        block_dict["x0"] = block_top_left_x
        block_dict["y0"] = block_top_left_y
        block_dict["x1"] = block_bottom_right_x
        block_dict["y1"] = block_top_left_y
        block_dict["x2"] = block_bottom_right_x
        block_dict["y2"] = block_bottom_right_y
        block_dict["x3"] = block_top_left_x
        block_dict["y3"] = block_bottom_right_y
        block_dict["text"] = block_text
        blocks.append(block_dict)
    os.remove(file_path)
    ret["text_lines"]=text_lines
    ret["blocks"]=blocks
    ret["words"]=words
    return ret

@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

reco_model = crnn_vgg16_bn("crnn_vgg16_bn-743599aa.onnx")
det_model = db_mobilenet_v3_large("db_mobilenet_v3_large-4987e7bd.onnx")
predictor = ocr_predictor(det_arch=det_model, reco_arch=reco_model)
run(server="paste",host='127.0.0.1', port=8189)     

