#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from paddleocr import PaddleOCR, TextDetection
    
@route('/ocr', method='POST')
def ocr():
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    print(lang)
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
    rec_model="PP-OCRv5_mobile_rec"
    det_model="PP-OCRv5_mobile_det"
    ret = {}
    ocr = None
    if lang not in ["ch","japan","en"]:
        ocr = PaddleOCR(
            lang=lang,
            use_doc_orientation_classify=False, 
            use_doc_unwarping=False, 
            use_textline_orientation=False)
    else:
        ocr = PaddleOCR(
            lang=lang,
            text_detection_model_name=det_model,
            text_recognition_model_name=rec_model,
            use_doc_orientation_classify=False, 
            use_doc_unwarping=False, 
            use_textline_orientation=False)
    result = ocr.predict(file_path)[0]
    print(result)
    text_lines=[]
    index = 0
    for text in result["rec_texts"]:
        text_line={}
        coord_index = 0
        for coord in result["rec_polys"][index]:
            text_line["x"+str(coord_index)]=int(coord[0])
            text_line["y"+str(coord_index)]=int(coord[1])
            coord_index=coord_index+1
        text_line["text"]=text
        text_lines.append(text_line)
        index=index+1
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret

@route('/detect', method='POST')
def detect():
    upload = request.files.get('upload')
    path = request.forms.get('path')
    file_path = ""
    if path != None:
        if os.path.exists(path):
            print(path)
            file_path = path
    if file_path == "":
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
    model = TextDetection()
    result = model.predict(file_path)[0]
    text_lines=[]
    polys = result["dt_polys"]
    for poly in polys:
        text_line={}
        coord_index = 0
        for coord in poly:
            text_line["x"+str(coord_index)]=int(coord[0])
            text_line["y"+str(coord_index)]=int(coord[1])
            coord_index=coord_index+1
        text_line["text"]=""
        text_lines.append(text_line)
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret

@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')


run(server="paste",host='127.0.0.1', port=8080)

