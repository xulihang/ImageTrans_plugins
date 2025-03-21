#!/usr/bin/env python3
from rapidocr_onnxruntime import RapidOCR
import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
    
@route('/ocr', method='POST')
def ocr():
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    return_word_box_param = request.forms.get('return_word_box')
    return_word_box = False
    if return_word_box_param == "true":
        return_word_box = True
    name, ext = os.path.splitext(upload.filename)
    print(ext.lower())
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
    ret = {}
    result = engine(file_path, return_word_box=return_word_box)
    print(result)
    text_lines=[]
    for line in result[0]:
        text_line={}
        index=0
        line_text = line[1]
        for coord in line[0]:
            text_line["x"+str(index)]=int(coord[0])
            text_line["y"+str(index)]=int(coord[1])
            index=index+1
        text_line["text"]=line_text

        if return_word_box:
            boxes_coords = line[3]
            
            box_index = 0
            boxes = []
            for coords in boxes_coords:
                box = {}
                index = 0
                for coord in coords:
                    box["x"+str(index)]=int(coord[0])
                    box["y"+str(index)]=int(coord[1])
                    index = index + 1
                box["text"] = line[4][box_index]
                boxes.append(box)
                box_index = box_index + 1
            text_line["boxes"] = boxes
        text_lines.append(text_line)
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret 


@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

engine = RapidOCR()
run(server="paste",host='127.0.0.1', port=8078)

