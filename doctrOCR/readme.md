# doctrOCR


1. Install Python and DocTROCR.
2. Install bottle and Paste: `pip install bottle Paste`
3. Run the following to start the server: `python server.py`
4. [Download the plugin files](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/ImageTrans_plugins.zip) and put `doctrOCRPlugin.jar` and `doctrOCRPlugin.xml` into the plugins folder of ImageTrans.

For convenience, you can directly use the Windows package: [link](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/onnxtr.zip)

Unzip the file and start `run.bat` to run the server. You need to keep the server running in the background.

The package is using ONNXRuntime. You can also use the Pytorch version: [link](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/DocTROCR.zip).

If you failed to download the model for the Pytorch version, you can [download the models](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/doctr-models.zip) and unzip them to `C:\Users\<your username>\.cache\doctr\models\`.


