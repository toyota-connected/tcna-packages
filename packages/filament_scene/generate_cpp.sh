#!/bin/bash -e

# NOTE: This script is meant to be run inside a `workspace-automation` instance

# This script generates the C++ interface code using the pigeon tool,
# then moves the generated files to the correct location,
# and formats/lints them with Clang as per project guidelines

# Check if in workspace-automation (if FLUTTER_WORKSPACE defined, or 'workspace-automation' is part of the current path)
if [ -z "$FLUTTER_WORKSPACE" ] && [[ ! "$PWD" == *"workspace-automation"* ]]; then
  echo "This script is meant to be run inside a workspace-automation instance"
  exit 1
fi

# Run pigeon
dart run pigeon \
    --input pigeons/messages.dart

# Move generated files to the correct location (overwriting existing files with o
mv -f generated/src/dart/messages.g.dart lib/generated/
mv -f generated/src/cpp/messages.g.* ../../../ivi-homescreen-plugins/plugins/filament_view/

# Remove generated directory
rm -rf generated

# Format and lint the generated files
cd ../../../ivi-homescreen-plugins/
# format
find plugins -type d -name third_party -prune -false -o -name '*.cc' -o -name '*.hpp' -o -name '*.h' > clang-format-files
clang-format-18 -i --files=clang-format-files
# lint/tidy
# TODO: implement linting
