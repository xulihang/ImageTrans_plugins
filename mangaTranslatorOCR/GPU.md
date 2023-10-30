Follow the link to enable GPU.

<https://github.com/xulihang/manga-image-translator#how-to-enable-gpu>


If you are using the packaged version for Windows, you can try the following to install Pytorch.


1. Edit `Python\Scripts\pip.exe` and replace `e:\python3810\python.exe` to `python.exe`.
2. Go to the `Python` folder, run the following command (you may have to update the command following the guide above):

   ```
    .\Scripts\pip.exe uninstall torch torchvision torchaudio
    .\Scripts\pip.exe install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

Then create a file named `use_cuda` under the root of the project to enable GPU.