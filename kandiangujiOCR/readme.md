# 看典古籍 OCR

使用看典古籍 API 进行古籍 OCR 文字识别和布局分析的插件。

## 功能

- OCR 文字识别
- OCR 文字识别（含位置信息）
- 布局分析

## API 文档

https://kandianguji.com/article_detail?id=33

## Token 获取

在 https://www.kandianguji.com/shuzihua?page_mode=ocr_api 注册账号并申请 API Token。

## 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| email | 注册账号（邮箱或手机号） | 空 |
| token | API Token | 空 |
| det_mode | 排版方向: `auto`/`sp`(竖排)/`hp`(横排) | auto |
| version | 算法版本: `default`/`beta`/`v2` | v2 |
| return_position | 是否返回坐标信息 | true |
