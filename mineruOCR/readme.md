# MinerU OCR

使用 MinerU 进行 OCR 和布局分析的插件。

## 功能

- OCR 文字识别
- OCR 文字识别（含位置信息）
- 布局分析

## 模式判断

通过 `host` 参数自动区分：

- **包含 `/api/v4`** → 云端 API 模式，使用 Precision Extract API
- **不包含** → 本地部署模式，使用 `/file_parse` 接口直接上传图片

## 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| key | API Token（云端模式需要） | 空 |
| host | MinerU 服务地址 | `https://mineru.net/api/v4` |
| is_ocr | 是否启用 OCR | true |
| enable_formula | 是否启用公式识别 | true |
| enable_table | 是否启用表格识别 | true |
| language | 文档语言 | ch |

## Token 获取

从 https://mineru.net/apiManage/token 申请 API Token。
