#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from doctr.io import DocumentFile
from doctr.models import ocr_predictor
    
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
    for page in result.pages:
        h, w = page.dimensions
        for block in page.blocks:
            for line in block.lines:
                top_left_x = line.geometry[0][0] * w
                top_left_y = line.geometry[0][1] * h
                bottom_right_x = line.geometry[1][0] * w
                bottom_right_y = line.geometry[1][1] * h
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
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret

@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

predictor = ocr_predictor(
                det_arch='db_resnet34', 
                reco_arch='parseq', 
                pretrained=True,
            )
run(server="paste",host='127.0.0.1', port=8189)     

