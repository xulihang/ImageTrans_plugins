## Pororo Korean OCR

See: https://github.com/yunwoong7/korean_ocr_using_pororo

### How to Install

For Windows users:

1. Download [pororo.zip](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/pororo.zip) and unzip it into a folder.
2. Download [pororo-models.zip](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/pororo-models.zip) and unzip it to `C:\`.
3. Download the [plugin](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/pororoPlugin.zip) and unzip the files into ImageTrans's plugins folder.
4. Execute `run.bat` and keep the window open so that we can use it in ImageTrans.

For macOS and Linux users, please follow the following steps to start pororo:

1. Clone the project and change the directory to `server`.
2. Install dependencies: `pip3 install -r requirements.txt`
3. Download [pororo-models.zip](https://github.com/xulihang/ImageTrans_plugins/releases/download/plugins/pororo-models.zip) and unzip it to `~/.pororo` (or let the script download it).
4. Start the server: `python3 server_pororo_ocr.py`
