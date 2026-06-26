#!/bin/bash
set -e

# Change directory to the repository root
cd "$(dirname "$0")/.."

echo "Zipping Windows release..."
# Remove old zip if it exists to start fresh
rm -f bin/Windows/ComplexFunctionsExplorer.zip

# Zip the Windows executable and GDExtension DLL
zip bin/Windows/ComplexFunctionsExplorer.zip bin/Windows/ComplexFunctionsExplorer.exe bin/libcomplex_functions.windows.template_release.x86_64.dll

echo "Building Linux AppImage..."
# Ensure the destination directory exists
mkdir -p bin/Linux

# Remove any old AppImage output
rm -f bin/Linux/Complex_Functions_Explorer-x86_64.AppImage

# Run the AppImage tool specifying the output path
./bin/appimagetool-x86_64.AppImage bin/ComplexFunctionsExplorer.AppDir bin/Linux/Complex_Functions_Explorer-x86_64.AppImage

echo "Packaging complete!"
