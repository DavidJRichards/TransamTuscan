import sys

def bin_to_intel_hex(bin_filename, hex_filename, start_address=0xF800):
    try:
        with open(bin_filename, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"❌ Error: File '{bin_filename}' not found.")
        sys.exit(1)
    
    with open(hex_filename, 'w') as f:
        for idx in range(0, len(data), 16):
            chunk = data[idx:idx+16]
            length = len(chunk)
            addr = start_address + idx
            
            # Record type 00 = Data Record
            record = f":{length:02X}{addr:04X}00"
            checksum = length + (addr >> 8) + (addr & 0xFF)
            
            for byte in chunk:
                record += f"{byte:02X}"
                checksum += byte
                
            checksum = (-checksum) & 0xFF
            record += f"{checksum:02X}\n"
            f.write(record)
            
        # Write Intel HEX End of File Record
        f.write(":00000001FF\n")
    print(f"✅ Successfully converted '{bin_filename}' ➡️  '{hex_filename}' at offset 0x{start_address:04X}")

if __name__ == "__main__":
    # If filenames are passed in the terminal, use them. Otherwise, default.
    if len(sys.argv) >= 3:
        bin_in = sys.argv[1]
        hex_out = sys.argv[2]
    else:
        bin_in = 'mitsimon_eprom.bin'
        hex_out = 'mitsimon.hex'
        
    bin_to_intel_hex(bin_in, hex_out)
