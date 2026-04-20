## PaddleOCR

The plugin is bundled with ImageTrans. You just need to start the PaddleOCR server.

1. Install Python.
2. Install PaddleOCR: `pip install paddleocr==2.6`
3. Install bottle and Paste: `pip install bottle Paste`
4. Run the following to start the server: `python server_paddleocr.py`

For convenience, you can directly use the pre-built packages for Windows and macOS:

* [Windows x64](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/PaddleOCR.zip). Unzip and execute `run.bat`.
* [macOS Apple CPU](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/PaddleOCR-mac-arm.zip)


You need to keep the server running in the background.


### PaddleOCR v3

PaddleOCR v3 has improved the recognition for vertical text.

You can use PaddleOCR v3 for a better recognition rate. But its speed is slower. For subtitle OCR, you need to use v2 above.


Windows package: <https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/PaddleOCRv3.zip>

