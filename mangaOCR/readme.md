See:

1. <https://github.com/kha-white/manga_ocr>
2. <https://github.com/xulihang/ImageTrans-docs/issues/140>

Install:

1. Install python3.
2. Install required packages: `pip install -r requirements.txt`.
3. Run the server: `python server_manga_ocr.py`.
4. Unzip the [plugin files](https://github.com/xulihang/ImageTrans-docs/files/10887754/manga-ocr-plugin.zip) in ImageTrans's `plugins` folder and restart ImageTrans. (optional for v1.9.0+)

**For convenience**, you can also use the Windows package:

1. Download and unzip [manga-ocr](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/manga-ocr.zip).
2. (Optional) Download the [model](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/manga-ocr-model.zip) and unzip it to manga-ocr's folder in the previous step.
3. Run `run.bat` and wait for the server to get ready.


## Usage Note

The mangaOCR works great for speech bubbles like the following one:

![normal](./normal.jpg)

But it may not work well for the following long text line image by default:

![long text](./long_text.jpg)

For such a case, you can select the long text mode of the plugin which will crop the long text line images into segments for the OCR engine to extract the text. It should better be used in combination with a scene text detector which detects the text lines accurately like this one: <https://github.com/xulihang/ImageTrans_plugins/tree/master/mangaTranslatorOCR>

![list](./list.jpg)

## Text Detection Combination

mangaOCR does not detect text. It can be used together with other text detection methods like the following ones:

1. Speech bubble detection model: <https://github.com/xulihang/ImageTrans-docs/issues/135>
2. manga image translator (detect text lines): <https://github.com/xulihang/ImageTrans_plugins/tree/master/mangaTranslatorOCR>

