See <https://github.com/xulihang/manga-image-translator>

What does the plugin do:

1. Detect the text lines as a scene text detector.
2. Detect the text lines and recognize the text as an OCR engine.
3. Create the text mask and remove the text using inpainting. (You need to install the [ExternalInpaint](https://github.com/xulihang/ImageTrans_plugins/tree/master/ExternalInpaint) and [ExternalMaskGen](https://github.com/xulihang/ImageTrans_plugins/tree/master/ExternalMaskGen) plugins as well. Get the plugins files [here](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/ImageTrans_plugins.zip))


Installation:

1. Download the Windows package of manga-image-translator: [manga-image-translator.zip](https://github.com/xulihang/manga-image-translator/releases/download/packages/manga-image-translator.zip) and unzip it into a folder.
2. Download the model files into the folder: [detect.ckpt
](https://github.com/zyddnys/manga-image-translator/releases/download/beta-0.2.1/detect.ckpt), [ocr.ckpt](https://github.com/zyddnys/manga-image-translator/releases/download/beta-0.2.1/ocr.ckpt), [inpainting.ckpt](https://github.com/zyddnys/manga-image-translator/releases/download/beta-0.2.1/inpainting.ckpt)
3. Start the server by running `run.bat`.
4. Put the `mangaTranslatorOCR` plugin files into the `plugins` folder. Get the plugins files [here](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/ImageTrans_plugins.zip)

If you are using macOS or Linux, please configure the environment by yourself.


Usage:

1. It can work as an OCR engine.
   
   Select `db_detector` to detect text lines only and select `db+resnet` to detect text lines and recognize the text as well.

   ![engines](./engines.jpg)

2. It can work as a scene text detector.
3. It can be used to generate the text mask and the text-removed image through the external mask generation and inpainting plugins.

