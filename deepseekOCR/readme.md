# Deepseek-OCR


A VLM model plugin for OCR and layout detection.

By default, it uses Siliconflow's API to use Deepseek-OCR.

You can host your own model using tools like vLLM, Ollama and deepseek-ocr.rs.


## Using deepseek-ocr.rs

deepseek-ocr.rs is a lightweight inference engine.

You can use it to run Deepseek-OCR, Dots.OCR and PaddleOCR-VL on your machine.


Here are the steps to use it:

1. Download its binary files: <https://github.com/TimmyOVO/deepseek-ocr.rs/releases>
2. Create a config.toml file with the following content:

    ```

    [models]
    active = "paddle_ocr_vl"

    # Per-model entries. Leave `config`/`tokenizer`/`weights` blank to use the automatic cache/download.
    [models.entries.deepseek-ocr]
    kind = "deepseek"
    config = "models/DeepSeek-OCR/config.json"
    tokenizer = "models/DeepSeek-OCR/tokenizer.json"
    weights = "models/DeepSeek-OCR/model.safetensors"

    [models.entries.paddleocr-vl]
    kind = "paddle_ocr_vl"
    # Absolute paths on Windows. Replace these with your actual locations.
    config = "models/PaddleOCR-VL/config.json"
    tokenizer = "models/PaddleOCR-VL/tokenizer.json"
    weights = "models/PaddleOCR-VL/model.safetensors"



    # Optional runtime defaults (can be overridden by CLI flags or request payloads)

    [runtime]

    device = "cpu" # e.g. "cpu", "cuda", "metal"

    dtype = "f16" # e.g. "f16", "f32", "bf16"

    max_new_tokens = 512



    [server]

    host = "0.0.0.0"

    port = 8000
    ```
    
3. Start the server:

    ```bash
    ./deepseek-ocr-server --config=config.toml
    ```
    
4. Use the Deepseek-OCR plugin in ImageTrans.

### Using PaddleOCR-VL-Manga

If you need to use PaddleOCR-VL-Manga for manga OCR, you need to download its model files, put them in a folder and replace the default PaddleOCR-VL's file paths like the following:

```diff
- config = "models/PaddleOCR-VL/config.json"
- tokenizer = "models/PaddleOCR-VL/tokenizer.json"
- weights = "models/PaddleOCR-VL/model.safetensors"
+ config = "models/PaddleOCR-VL-Manga/config.json"
+ tokenizer = "models/PaddleOCR-VL-Manga/tokenizer.json"
+ weights = "models/PaddleOCR-VL-Manga/model.safetensors"
```

Download links:

* Link 1: <https://huggingface.co/jzhang533/PaddleOCR-VL-For-Manga/tree/main/>
* Link 2: <https://hf-mirror.com/jzhang533/PaddleOCR-VL-For-Manga/tree/main/>

In addition, you need to modify the default prompt for OCR to "OCR" and model name to "paddleocr-vl" in the preferences. Please note that PaddleOCR-VL can only extract the text from an image, without any extra data using deepseek-ocr.rs.


