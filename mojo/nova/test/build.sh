# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #

set -euo pipefail

BUILD_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$(realpath "${BUILD_DIR}/..")
SRC_PATH="${REPO_ROOT}/src"

PACKAGE_NAME="nova.mojopkg"
PACKAGE_PATH="${BUILD_DIR}"/"${PACKAGE_NAME}"

echo -e "╓───  Packaging the Nova library"
mojo package "${SRC_PATH}" -o "${PACKAGE_PATH}"
echo Successfully created "${PACKAGE_PATH}"