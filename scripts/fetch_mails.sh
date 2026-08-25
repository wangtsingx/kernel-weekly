#!/usr/bin/env bash
set -euo pipefail

# ─── 配置 ──────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ISSUES_DIR="$REPO_DIR/issues"
LORE_BASE="https://lore.kernel.org"
# 关注的内核邮件列表
LISTS=(
  "linux-kernel"
  "netdev"
  "linux-mm"
  "linux-block"
  "linux-pm"
  "linux-security-module"
  "stable"
  "regressions"
)
# 取最近 N 天
DAYS=${DAYS:-7}
# 输出文件
TODAY=$(date -u +%Y-%m-%d)
RAW_DIR="$REPO_DIR/.raw"
OUTPUT="$ISSUES_DIR/${TODAY}-kernel-weekly.md"

mkdir -p "$ISSUES_DIR" "$RAW_DIR"

# ─── 爬取 lore.kernel.org 邮件列表 ────────────────────
echo ">>> Fetching lore.kernel.org mailing lists (last ${DAYS} days)..."

# lore.kernel.org 提供 mbox 格式下载，支持 ?q= 查询
# 使用公开 API: https://lore.kernel.org/<list>/?q=...
SINCE_DATE=$(date -u -d "${DAYS} days ago" +%Y-%m-%d)

fetch_list() {
  local list="$1"
  local out="$RAW_DIR/${list}.mbox"
  echo "  - $list (since $SINCE_DATE)"

  # lore.kernel.org 支持下载整个列表的 mbox
  # 使用 /all/?q=lst:<list>+AND+after:<date> 查询
  local url="${LORE_BASE}/all/?q=lst%3A${list}+AND+dt%3A${SINCE_DATE}&x=A"
  # 备用: 直接拉取列表的新邮件索引
  curl -sf -L "$url" -o "$out" 2>/dev/null || {
    # 备用方案: 用 lore API
    curl -sf -L "${LORE_BASE}/${list}/" -o "$RAW_DIR/${list}.html" 2>/dev/null || true
  }
}

for list in "${LISTS[@]}"; do
  fetch_list "$list"
done

# ─── 提取邮件标题和链接 ────────────────────────────────
echo ">>> Extracting email subjects..."

ALL_SUBJECTS="$RAW_DIR/subjects.txt"
> "$ALL_SUBJECTS"

for list in "${LISTS[@]}"; do
  html="$RAW_DIR/${list}.html"
  mbox="$RAW_DIR/${list}.mbox"

  if [[ -f "$mbox" && -s "$mbox" ]]; then
    # 从 mbox 提取 Subject 行
    grep -i "^Subject:" "$mbox" 2>/dev/null | \
      sed 's/^Subject: \[.*\] //' | \
      sed 's/^Subject: //I' | \
      sort -u >> "$ALL_SUBJECTS" || true
  elif [[ -f "$html" && -s "$html" ]]; then
    # 从 HTML 提取邮件标题
    grep -oP '(?<=<a class="subject-link" href=")[^"]+' "$html" 2>/dev/null >> "$ALL_SUBJECTS" || true
  fi
done

# 清理、去重、排序
sort -u "$ALL_SUBJECTS" -o "$ALL_SUBJECTS"
SUBJECT_COUNT=$(wc -l < "$ALL_SUBJECTS")
echo "  Total unique subjects: $SUBJECT_COUNT"

# ─── 生成原始数据汇总（供 AI 分析） ─────────────────────
RAW_SUMMARY="$RAW_DIR/raw_summary_${TODAY}.txt"
{
  echo "# Raw Mail Summary - ${TODAY}"
  echo "# Source: lore.kernel.org"
  echo "# Lists: ${LISTS[*]}"
  echo "# Period: ${SINCE_DATE} to ${TODAY}"
  echo "# Total subjects: $SUBJECT_COUNT"
  echo ""
  echo "## All Subjects"
  echo "```"
  cat "$ALL_SUBJECTS"
  echo "```"
} > "$RAW_SUMMARY"

echo ">>> Raw summary saved to $RAW_SUMMARY"
echo ">>> Next step: AI analysis on $RAW_SUMMARY"
