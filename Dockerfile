# Argument for STM32CubeCLT version (defaults to latest)
# This will be set automatically from the git tag during build
ARG CUBECLT_VERSION=1.15.0

# Base Image with specific STM32CubeCLT version pre-installed
FROM uoohyo/stm32-cmake:${CUBECLT_VERSION}

# Metadata
LABEL org.opencontainers.image.source="https://github.com/uoohyo/action-stm32-cmake"
LABEL org.opencontainers.image.description="Build STM32 projects with STM32CubeCLT ${CUBECLT_VERSION} using CMake"
LABEL org.opencontainers.image.licenses="MIT"

# Override base image USER to run as root in GitHub Actions
# Base image (uoohyo/stm32-cmake) sets USER stm32user for security,
# but GitHub Actions requires root for /github/workspace write access
USER root

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
