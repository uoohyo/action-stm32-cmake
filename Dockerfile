# Argument for STM32CubeCLT version (defaults to latest)
# This will be set automatically from the git tag during build
ARG CUBECLT_VERSION=latest

# Base Image with specific STM32CubeCLT version pre-installed
FROM uoohyo/stm32-cmake:${CUBECLT_VERSION}

# Metadata
LABEL org.opencontainers.image.source="https://github.com/uoohyo/action-stm32-cmake"
LABEL org.opencontainers.image.description="Build STM32 projects with STM32CubeCLT ${CUBECLT_VERSION} using CMake"
LABEL org.opencontainers.image.licenses="MIT"

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
