## Lama inpainting plugin for ImageTrans

You can download the plugin files here:

https://github.com/xulihang/ImageTrans-docs/issues/216


You need to run [lama-cleaner](https://github.com/Sanster/lama-cleaner) as the backend of the plugin.

### How to use

1. Install Python
2. Put the plugin files in ImageTrans's `plugins` folder
3. Install lama-cleaner: `pip install lama-cleaner==0.12.0`
4. Start the server at port 8087: `lama-cleaner --device=cpu --port=8087`
5. In ImageTrans, set the default inpainter to lama or use it in TextRemover.


For convenience, you can also use the Windows package of lama-cleaner. Download and unzip it and then start `run.bat` to keep the server running. [Download link](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/LamaInpaint.zip).