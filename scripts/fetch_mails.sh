#!/usr/bin/env bash
set -euo pipefail

# ─── 配置 ──────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LORE_BASE="https://lore.kernel.org"
# 关注的内核邮件列表 (list_name:lore_name)
# linux-kernel 在 lore 上叫 lkml
LISTS=(
  "linux-kernel:lkml"
  "netdev:netdev"
  "linux-mm:linux-mm"
  "linux-block:linux-block"
  "linux-pm:linux-pm"
  "linux-security-module:linux-security-module"
  "stable:stable"
  "regressions:regressions"
)
# 取最近 N 天
DAYS=${DAYS:-7}
SINCE_DATE=$(date -u -d "${DAYS} days ago" +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

RAW_DIR="$REPO_DIR/.raw"
OUTPUT="$REPO_DIR/issues/${TODAY}-kernel-weekly.md"

mkdir -p "$RAW_DIR"
# 清理上次残留
rm -rf "$RAW_DIR"/*.txt "$RAW_DIR"/*.json "$RAW_DIR"/git_*

ALL_DATA="$RAW_DIR/all_mails_${TODAY}.tsv"
> "$ALL_DATA"

echo ">>> Fetching lore.kernel.org mailing lists (since ${SINCE_DATE})..."

# ─── 找到每个列表的最新 epoch ──────────────────────────
find_latest_epoch() {
  local lore_name="$1"
  local latest=-1
  for i in $(seq 0 30); do
    if timeout 10 git ls-remote "https://lore.kernel.org/${lore_name}/${i}" HEAD 2>/dev/null | grep -q .; then
      latest=$i
    else
      break
    fi
  done
  echo "$latest"
}

# ─── 爬取每个列表 ──────────────────────────────────────
for entry in "${LISTS[@]}"; do
  IFS=':' read -r list_name lore_name <<< "$entry"
  echo "  - $list_name (lore: $lore_name)"

  # 找到最新 epoch
  latest_epoch=$(find_latest_epoch "$lore_name")
  if [ "$latest_epoch" -lt 0 ]; then
    echo "    WARNING: no epoch found for $lore_name, skipping"
    continue
  fi
  echo "    latest epoch: $latest_epoch"

  # 也检查前一个 epoch（以防新 epoch 刚开始）
  epochs_to_fetch=()
  if [ "$latest_epoch" -gt 0 ]; then
    epochs_to_fetch+=("$((latest_epoch - 1))")
  fi
  epochs_to_fetch+=("$latest_epoch")

  for epoch in "${epochs_to_fetch[@]}"; do
    clone_dir="$RAW_DIR/git_${lore_name}_${epoch}"
    if [ -d "$clone_dir" ]; then
      rm -rf "$clone_dir"
    fi

    # 用 shallow-since 只拉取最近的提交
    timeout 120 git clone --quiet --shallow-since="${SINCE_DATE}" \
      "https://lore.kernel.org/${lore_name}/${epoch}" "$clone_dir" 2>/dev/null || {
      echo "    (epoch $epoch: clone failed or empty, skipping)"
      continue
    }

    # 提取邮件元数据：hash|date|author|subject
    count=$(git -C "$clone_dir" log --since="${SINCE_DATE}" --until="${TODAY}" \
      --format="%H|%aI|%an|%s" 2>/dev/null | wc -l)
    echo "    epoch $epoch: $count emails"

    # 写入数据文件，加上列表名前缀
    git -C "$clone_dir" log --since="${SINCE_DATE}" --until="${TODAY}" \
      --format="%H|%aI|%an|%s" 2>/dev/null | \
      while IFS='|' read -r hash date author subject; do
        echo -e "${list_name}\t${hash}\t${date}\t${author}\t${subject}"
      done >> "$ALL_DATA"
  done
done

TOTAL=$(wc -l < "$ALL_DATA")
echo ">>> Total emails fetched: $TOTAL"

# ─── 生成原始数据汇总（供 AI 分析） ─────────────────────
RAW_SUMMARY="$RAW_DIR/raw_summary_${TODAY}.txt"
{
  echo "# Raw Mail Summary - ${TODAY}"
  echo "# Source: lore.kernel.org (via git clone)"
  echo "# Lists: ${LISTS[*]}"
  echo "# Period: ${SINCE_DATE} to ${TODAY}"
  echo "# Total emails: $TOTAL"
  echo ""
} > "$RAW_SUMMARY"

echo ">>> Raw data saved to $ALL_DATA"
echo ">>> Raw summary saved to $RAW_SUMMARY"
