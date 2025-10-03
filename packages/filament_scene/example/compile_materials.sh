#!/bin/bash -e

# This script compiles all Filament materials

matc="../../../../filament/cmake-build-release/staging/release/bin/matc"

# Find all materials in directory
source_path="assets/materials/raw"
dest_path="assets/materials"
find "$source_path" -name '*.mat' | while read material; do
    # Get the base name of the material file
    name=$(basename "$material" .mat)
    echo "Compiling $material"
    "$matc" -a vulkan -p all -o "$dest_path/$name.filamat" "$source_path/$name.mat"
done
