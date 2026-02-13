###############################################################################
# Stage 1: Builder (Alpine + Node)
# - Installs playwright-core
# - Extracts the list of native apt dependencies for the target browser
# - Downloads the browser binaries
###############################################################################
FROM node:24-alpine AS builder

ARG PLAYWRIGHT_VERSION
ARG PLAYWRIGHT_BROWSER=chromium
# Must match the final stage's OS. ubuntu:noble = 24.04
ARG PLAYWRIGHT_PLATFORM=ubuntu24.04-x64

WORKDIR /build

# Install playwright-core (no browsers yet, just the library)
RUN npm init -y && npm i "playwright-core@${PLAYWRIGHT_VERSION}"

# Copy the dependency extraction script
COPY get-deps.js .

# 1) Extract native dependencies list
RUN node get-deps.js "${PLAYWRIGHT_PLATFORM}" "${PLAYWRIGHT_BROWSER}" > /deps.txt \
    && echo "=== Native dependencies ===" && cat /deps.txt

# 2) Download browser binaries (needs a full playwright install for the download)
#    We install the full playwright package just to run `playwright install`
RUN npm i "playwright@${PLAYWRIGHT_VERSION}" \
    && npx --no -- playwright install "${PLAYWRIGHT_BROWSER}" \
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

# Copy the dependency list from builder
COPY --from=builder /deps.txt /tmp/deps.txt

# Install ONLY the native dependencies Playwright needs
RUN apt-get update \
    && xargs apt-get install -y --no-install-recommends < /tmp/deps.txt \
    && rm -rf /var/lib/apt/lists/* /tmp/deps.txt

# Copy browser binaries from builder
COPY --from=builder /ms-playwright /ms-playwright