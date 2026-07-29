#!/bin/bash
# ==============================================================================
# AUTOMATED WORKSPACE MANAGER - TUSCAN SYSTEM 1 MASTER MONITOR
# ==============================================================================

# 1. Clean up old binary segments
rm -f mitsimon_raw.bin mitsimon_eprom.bin mitsimon.hex

echo "⚙️  Step 1: Compiling Monitor Source..."
z80asm -l -o mitsimon_raw.bin mitsimon.asm > mitsimon.lis 2>&1

echo "✂️  Step 2: Trimming Null Bytes and Aligning Tracks..."
# Strips the lower offsets and the 5 leading null bytes to perfectly align $F800
dd if=mitsimon_raw.bin of=mitsimon_eprom.bin bs=1 skip=154 status=none

# Pad out to absolute 2048-byte EPROM layout using $FF
CURRENT_SIZE=$(wc -c < mitsimon_eprom.bin | tr -d ' ')
PADDING_BYTES=$((2048 - CURRENT_SIZE))
perl -e "print \"\xFF\" x $PADDING_BYTES" >> mitsimon_eprom.bin

echo "� Step 3: Packaging Formatted Intel HEX Object..."
python3 bin2hex.py mitsimon_eprom.bin mitsimon.hex

echo "� Step 4: Booting Virtual Monitor Workspace..."
# Create a temporary pre-boot macro script to inject the IOBYTE automatically
cat << 'EOF' > automacro.txt
f 0000,ffff,00
r mitsimon.hex
x pc
f800
g
EOF

# Launch the simulator, piping the macro straight into the core engine
# TO THIS NEW LIVE INTERACTIVE TERMINAL LOOP:
(cat automacro.txt; cat) | ./z80sim -z -f 4

# Clean up temp file
rm -f automacro.txt

