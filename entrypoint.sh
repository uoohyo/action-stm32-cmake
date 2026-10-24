#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

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

# Parse shell-style quoting without evaluating substitutions or shell commands.
source "$SCRIPT_DIR/parse-cmake-args.sh"
parse_cmake_args "$CMAKE_ARGS" || exit 1

PRESET_NAME=""
for ((i=0; i<${#EXTRA_ARGS[@]}; i++)); do
    case "${EXTRA_ARGS[i]}" in
        --preset)
            if (( i + 1 >= ${#EXTRA_ARGS[@]} )); then
                echo "[ERROR] --preset requires a value"
                exit 1
            fi
            PRESET_NAME="${EXTRA_ARGS[i+1]}"
            ;;
        --preset=*)
            PRESET_NAME="${EXTRA_ARGS[i]#--preset=}"
            ;;
    esac
done

CONFIG_LOG=$(mktemp)
trap 'rm -f "$CONFIG_LOG"' EXIT

if [ -n "$PRESET_NAME" ]; then
    echo ">>> Configuring CMake preset: $PRESET_NAME"
    # The preset determines both generator and binaryDir.
    if ! cmake -S . "${EXTRA_ARGS[@]}" 2>&1 | tee "$CONFIG_LOG"; then
        echo "[ERROR] Preset configuration failed"
        exit 1
    fi
    BUILD_DIR=$(sed -n 's/^-- Build files have been written to: //p' "$CONFIG_LOG" | tail -1)
    if [ -z "$BUILD_DIR" ] || [ ! -d "$BUILD_DIR" ]; then
        echo "[ERROR] Could not determine configured preset binaryDir"
        exit 1
    fi
else
    BUILD_DIR="$PROJECT_PATH/build"
    mkdir -p "$BUILD_DIR"
    if ! cmake -S . -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE="$BUILD_CONFIG" "${EXTRA_ARGS[@]}"; then
        echo "[ERROR] CMake configuration failed"
        exit 1
    fi
fi

echo ">>> Building target: $BUILD_TARGET"
cmake --build "$BUILD_DIR" --target "$BUILD_TARGET" || {
    echo "[ERROR] CMake build failed"
    exit 1
}

echo ""
echo "=== Build Complete ==="
echo "Build artifacts are in: $BUILD_DIR"
find "$BUILD_DIR" -maxdepth 2 -type f \( -name '*.elf' -o -name '*.bin' -o -name '*.hex' \) -print | head -20
