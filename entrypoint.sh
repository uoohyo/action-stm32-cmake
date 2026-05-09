#!/bin/bash
set -e

# Banner
cat << 'EOF'

 $$$$$$\              $$\     $$\                            $$$$$$\ $$$$$$$$\ $$\      $$\  $$$$$$\   $$$$$$\           $$$$$$\  $$\      $$\  $$$$$$\  $$\   $$\ $$$$$$$$\ 
$$  __$$\             $$ |    \__|                          $$  __$$\\__$$  __|$$$\    $$$ |$$ ___$$\ $$  __$$\         $$  __$$\ $$$\    $$$ |$$  __$$\ $$ | $$  |$$  _____|
$$ /  $$ | $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\        $$ /  \__|  $$ |   $$$$\  $$$$ |\_/   $$ |\__/  $$ |        $$ /  \__|$$$$\  $$$$ |$$ /  $$ |$$ |$$  / $$ |      
$$$$$$$$ |$$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\       \$$$$$$\    $$ |   $$\$$\$$ $$ |  $$$$$ /  $$$$$$  |$$$$$$\ $$ |      $$\$$\$$ $$ |$$$$$$$$ |$$$$$  /  $$$$$\    
$$  __$$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |       \____$$\   $$ |   $$ \$$$  $$ |  \___$$\ $$  ____/ \______|$$ |      $$ \$$$  $$ |$$  __$$ |$$  $$<   $$  __|   
$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |      $$\   $$ |  $$ |   $$ |\$  /$$ |$$\   $$ |$$ |              $$ |  $$\ $$ |\$  /$$ |$$ |  $$ |$$ |\$$\  $$ |      
$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |      \$$$$$$  |  $$ |   $$ | \_/ $$ |\$$$$$$  |$$$$$$$$\         \$$$$$$  |$$ | \_/ $$ |$$ |  $$ |$$ | \$$\ $$$$$$$$\ 
\__|  \__| \_______|   \____/ \__| \______/ \__|  \__|       \______/   \__|   \__|     \__| \______/ \________|         \______/ \__|     \__|\__|  \__|\__|  \__|\________|

                                                               STMicroelectronics STM32CubeCLT CMake Builder for GitHub Actions
                                                                                                             Creative by Uoohyo
                                                                                                      https://github.com/uoohyo

EOF

# STM32CubeCLT installation directory (from docker-stm32-cmake)
CUBECLT_INSTALL_DIR="/opt/st/stm32cubeclt"

# Verify installation
if [ ! -d "$CUBECLT_INSTALL_DIR" ]; then
    echo "[ERROR] STM32CubeCLT installation not found at ${CUBECLT_INSTALL_DIR}"
    exit 1
fi

echo "=== STM32CubeCLT Environment ==="
echo "Version      : ${CUBECLT_VERSION:-unknown}"
echo "Installation : ${CUBECLT_INSTALL_DIR}"
echo ""

echo "Available tools:"
if command -v arm-none-eabi-gcc &> /dev/null; then
    echo "  • ARM GCC     : $(arm-none-eabi-gcc --version | head -1)"
else
    echo "  ✗ ARM GCC     : not found"
fi

if command -v cmake &> /dev/null; then
    echo "  • CMake       : $(cmake --version | head -1)"
else
    echo "  ✗ CMake       : not found"
fi

if command -v ninja &> /dev/null; then
    echo "  • Ninja       : $(ninja --version)"
else
    echo "  ✗ Ninja       : not found"
fi

if command -v STM32_Programmer_CLI &> /dev/null; then
    echo "  • Programmer  : $(STM32_Programmer_CLI --version 2>&1 | head -1 || echo 'installed')"
fi

echo ""

# Parse arguments
PROJECT_PATH="/github/workspace/$1"
BUILD_CONFIG="$2"
BUILD_TARGET="$3"
CMAKE_ARGS="$4"

echo "=== CMake Build Configuration ==="
echo "Project Path    : ${PROJECT_PATH}"
echo "Build Config    : ${BUILD_CONFIG}"
echo "Build Target    : ${BUILD_TARGET}"
echo "CMake Arguments : ${CMAKE_ARGS}"
echo ""

# Verify project path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "[ERROR] Project path does not exist: ${PROJECT_PATH}"
    exit 1
fi

# Verify CMakeLists.txt exists
if [ ! -f "$PROJECT_PATH/CMakeLists.txt" ]; then
    echo "[ERROR] CMakeLists.txt not found in ${PROJECT_PATH}"
    echo "Please ensure your project-path points to a directory containing CMakeLists.txt"
    exit 1
fi

# Navigate to project directory
cd "$PROJECT_PATH"

# Create and enter build directory
BUILD_DIR="build"
echo ">>> Creating build directory: ${BUILD_DIR}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo ">>> Configuring CMake..."
CMAKE_CMD="cmake .. -G Ninja -DCMAKE_BUILD_TYPE=${BUILD_CONFIG}"

# Append additional CMake arguments if provided
if [ -n "$CMAKE_ARGS" ]; then
    CMAKE_CMD="${CMAKE_CMD} ${CMAKE_ARGS}"
fi

echo "Running: $CMAKE_CMD"
eval "$CMAKE_CMD" || {
    echo "[ERROR] CMake configuration failed"
    exit 1
}

echo ""

# Build with Ninja
echo ">>> Building target: ${BUILD_TARGET}"
ninja "$BUILD_TARGET" || {
    echo "[ERROR] Build failed"
    exit 1
}

echo ""
echo "=== Build Complete ==="
echo "Build artifacts are in: ${PROJECT_PATH}/${BUILD_DIR}"
echo ""

# List build outputs
if compgen -G "*.elf" > /dev/null || compgen -G "*.bin" > /dev/null || compgen -G "*.hex" > /dev/null; then
    echo "Generated binaries:"
    ls -lh *.elf *.bin *.hex 2>/dev/null || true
fi
