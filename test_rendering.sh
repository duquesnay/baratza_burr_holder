#!/bin/bash
# Script to test if threading renders correctly in OpenSCAD

# Path to OpenSCAD executable
OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"

# Check if OpenSCAD exists
if [ ! -f "$OPENSCAD" ]; then
    echo "Error: OpenSCAD executable not found at $OPENSCAD"
    exit 1
fi

# Run OpenSCAD in console mode to check for errors
echo "Testing rendering..."
"$OPENSCAD" -o /tmp/test_render.stl burrholder.scad 2>&1 | grep -i "error"

# Check exit status
STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo "Rendering failed - errors detected"
    exit 1
else
    echo "Rendering successful - no errors detected"
    exit 0
fi