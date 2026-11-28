#!/usr/bin/env bash
# Write the .env that ships inside a desktop bundle.
#
# Usage:
#   bash scripts/write-desktop-env.sh [alloomi_dir] [region]
#
# Defaults: alloomi_dir=./alloomi, region=intl
#
# Why this is a script and not a heredoc in the workflow: the file was written
# inline in five places (one per platform job) and the copies had already
# drifted apart in comments and blank lines. The values were the same, but a
# reader had to diff five blocks to know that. One writer, one place to
# change, and a region switch that cannot half-apply.
#
# The file matters: apps/web/src-tauri/tauri.conf.* lists ../.env as a bundle
# resource, so it ships inside the .app and the Next.js standalone server
# reads it at runtime. It decides which cloud the installed client talks to.
#
# Two regions, two sets of endpoints:
#
#   intl (default)  app.alloomi.ai, providers reached through OpenRouter
#   cn              app.alloomi.cn, providers reached through the China
#                   gateway (ai.app.alloomi.cn), which serves logical routes
#                   (default / flash / pro / vision / ...) rather than
#                   provider model ids.
#
# The region also selects the Tauri config (src-tauri/tauri.conf.<region>.json,
# via apps/web/scripts/tauri-build-region.mjs) and the ALLOOMI_REGION that
# gets compiled into the Rust binary, so the installed client defaults to the
# cn cloud, the cn data root (~/.alloomi-cn) and the cn update channel
# (https://download.alloomi.cn) with no user-side configuration.
#
# Not set here on purpose for cn: LLM_IMAGE_MODEL and the LLM_EMBEDDING_*
# pair. The embedding route resolves them from the region defaults when they
# are absent (text-embedding-v3 on the Bailian endpoint), and the desktop
# forwards embedding calls to the cloud instead of calling the provider, so
# shipping a provider model id or a key in the bundle would be wrong. There is
# no image model on the cn gateway yet; the images route reports that instead
# of guessing a provider.
#
# Set here for cn: NEXT_PUBLIC_ENABLE_OUTLOOK_CHINA=1. The Outlook China
# (21Vianet) connector is part of the China distribution, so every cn build
# ships the connector tile. The switch is read at build time (Next.js inlines
# NEXT_PUBLIC_* into the browser bundle), which is why it lives in this file
# and not in the workflow environment.
set -euo pipefail

REPO="${1:-alloomi}"
REGION="${2:-intl}"
ENV_FILE="${REPO}/apps/web/.env"

case "$REGION" in
  cn | china | cn-cn)
    REGION="cn"
    ;;
  intl | international | global | "")
    REGION="intl"
    ;;
  *)
    echo "write-desktop-env: unknown region '${REGION}' (expected intl or cn)" >&2
    exit 2
    ;;
esac

if [ ! -d "${REPO}/apps/web" ]; then
  echo "write-desktop-env: ${REPO}/apps/web not found" >&2
  exit 1
fi

case "$REGION" in
  cn)
    cat > "$ENV_FILE" << 'EOF'

# Cloud API Configuration for Tauri Desktop App (China region)
CLOUD_API_URL=https://app.alloomi.cn
NEXT_PUBLIC_CLOUD_API_URL=https://app.alloomi.cn

# Local development URL (for Tauri mode)
NEXT_PUBLIC_APP_URL=http://localhost:3415

# The China LLM gateway. It serves logical routes, not provider model ids,
# so every model below is a route name.
LLM_BASE_URL=https://ai.app.alloomi.cn/v1
LLM_MODEL=default
LLM_REASONING_MODEL=default
LLM_VISION_LANGUAGE_MODEL=default

TELEGRAM_MODE=pooling

ANTHROPIC_BASE_URL=http://localhost:3415/api/ai
API_TIMEOUT_MS=3000000
IS_TAURI=true

# The Outlook China (21Vianet) connector ships in the China distribution:
# every cn build surfaces the connector tile. Next.js inlines NEXT_PUBLIC_*
# at build time, so the switch has to live in this file -- the one that ships
# inside the bundle and that the packaged server reads at runtime.
#
# It does NOT change the updater's asset prefix (apps/web/lib/tauri.ts): the
# cn update channel publishes the standard Alloomi_* set and this build
# downloads from that channel.
NEXT_PUBLIC_ENABLE_OUTLOOK_CHINA=1

EOF
    ;;
  intl)
    cat > "$ENV_FILE" << 'EOF'

# Cloud API Configuration for Tauri Desktop App
CLOUD_API_URL=https://app.alloomi.ai
NEXT_PUBLIC_CLOUD_API_URL=https://app.alloomi.ai

# Local development URL (for Tauri mode)
NEXT_PUBLIC_APP_URL=http://localhost:3415

LLM_BASE_URL=https://openrouter.ai/api/v1
LLM_MODEL=google/gemini-3-flash-preview
LLM_REASONING_MODEL=google/gemini-3-flash-preview
LLM_VISION_LANGUAGE_MODEL=google/gemini-3-flash-preview
LLM_IMAGE_MODEL=openai/gpt-5-image

LLM_EMBEDDING_MODEL=qwen/qwen3-embedding-4b
LLM_EMBEDDING_BASE_URL=https://openrouter.ai/api/v1

TELEGRAM_MODE=pooling

ANTHROPIC_BASE_URL=http://localhost:3415/api/ai
API_TIMEOUT_MS=3000000
IS_TAURI=true

EOF
    ;;
esac

echo "write-desktop-env: region=${REGION} → ${ENV_FILE}"
cat "$ENV_FILE"
