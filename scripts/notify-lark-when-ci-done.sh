#!/usr/bin/env bash
# 在本机等待一次 Alloomi CI 结束，再把各平台安装包的下载链接发到 Lark。
#
# 用法：
#   scripts/notify-lark-when-ci-done.sh [run-id]
#   scripts/notify-lark-when-ci-done.sh --dry-run [run-id]
#
# 不写 run-id 时，只等待这两个 workflow 里正在跑的最新一次：
#   CI Alloomi (Main Branch)
#   CI Alloomi (macOS arm64 + Windows)
# 没有正在跑的构建就退出，避免把上一次已经完成的结果再发一遍。
#
# Webhook 地址按这个顺序读，仓库里不放地址：
#   $LARK_CI_WEBHOOK
#   ~/.config/alloomi/lark-ci-webhook   （文件里一行 URL）
set -euo pipefail

REPO="${REPO:-melandlabs/release}"
DRY_RUN=0
RUN_ID=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      if [ -n "$RUN_ID" ]; then
        echo "notify-lark-when-ci-done: 只能有一个 run id" >&2
        exit 2
      fi
      RUN_ID="$arg"
      ;;
  esac
done

webhook_url() {
  if [ -n "${LARK_CI_WEBHOOK:-}" ]; then
    printf '%s' "$LARK_CI_WEBHOOK"
    return
  fi
  local file="${HOME}/.config/alloomi/lark-ci-webhook"
  if [ -f "$file" ]; then
    tr -d '[:space:]' < "$file"
    return
  fi
  echo "notify-lark-when-ci-done: 没有 webhook。设置 LARK_CI_WEBHOOK，或把 URL 写进 ${file}" >&2
  exit 2
}

if [ "$DRY_RUN" -eq 0 ]; then
  WEBHOOK="$(webhook_url)"
  case "$WEBHOOK" in
    https://open.larksuite.com/open-apis/bot/v2/hook/*|https://open.feishu.cn/open-apis/bot/v2/hook/*) ;;
    *)
      echo "notify-lark-when-ci-done: webhook 不是 Lark / 飞书机器人地址" >&2
      exit 2
      ;;
  esac
fi

pick_running_run() {
  gh run list --repo "$REPO" --limit 20 --json databaseId,status,workflowName,createdAt \
    --jq '[.[] | select(.status=="in_progress" or .status=="queued") | select(.workflowName=="CI Alloomi (Main Branch)" or .workflowName=="CI Alloomi (macOS arm64 + Windows)")] | sort_by(.createdAt) | reverse | .[0].databaseId // empty'
}

if [ -z "$RUN_ID" ]; then
  RUN_ID="$(pick_running_run)"
  if [ -z "$RUN_ID" ]; then
    echo "notify-lark-when-ci-done: 没有正在跑的 Alloomi CI。请传入 run id。" >&2
    exit 1
  fi
fi

echo "等待 run ${RUN_ID}"
echo "https://github.com/${REPO}/actions/runs/${RUN_ID}"

while true; do
  view="$(gh run view "$RUN_ID" --repo "$REPO" --json status,conclusion,displayTitle,url,jobs \
    --jq '{status,conclusion,displayTitle,url,jobs:[.jobs[]|{name,conclusion}]}')"
  run_status="$(printf '%s' "$view" | jq -r '.status')"
  if [ "$run_status" = "completed" ]; then
    break
  fi
  echo "$(date '+%H:%M:%S') 仍在 ${run_status}"
  sleep 30
done

artifacts="$(gh api --paginate "repos/${REPO}/actions/runs/${RUN_ID}/artifacts" \
  --jq '.artifacts[] | {name,id,size_in_bytes,expired}')"

export NOTIFY_VIEW="$view"
export NOTIFY_ARTIFACTS="$artifacts"
export NOTIFY_RUN_ID="$RUN_ID"
export NOTIFY_REPO="$REPO"

payload="$(python3 <<'PY'
import json, os, sys

view = json.loads(os.environ["NOTIFY_VIEW"])
artifacts = []
blob = os.environ.get("NOTIFY_ARTIFACTS", "").strip()
if blob:
    for line in blob.splitlines():
        line = line.strip()
        if not line:
            continue
        artifacts.append(json.loads(line))

