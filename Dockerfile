###############################################################################
# Stage 1: Builder (Alpine + Node)
# - Installs playwright-core
# - Extracts the list of native apt dependencies for the target browser
# - Downloads the browser binaries
# It runs on the build machine's architecture and downloads the binaries for
# the target architecture, so multi-platform builds do not emulate Node.
###############################################################################
FROM --platform=$BUILDPLATFORM node:24-alpine AS builder

ARG PLAYWRIGHT_VERSION
ARG PLAYWRIGHT_BROWSER=chromium
# Set by BuildKit: amd64 or arm64.
ARG TARGETARCH
# Must match the final stage's OS (ubuntu:noble = 24.04) and architecture.
# Defaults to ubuntu24.04-x64 or ubuntu24.04-arm64 from TARGETARCH.
ARG PLAYWRIGHT_PLATFORM

WORKDIR /build

RUN if [ -n "${PLAYWRIGHT_PLATFORM}" ]; then platform="${PLAYWRIGHT_PLATFORM}"; \
    elif [ "${TARGETARCH}" = "arm64" ]; then platform="ubuntu24.04-arm64"; \
    else platform="ubuntu24.04-x64"; fi \
    && echo "${platform}" > /platform.txt \
    && echo "=== Playwright platform: ${platform} ==="

# Install playwright-core (no browsers yet, just the library)
RUN npm init -y && npm i "playwright-core@${PLAYWRIGHT_VERSION}"

# Copy the dependency extraction script
COPY get-deps.js .

# 1) Extract native dependencies list
RUN node get-deps.js "$(cat /platform.txt)" "${PLAYWRIGHT_BROWSER}" > /deps.txt \
    && echo "=== Native dependencies ===" && cat /deps.txt

# 2) Download browser binaries (needs a full playwright install for the download)
#    We install the full playwright package just to run `playwright install`.
#    The platform override makes it download the target architecture's binaries.
RUN npm i "playwright@${PLAYWRIGHT_VERSION}" \
    && PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="$(cat /platform.txt)" npx --no -- playwright install "${PLAYWRIGHT_BROWSER}" \
    && cp -a /root/.cache/ms-playwright /ms-playwright \
    && chmod -R 777 /ms-playwright


###############################################################################
# Stage 2: Final image (Ubuntu Noble) — no Node.js at all
###############################################################################
FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=America/Los_Angeles

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Copy the dependency list from builder
COPY --from=builder /deps.txt /tmp/deps.txt

# Install ONLY the native dependencies Playwright needs
RUN apt-get update \
    && apt-get install zstd curl gnupg libatomic1 -y \
    && xargs apt-get install -y --no-install-recommends < /tmp/deps.txt \
    && rm -rf /var/lib/apt/lists/* /tmp/deps.txt

# Copy browser binaries from builder
COPY --from=builder /ms-playwright /ms-playwright