You have to install a Pytorch version with GPU support according to [this](https://pytorch.org/get-started/locally/#start-locally).

If you are using the packaged version for Windows, you can try the following to install Pytorch.


1. Edit `Python3810\Scripts\pip.exe` and replace `D:\python3810\python.exe` to `python.exe`.
2. Go to the `Python3810` folder, run the following command (you may have to update the command following the guide above):

   ```
    .\Scripts\pip.exe uninstall torch torchvision torchaudio
    .\Scripts\pip.exe install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```