repo = os.environ["NOTIFY_REPO"]
run_id = os.environ["NOTIFY_RUN_ID"]
conclusion = view.get("conclusion") or ""
title = view.get("displayTitle") or ""
run_url = view.get("url") or f"https://github.com/{repo}/actions/runs/{run_id}"

order = {
    "macOS Apple 芯片（arm64）": 0,
    "macOS Intel（x64）": 1,
    "Windows x64": 2,
    "Windows arm64": 3,
    "Linux amd64": 4,
    "Linux arm64": 5,
}

def label(name: str) -> str:
    outlook = "，Outlook 中国版" if "outlook-china" in name else ""
    low = name.lower()
    if low.endswith(".dmg") and "aarch64" in low:
        base = "macOS Apple 芯片（arm64）"
    elif low.endswith(".dmg") and ("x64" in low or "amd64" in low):
        base = "macOS Intel（x64）"
    elif low.endswith(".exe") and "arm64" in low:
        base = "Windows arm64"
    elif low.endswith(".exe"):
        base = "Windows x64"
    elif low.endswith(".deb") and "amd64" in low:
        base = "Linux amd64"
    elif low.endswith(".deb") and "arm64" in low:
        base = "Linux arm64"
    else:
        base = name
    return base + outlook

rows = []
for item in artifacts:
    if item.get("expired") is True:
        continue
    name = item.get("name")
    art_id = item.get("id")
    if not isinstance(name, str) or not isinstance(art_id, int):
        raise SystemExit("artifact 缺少 name 或 id")
    size = item.get("size_in_bytes")
    mb = f"{round(size / 1048576)} MB" if isinstance(size, int) else ""
    href = f"https://github.com/{repo}/actions/runs/{run_id}/artifacts/{art_id}"
    rows.append((label(name), name, mb, href))

rows.sort(key=lambda row: (order.get(row[0].split("，")[0], 99), row[1]))

failed = []
for job in view.get("jobs") or []:
    if job.get("conclusion") in ("failure", "cancelled"):
        failed.append(f"{job.get('name')}={job.get('conclusion')}")

def line(text):
    return [[{"tag": "text", "text": text}]]

def link(href):
    return [[{"tag": "a", "text": href, "href": href}]]

content = []
if conclusion == "success":
    head = f"Alloomi 打包完成 · {title}"
    content.extend(line("构建已成功。打开链接需要登录 GitHub。"))
else:
    head = f"Alloomi 打包未完成 · {title}"
    content.extend(line(f"构建结果：{conclusion}。"))
    if failed:
        content.extend(line("未成功的任务：" + "；".join(failed)))
    if rows:
        content.extend(line("已经上传的安装包："))

content.extend(line("构建页面"))
content.extend(link(run_url))
for platform, name, mb, href in rows:
    size_bit = f"（{mb}）" if mb else ""
    content.extend(line(f"{platform}  {name}{size_bit}"))
    content.extend(link(href))

if conclusion == "success" and not rows:
    content.extend(line("这次没有安装包。"))

payload = {
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": head,
                "content": content,
            }
        }
    },
}
json.dump(payload, sys.stdout, ensure_ascii=False)
print()
PY
)"

python3 -c '
import json, sys
payload = json.loads(sys.stdin.read())
content = payload["content"]["post"]["zh_cn"]["content"]
texts = []
for row in content:
    for part in row:
        if part.get("tag") == "text":
            texts.append(part["text"])
        elif part.get("tag") == "a":
            href = part.get("href")
            if not isinstance(href, str) or not href.startswith("https://github.com/"):
                raise SystemExit("链接不是 GitHub 地址")
            texts.append(href)
blob = "\n".join(texts)
for bad in ("[object Object]", "undefined", "NaN"):
    if bad in blob:
        raise SystemExit("通知正文有空值")
print(payload["content"]["post"]["zh_cn"]["title"])
for text in texts:
    print(text)
' <<<"$payload"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run：未发送"
  exit 0
fi

response="$(curl -fsS -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  --data-binary "$payload")"
printf '%s\n' "$response"
python3 -c '
import json, sys
body = json.loads(sys.stdin.read())
code = body.get("code", body.get("StatusCode"))
if code != 0:
    raise SystemExit(f"Lark 返回 code={code}")
' <<<"$response"
echo "已发到 Lark"
