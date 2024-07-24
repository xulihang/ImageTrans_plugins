Follow the link to enable GPU.

<https://github.com/xulihang/manga-image-translator#how-to-enable-gpu>


If you are using the packaged version for Windows, you can try the following to install Pytorch.

## Option 1: Install with the Prepacked Packages

1. Download [torch_cu118_2.7z.001](https://github.com/xulihang/manga-image-translator/releases/download/packages/torch_cu118_2.7z.001) and [torch_cu118_2.7z.002](https://github.com/xulihang/manga-image-translator/releases/download/packages/torch_cu118_2.7z.002).
2. Use 7-zip to open `torch_cu118_2.7z.001`. Unzip the inner zip and unzip it to `Python3810\Lib\site-packages`. Remember to delete the folders in the `site-packages` folder starting with `torch` beforehand.

Then create a file named `use_cuda` under the root of the project to enable GPU.

## Option 2: Install with Pip

Go to the `Python` folder, and run the following command (you may have to update the command following the guide above):

   ```
    .\Scripts\pip.exe uninstall torch torchvision torchaudio
    .\Scripts\pip.exe install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

Then create a file named `use_cuda` under the root of the project to enable GPU.
