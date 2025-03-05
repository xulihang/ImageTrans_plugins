#!/usr/bin/env python3

import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json
from paddleocr import PaddleOCR
    
@route('/ocr', method='POST')
def ocr():
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    print(lang)
    global current_lang
    global ocr
    if current_lang!=lang:
        current_lang=lang
        ocr = PaddleOCR(lang=current_lang)
        
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
    result = ocr.ocr(file_path)[0]
    print(result)
    text_lines=[]
    for line in result:
        text_line={}
        index=0
        for coord in line[0]:
            text_line["x"+str(index)]=int(coord[0])
            text_line["y"+str(index)]=int(coord[1])
            index=index+1
        text_line["text"]=line[1][0]
        text_lines.append(text_line)
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret

@route('/detect', method='POST')
def detect():
    upload = request.files.get('upload')
    lang = request.forms.get('lang')
    print(lang)
    global current_lang
    global ocr
    if current_lang!=lang:
        current_lang=lang
        ocr = PaddleOCR(lang=current_lang)
        
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
    result = ocr.ocr(file_path,rec=False,cls=True)[0]
    print(result)
    text_lines=[]
    for line in result:
        text_line={}
        index=0
        for coord in line:
            text_line["x"+str(index)]=int(coord[0])
            text_line["y"+str(index)]=int(coord[1])
            index=index+1
        text_line["text"]=""
        text_lines.append(text_line)
    os.remove(file_path)
    ret["text_lines"]=text_lines
    return ret    


@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

current_lang="ch"
ocr = PaddleOCR(lang=current_lang,det_db_thresh=0.9,det_db_box_thresh=0.6)
run(server="paste",host='127.0.0.1', port=8080)     

