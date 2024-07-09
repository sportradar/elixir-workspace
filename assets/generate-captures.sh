#!/bin/bash

# This script is used to generate the images and gifs
#
# It requires the following tools:
# - vhs: https://github.com/charmbracelet/vhs 

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

ROOT_PATH=$(git rev-parse --show-toplevel)

TAPES_PATH=$ROOT_PATH/assets/tapes
DEMO_PATH=$ROOT_PATH/artifacts/workspace_demo
OUTPUT_PATH=$ROOT_PATH/assets/captures

echo "==> deleting demo path $DEMO_PATH if there..."
rm -rf $DEMO_PATH

echo "==> cloning demo project into $DEMO_PATH..."
git clone --depth 1 https://github.com/pnezis/workspace_demo.git $DEMO_PATH

echo "==> getting demo ready for recording..."
cd $DEMO_PATH
mix deps.get
mix workspace.run -t deps.get

echo "==> recording..."
vhs $TAPES_PATH/status.tape -o $OUTPUT_PATH/status.gif
vhs $TAPES_PATH/run.tape -o $OUTPUT_PATH/run.gif
vhs $TAPES_PATH/demo.tape -o $OUTPUT_PATH/demo.gif

git clean -fd
cd $ROOT_PATH

echo "==> cleaning up..."
rm -rf $DEMO_PATH
