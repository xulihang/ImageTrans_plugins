## Lama inpainting plugin for ImageTrans

You can download the plugin files here: [lamainpaint_plugins.zip](https://github.com/xulihang/ImageTrans-docs/files/13327436/lamainpaint_plugins.zip)

You need to run [lama-cleaner](https://github.com/Sanster/lama-cleaner) as the backend of the plugin.

### How to use

1. Install Python
2. Put the plugin files in ImageTrans's `plugins` folder
3. Install lama-cleaner: `pip install lama-cleaner==0.12.0`
4. Start the server at port 8087: `lama-cleaner --device=cpu --port=8087`
5. In ImageTrans, set the default inpainter to lama or use it in TextRemover.


For convenience, you can also use the Windows package of lama-cleaner. Download and unzip it and then start `run.bat` to keep the server running. [Download link](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/LamaInpaint.zip).


Related issue: https://github.com/xulihang/ImageTrans-docs/issues/216

PS: lama will resize images too large so it is recommended to process by text areas. You can enable this in the project settings.

### Model

If the program fails to download the model, you can download the model file manually.

Download link: <https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/big-lama.zip>.

For Windows, you need to unzip it to the following path: `C:\Users\<your username>\.cache\torch\hub\checkpoints\big-lama.pt`.


### GPU

If you need to use CUDA GPU, you have to install the cuda version of pytorch:

```
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

Then launch it with this command: `lama-cleaner --device=cuda --port=8087`

If you are using the Windows package, you have to use notepad to edit `Scripts\pip.exe` to replace `e:\python3810\python.exe` with `.\python.exe` and run the following command:

```
.\Scripts\pip.exe uninstall torch torchvision torchaudio
.\Scripts\pip.exe install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```






