
## Plugin to Use ChatGPT for Machine Translation

Related issue: <https://github.com/xulihang/ImageTrans-docs/issues/375>

Usage:

1. Enter your key in the API preference settings.
2. You can customize the prompt in the settings as well. `{langcode}`, `{source}` and `{term}` will be replaced with the name of the target language, the source text and the glossary. Batch translation sends the source as numbered lines (`1. ...`, `2. ...`) and the default prompts ask for one numbered line per item back. Matching by that number keeps a comic page aligned even when a translation wraps onto a second line or the model echoes part of the instruction, which is what used to scramble the order. A JSON answer keyed by id is understood as well. A line break inside an item's own text is sent as `\n` and comes back as a real line break in the translation. The default prompts spell this out; if you write your own prompt, keep the `\n` in the answer where the break belongs, or the break will be lost.
   - If you customized `batch_prompt` / `vision_batch_prompt` (or their `_with_term` variants) before, your saved prompt is used as is. The plugin still understands a plain one-line-per-item answer, but it will not get the numbered alignment unless you reset the prompt to the new default.
3. You can use third-party ChatGPT hosts by setting the host parameter.

### Blog

https://www.basiccat.org/ChatGPT-image-translator/
