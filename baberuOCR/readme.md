# BaberuOCR

This OCR is good for recognizing manga text, including sound effects words.

It is not suitable for long text strips.

## How to Use

Download the model files from https://huggingface.co/genshiai-daichi/baberu-ocr/tree/v1.2 to the `baberuocr` folder of the program.

```
decoder_prefill_int8.onnx

decoder_step_int8.onnx
vision_int4.onnx
tokenizer_vocab.txt (renamed from https://huggingface.co/genshiai-daichi/baberu-ocr/blob/v1.2/tokenizer/vocab.json)
```

Extract the plugin files to the plugins folder of the program: [baberuOCR.zip](https://github.com/user-attachments/files/34402895/baberuOCR.zip)
