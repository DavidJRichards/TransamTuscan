import re
import sys

def parse_z80_to_dot(asm_path, dot_path):
    # Match labels starting a line or ending with a colon: "MainLoop:" or "MainLoop"
    label_def_regex = re.compile(r'^\s*([a-zA-Z_][a-zA-Z0-9_]*):')
    
    # Match branching commands: CALL, JP, JR, DJNZ
    # Account for optional conditional prefixes: "JP NZ, Target" or "JR C, Target"
    branch_regex = re.compile(
        r'\b(CALL|JP|JR|DJNZ)\s+(?:[a-zA-Z]{1,2}\s*,\s*)?([a-zA-Z_][a-zA-Z0-9_]*)', 
        re.IGNORECASE
    )

    defined_labels = set()
    edges = set() # Stores tuples: (source_node, target_node, branch_type)
    current_context = "Global_Start"

    try:
        with open(asm_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                # Strip comments to ensure we do not parse commented-out code
                clean_line = line.split(';')[0].strip()
                if not clean_line:
                    continue
                
                # 1. Track Label Definitions (Nodes)
                label_match = label_def_regex.match(clean_line)
                if label_match:
                    current_context = label_match.group(1)
                    defined_labels.add(current_context)
                
                # 2. Track Branch Destinatons (Edges)
                for branch_match in branch_regex.finditer(clean_line):
                    cmd_type = branch_match.group(1).upper()
                    target_label = branch_match.group(2)
                    
                    # Ignore jumps to register pointers like JP (HL), JP (IX)
                    if target_label.upper() in ['(HL)', '(IX)', '(IY)', '(BC)', '(DE)']:
                        continue
                        
                    edges.add((current_context, target_label, cmd_type))
                    
    except FileNotFoundError:
        print(f"Error: Could not find assembly source file at '{asm_path}'")
        return

    # Filter out jumps to external constants or non-existent labels
    valid_edges = [
        (src, dest, cmd) for src, dest, cmd in edges 
        if dest in defined_labels
    ]

    # Write out the Graphviz file with custom formatting rules
    with open(dot_path, 'w', encoding='utf-8') as f:
        f.write("digraph Z80_Program_Structure {\n")
        f.write("    // Canvas Settings\n")
        f.write("    graph [rankdir=TB, splines=true, nodesep=0.5, ranksep=0.6];\n")
        f.write("    node [shape=box, style=\"filled,rounded\", fillcolor=\"#F4F6F7\", color=\"#2C3E50\", fontname=\"Courier\", fontsize=10];\n")
        f.write("    edge [fontname=\"Arial\", fontsize=8, arrowsize=0.7];\n\n")
        
        f.write("    // Subroutine Nodes\n")
        for label in sorted(defined_labels):
            f.write(f'    "{label}" [label="{label}"];\n')
            
        f.write("\n    // Structural Connections\n")
        for src, dest, cmd in sorted(valid_edges):
            # Format arrows visually based on execution action
            if cmd == "CALL":
                # Solid blue line for functional subroutines
                style = 'color="#1F77B4", weight=2, style="solid"'
            elif cmd in ["JP", "JR"]:
                # Dashed grey line for jumps / local structural redirection
                style = 'color="#7F7F7F", style="dashed"'
            elif cmd == "DJNZ":
                # Dotted line for explicit register loop structures
                style = 'color="#2CA02C", style="dotted", label="Loop (B)"'
                
            f.write(f'    "{src}" -> "{dest}" [{style}];\n')
            
        f.write("}\n")
        print(f"Successfully generated Graphviz mapping file: {dot_path}")

if __name__ == "__main__":
    # Change these strings to your actual local file locations
    INPUT_ASM_FILE = "mitsimon.asm"
    OUTPUT_DOT_FILE = "program_flow.dot"
    
    parse_z80_to_dot(INPUT_ASM_FILE, OUTPUT_DOT_FILE)
