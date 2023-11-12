You have to install a Pytorch version with GPU support according to [this](https://pytorch.org/get-started/locally/#start-locally).

If you are using the packaged version for Windows, you can try the following to install Pytorch.

## Option 1: Install with the Prepacked Packages

1. Download [torch_cu118_2.7z.001](https://github.com/xulihang/manga-image-translator/releases/download/packages/torch_cu118_2.7z.001) and [torch_cu118_2.7z.002](https://github.com/xulihang/manga-image-translator/releases/download/packages/torch_cu118_2.7z.002).
2. Use 7-zip to open `torch_cu118_2.7z.001`. Unzip the inner zip and unzip it to `Python3810\Lib\site-packages`. Remember to delete the folders in the `site-packages` folder starting with `torch` beforehand.

## Option 2: Install with Pip

1. Edit `Python3810\Scripts\pip.exe` and replace `D:\python3810\python.exe` to `python.exe`.
2. Go to the `Python3810` folder, and run the following command (you may have to update the command following the guide above):

   ```
    .\Scripts\pip.exe uninstall torch torchvision torchaudio
    .\Scripts\pip.exe install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```
