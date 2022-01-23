#!/usr/bin/env python3
from manga_ocr import MangaOcr
import os
import time
import datetime
from bottle import route, run, template, request, static_file
import json

@route('/ocr', method='POST')
def ocr():
    upload = request.files.get('upload')       
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
    text = mocr(file_path)
    os.remove(file_path)
    return text


@route('/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='www')

mocr = MangaOcr()
run(server="paste",host='127.0.0.1', port=8080)     

