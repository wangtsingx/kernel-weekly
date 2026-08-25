# kernel-weekly

自动爬取 [lore.kernel.org](https://lore.kernel.org) 最近一周的邮件列表，使用 AI 分析问题类型、严重程度和修复方案，生成周刊并推送到本仓库。

## 自动化机制

- **平台**: Multica autopilot（每周一 09:00 CST 自动触发）
- **流程**: 爬取 → AI 分析 → 生成 Markdown 周刊 → git commit & push
- **输出**: `issues/` 目录下按日期归档的周刊文件

## 目录结构

```
issues/
  2026-08-25-kernel-weekly.md    # 每周周刊
scripts/
  fetch_and_analyze.sh           # 爬取+分析脚本
README.md
```

## 周刊内容

每期周刊包含：

- 本周邮件统计（按子列表分类）
- 重点问题清单（按严重程度排序）
- AI 分析的问题类型、影响范围、修复方案
- 关键补丁链接
