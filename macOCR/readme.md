macOS's built-in OCR service.

Combinations:
- `mac`: Live Text mode (default), line level
- `word level (mac)`: Live Text mode, word/character level
- `accurate (mac)`: accurate mode, line level
- `accurate word level (mac)`: accurate mode, word/character level

Live Text is used by default. It falls back to accurate mode automatically on systems that do not support it.
Unlike accurate mode, Live Text's language setting does not restrict the recognized languages.

See <https://github.com/xulihang/ImageTrans-docs/issues/341>