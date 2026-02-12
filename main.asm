
.data
# Constants
BUFFER_SIZE:    .word 10240     # 10KB buffer
filename_buffer: .space 256
file_content:   .space 10240
output_content: .space 10240
frequency_table: .space 1024 # 256 words * 4 bytes
nodes:          .space 10240 # 512 nodes * 20 bytes = 10240
huffman_codes:  .space 2048  # 256 entries * 8 bytes (len, code)

# Strings
str_newline:    .asciiz "\n"
str_separator:  .asciiz "========================================\n"
str_title:      .asciiz "       MIPS HUFFMAN COMPRESSOR v1.0     \n"
str_menu_opt1:  .asciiz "[1] Compactar arquivo\n"
str_menu_opt2:  .asciiz "[2] Descompactar arquivo\n"
str_menu_opt3:  .asciiz "[3] Ver tabela Huffman (ultimo arquivo)\n"
str_menu_opt4:  .asciiz "[4] Ver estatisticas\n"
str_menu_opt0:  .asciiz "[0] Sair\n"
str_menu_opt5:  .asciiz "[5] Sobre\n"
str_prompt:     .asciiz "Escolha: "
str_invalid:    .asciiz "Opcao invalida! Tente novamente.\n"
str_err_file:   .asciiz "Erro ao abrir arquivo!\n"
str_exit:       .asciiz "Saindo... Ate logo!\n"
str_input_file: .asciiz "Digite o arquivo de entrada: "
str_processing: .asciiz "\nProcessando...\n"
output_filename: .asciiz "out.huff"
str_done:       .asciiz "\nConcluido!\n"
str_pause:      .asciiz "\nPressione Enter para continuar..."
str_about_text: .asciiz "Huffman Compressor v1.0\nDesenvolvido em MIPS Assembly.\nAlgoritmo de compressao sem perdas.\n"

.text
.globl main

# --------------------------------------------------------------------------------------------------
# MAIN MENU LOOP
# --------------------------------------------------------------------------------------------------
main:
    # Clear screen (print newlines)
    li $v0, 4
    la $a0, str_newline
    syscall
    syscall
    syscall
    
    # Print Header
    li $v0, 4
    la $a0, str_separator
    syscall
    
    li $v0, 4
    la $a0, str_title
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    # Print Options
    li $v0, 4
    la $a0, str_menu_opt1
    syscall
    
    li $v0, 4
    la $a0, str_menu_opt2
    syscall
    
    li $v0, 4
    la $a0, str_menu_opt3
    syscall
    
    li $v0, 4
    la $a0, str_menu_opt4
    syscall

    li $v0, 4
    la $a0, str_menu_opt5
    syscall
    
    li $v0, 4
    la $a0, str_menu_opt0
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    # Prompt for Choice
    li $v0, 4
    la $a0, str_prompt
    syscall
    
    # Read Integer Choice
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Branching
    beq $t0, 1, opt_compress
    beq $t0, 2, opt_decompress
    beq $t0, 3, opt_view_table
    beq $t0, 4, opt_stats
    beq $t0, 5, opt_about
    beq $t0, 0, opt_exit
    
    # Invalid Option
    li $v0, 4
    la $a0, str_invalid
    syscall
    j wait_enter


# --------------------------------------------------------------------------------------------------
# OPTION HANDLERS
# --------------------------------------------------------------------------------------------------
opt_compress:
    # Clear screen
    li $v0, 4
    la $a0, str_newline
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    # Get Input Filename
    jal prompt_filename
    
    # Read File
    jal read_file
    move $s7, $v0 # Save file size in s7
    
    # Check if read was successful (v0 > 0)
    blez $v0, file_error
    
    # Fake processing 
    li $v0, 4
    la $a0, str_processing
    syscall
    
    jal show_progress_bar

    # COMPRESSION LOGIC
    
    # 1. Frequency Analysis
    move $a0, $s7 # Pass file size
    jal count_frequencies
    
    # 2. Build Huffman Tree
    jal build_huffman_tree
    
    # 3. Generate Codes
    jal generate_codes
    
    # 4. Compress Data
    jal compress_data
    move $t9, $v0 # Save compressed size for write
    move $s6, $v0 # Save for stats
    
    # Write File
    jal write_file 

    li $v0, 4
    la $a0, str_done
    syscall
    
    j wait_enter

file_error:
    li $v0, 4
    la $a0, str_err_file
    syscall
    j wait_enter

opt_decompress:
    # Clear screen
    li $v0, 4
    la $a0, str_newline
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    jal prompt_filename
    
    jal read_file
    move $s7, $v0 # File size
    
    blez $v0, file_error
    
    li $v0, 4
    la $a0, str_processing
    syscall
    
    jal show_progress_bar
    
    # Decompress
    move $a0, $s7
    jal decompress_data
    
    move $t9, $v0 # Uncompressed size
    
    # Write Output (fixed name 'out.txt')
    # Use output_filename buffer but change content?
    # Just use fixed name for now or overwrite output_filename string logic if needed.
    # For simplicity, let's just write to 'out.txt' if we can change the string.
    # Or just use 'out.huff' but that's confusing.
    # Let's update output_filename to "out.txt" manually in memory?
    
    la $t0, output_filename
    li $t1, 'o'
    sb $t1, 0($t0)
    li $t1, 'u'
    sb $t1, 1($t0)
    li $t1, 't'
    sb $t1, 2($t0)
    li $t1, '.'
    sb $t1, 3($t0)
    li $t1, 't'
    sb $t1, 4($t0)
    li $t1, 'x'
    sb $t1, 5($t0)
    li $t1, 't'
    sb $t1, 6($t0)
    sb $zero, 7($t0)
    
    jal write_file
    
    li $v0, 4
    la $a0, str_done
    syscall
    
    j wait_enter

opt_view_table:
    li $v0, 4
    la $a0, str_processing
    syscall
    j wait_enter

opt_stats:
    li $v0, 4
    la $a0, str_processing
    syscall
    j wait_enter

opt_about:
    # About Screen
    li $v0, 4
    la $a0, str_newline
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    li $v0, 4
    la $a0, str_about_text
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    j wait_enter

opt_exit:
    li $v0, 4
    la $a0, str_exit
    syscall
    
    li $v0, 10
    syscall

# --------------------------------------------------------------------------------------------------
# HELPER FUNCTIONS
# --------------------------------------------------------------------------------------------------

# Function: count_frequencies
# Arguments: $a0 = buffer size
# Output: Updates 'frequency_table'
count_frequencies:
    # Clear table first
    la $t0, frequency_table
    li $t1, 0
    li $t2, 256 # 256 entries
clear_loop:
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    bne $t1, $t2, clear_loop
    
    # Count chars
    la $t0, file_content
    move $t1, $a0  # Loop counter (file size)
    la $t2, frequency_table
    
freq_loop:
    blez $t1, freq_end
    
    lbu $t3, 0($t0)  # Load byte (unsigned)
    
    # Calculate offset: table_base + (char * 4)
    sll $t4, $t3, 2
    add $t4, $t4, $t2
    
    # Increment count
    lw $t5, 0($t4)
    addi $t5, $t5, 1
    sw $t5, 0($t4)
    
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    j freq_loop
    
freq_end:
    jr $ra

# Unify filename handling
prompt_filename:
    li $v0, 4
    la $a0, str_input_file
    syscall
    
    li $v0, 8
    la $a0, filename_buffer
    li $a1, 255
    syscall
    
    # Remove newline at end
    la $t0, filename_buffer
remove_nl:
    lb $t1, 0($t0)
    beq $t1, 10, found_nl
    beq $t1, 0, end_nl
    addi $t0, $t0, 1
    j remove_nl
found_nl:
    sb $zero, 0($t0)
end_nl:
    jr $ra

read_file:
    # Open File (Syscall 13)
    li $v0, 13
    la $a0, filename_buffer
    li $a1, 0    # Read mode
    li $a2, 0
    syscall
    
    move $s0, $v0  # Save descriptor
    
    bltz $s0, read_err
    
    # Read Content (Syscall 14)
    li $v0, 14
    move $a0, $s0
    la $a1, file_content
    lw $a2, BUFFER_SIZE
    syscall
    
    move $s1, $v0  # Bytes read
    
    # Close File (Syscall 16)
    li $v0, 16
    move $a0, $s0
    syscall
    
    move $v0, $s1  # Return bytes read
    jr $ra
    
read_err:
    li $v0, -1
    jr $ra

write_file:
    # Open File (Syscall 13) - Write mode
    li $v0, 13
    la $a0, output_filename # Needs to be defined
    li $a1, 1    # Write mode
    li $a2, 0
    syscall
    
    move $s0, $v0
    bltz $s0, write_err
    
    # Write Content (Syscall 15)
    li $v0, 15
    move $a0, $s0
    la $a1, output_content
    move $a2, $t9 # Length (passed in t9 for now)
    syscall
    
    # Close File
    li $v0, 16
    move $a0, $s0
    syscall
    
    jr $ra

write_err:
    jr $ra

# Function: build_huffman_tree
# Output: Constructs the tree in 'nodes' array
build_huffman_tree:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Initialize Leaf Nodes
    jal init_nodes
    
    # 2. Build Priority Queue (simplification: just find min2 iteratively)
    # Ideally should use a heap or sorted list. 
    # For this MIPS project, we will use a naive "find minimums" loop to merge.
    
    # Logic:
    # Loop N-1 times (where N is number of active symbols)
    #   Find two active nodes with lowest frequencies that have no parent yet.
    #   Create new parent node.
    #   Update their parents.
    
    jal construct_tree_loop
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function: init_nodes
# Initializes the first 256 nodes as leaves
init_nodes:
    la $t0, frequency_table
    la $t1, nodes
    li $t2, 0   # loop index (char)
    li $t3, 256
    
init_loop:
    beq $t2, $t3, init_end
    
    # Load frequency
    lw $t4, 0($t0) # freq
    
    # Node Structure:
    # 0: Freq
    # 4: Parent (index, -1 if none)
    # 8: Left (index, -1 if none)
    # 12: Right (index, -1 if none)
    # 16: IsLeaf (1 yes, 0 no)
    
    sw $t4, 0($t1)    # Freq
    li $t5, -1
    sw $t5, 4($t1)    # Parent
    sw $t5, 8($t1)    # Left
    sw $t5, 12($t1)   # Right
    li $t5, 1
    sw $t5, 16($t1)   # IsLeaf
    
    addi $t0, $t0, 4 # next freq
    addi $t1, $t1, 20 # next node
    addi $t2, $t2, 1
    j init_loop
    
init_end:
    jr $ra

# Function: construct_tree_loop
# Repeatedly merges nodes until one tree remains
construct_tree_loop:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # New nodes start at index 256
    li $s0, 256 # next_node_index
    
    # Loop indefinitely, break when < 2 nodes found
merge_loop:
    # Initialize mins
    li $t0, -1   # min1_idx
    li $t1, -1   # min2_idx
    li $t2, 0x7FFFFFFF # min1_freq (MAX_INT)
    li $t3, 0x7FFFFFFF # min2_freq (MAX_INT)
    
    la $t4, nodes # Active node pointer
    li $t5, 0     # Iterator i
    move $t6, $s0 # Limit (next_node_index)
    
find_mins_loop:
    bge $t5, $t6, check_mins
    
    # Check if node is active (Frequency > 0 and Parent == -1)
    # Node struct: freq(0), parent(4), left(8), right(12), isLeaf(16)
    
    lw $t7, 0($t4) # freq
    lw $t8, 4($t4) # parent
    
    blez $t7, next_node # Ignore 0 freq
    li $t9, -1
    bne $t8, $t9, next_node # Ignore if already has parent
    
    # Check against min1
    blt $t7, $t2, update_min1
    # Check against min2
    blt $t7, $t3, update_min2
    j next_node

update_min1:
    # Demote min1 to min2
    move $t3, $t2
    move $t1, $t0
    # Set new min1
    move $t2, $t7
    move $t0, $t5
    j next_node
    
update_min2:
    # Set new min2
    move $t3, $t7
    move $t1, $t5
    j next_node

next_node:
    addi $t4, $t4, 20 # Next node
    addi $t5, $t5, 1
    j find_mins_loop

check_mins:
    # If min2_idx is -1, means we found 0 or 1 node. Done.
    li $t9, -1
    beq $t1, $t9, tree_done
    
    # Merge min1 ($t0) and min2 ($t1)
    # Create new node at $s0
    
    # Calculate address of new node: nodes + s0 * 20
    la $t4, nodes
    mul $t5, $s0, 20
    add $t4, $t4, $t5
    
    # New Freq = min1_freq + min2_freq
    add $t6, $t2, $t3
    sw $t6, 0($t4) # Store freq
    
    li $t7, -1
    sw $t7, 4($t4) # Parent (-1)
    
    sw $t0, 8($t4) # Left (min1)
    sw $t1, 12($t4) # Right (min2)
    
    sw $zero, 16($t4) # IsLeaf (0)
    
    
    # Update Parents of min1 and min2
    # Address of min1: nodes + min1 * 20
    la $t8, nodes
    mul $t9, $t0, 20
    add $t8, $t8, $t9
    sw $s0, 4($t8) # parent = s0
    
    # Address of min2
    la $t8, nodes
    mul $t9, $t1, 20
    add $t8, $t8, $t9
    sw $s0, 4($t8) # parent = s0
    
    addi $s0, $s0, 1 # next_node_index++
    j merge_loop

tree_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function: generate_codes
# Builds the 'huffman_codes' table from the tree
generate_codes:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, nodes
    la $t1, huffman_codes
    li $t2, 0 # char index (0-255)
    
gen_loop:
    beq $t2, 256, gen_end
    
    # Check freq > 0
    mul $t3, $t2, 20
    add $t3, $t3, $t0 # Address of node[i]
    lw $t4, 0($t3) # freq
    
    blez $t4, next_char
    
    # Trace up to root
    move $t5, $t2 # Current node index
    li $t6, 0     # Code bits
    li $t7, 0     # Length
    
    # Need to store path, but since we traverse up, we get bits in reverse order.
    # We can store them in a temporary register or stack and then reverse.
    # OR: Just accumulate and reverse at the end? 
    # Actually, simpler to just accumulate in a register if Length <= 32. 
    # Yes, length <= 32 is guaranteed for < 4 billion freq.
    
trace_up:
    mul $t8, $t5, 20
    add $t8, $t8, $t0 # Addr of current node
    lw $t9, 4($t8)    # Parent index
    
    li $s1, -1
    beq $t9, $s1, trace_done
    
    # Find if we are left or right child
    mul $s2, $t9, 20
    add $s2, $s2, $t0 # Addr of parent
    
    lw $s3, 8($s2) # Left child index
    
    # Shift current code to make space? No, traversing up means we find LSBs first?
    # Actually: Root is MSB. Leaf is LSB?
    # Example: Root -> Left(0) -> Left(0) = 00.
    # If we go Leaf -> Parent -> Parent, we see Left, then Left.
    # So the first step (Leaf->Parent) determines the LAST bit of the code.
    
    # So: code = bit | (code << 1) ??
    # No. If we have bits 0, 1, 0 (010), traversing up gives 0 (last), 1 (middle), 0 (first).
    # So we should add bits at the current position $t7.
    
    beq $t5, $s3, is_left
    # Is Right (1)
    li $s4, 1
    sllv $s4, $s4, $t7
    or $t6, $t6, $s4
    j step_up
    
is_left:
    # Is Left (0) - Nothing to OR, just increment length
    
step_up:
    addi $t7, $t7, 1
    move $t5, $t9 # current = parent
    j trace_up
    
trace_done:
    # Store in table
    # Table entry size = 8 bytes (Length, Code)
    # Address = huffman_codes + char * 8
    mul $s5, $t2, 8
    add $s5, $s5, $t1
    
    sw $t7, 0($s5) # Length
    sw $t6, 4($s5) # Code (bits are already in correct order because we shifted 1 << length)
                  # Wait.
                  # If trace gives b0, b1, b2... where b0 is from leaf->parent (last bit).
                  # We did: code |= bit << length.
                  # Step 0: bit=b0, len=0. code |= b0 << 0. (b0 at pos 0)
                  # Step 1: bit=b1, len=1. code |= b1 << 1. (b1 at pos 1)
                  # Result: ...b1 b0. 
                  # If we print MSB first, we want the LAST bit (Root->Child) to be printed first.
                  # Root->...->Leaf.
                  # b2 b1 b0.
                  # My code constructed: b2 is at max pos. b0 is at pos 0.
                  # So b2 * 2^2 + b1 * 2^1 + b0 * 2^0.
                  # This integer value represents the bits correctly if we print MSB of the integer?
                  # No, usually we want to output bits into stream.
                  # If code is "010", we want to write 0, then 1, then 0.
                  # My construction puts bit 0 (leaf side) at LSB.
                  # bit 2 (root side) at MSB (relative to length).
                  # So to write, we should write from (Length-1) down to 0.
    
    # Storing is fine. Writing logic will handle the bit order.
    
    j next_char

next_char:
    addi $t2, $t2, 1
    j gen_loop
    
gen_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Function: compress_data
# Encodes input using lookup table
# Output: Returns size of compressed data (in bytes) in $v0
compress_data:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Write Header (Frequency Table) to Output
    # Size: 1024 bytes
    la $t0, frequency_table
    la $t1, output_content
    li $t2, 0   # counter
    li $t3, 256 # words
    
copy_header_loop:
    beq $t2, $t3, copy_header_end
    
    lw $t4, 0($t0)
    sw $t4, 0($t1)
    
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j copy_header_loop
    
copy_header_end:
    # $t1 now points to where compressed streams start
    # Keep track of output byte pointer in $s0 (originally $t1)
    move $s0, $t1 
    
    # Bit packing variables
    li $s1, 0   # Current byte buffer (accumulator)
    li $s2, 0   # Current bit count (0-7)
    
    # Input loop
    la $s3, file_content
    move $s4, $s7 # File size (global var from read)
    
encode_loop:
    blez $s4, encode_done
    
    lbu $t5, 0($s3) # Load char
    
    # Lookup Code
    la $t6, huffman_codes
    mul $t7, $t5, 8
    add $t6, $t6, $t7
    
    lw $t8, 0($t6) # Length
    lw $t9, 4($t6) # Code
    
    # Pack bits
    # We need to output bits from MSB (relative to length) down to LSB (0).
    # Since we constructed code: bit 0 (leaf) is LSB. 
    # Example: Code 010 (Left, Right, Left). My stack traces L->R->L.
    # L(0) -> R(1) -> L(0).
    # Step 1 (L): code |= 0 << 0. code=...0
    # Step 2 (R): code |= 1 << 1. code=...10
    # Step 3 (L): code |= 0 << 2. code=...010 (value 2)
    # Length = 3. 
    # To output "010", we access bit 0, then 1, then 2? 
    # No, usually tree traversal for code "010" means Left, Right, Left from Root.
    # Root->Child(0) -> Child(1) -> Child(0).
    # My trace was Leaf->Parent...
    # Leaf->P is the LAST bit of the path.
    # So if Leaf->P is 0, that's the LSB of my integer, but it's the LAST bit of the code sequence.
    # So if I want to output the code, I should output bits from (Length-1) down to 0.
    
    addi $t8, $t8, -1 # index = len - 1
pack_bits_loop:
    bltz $t8, next_char_encode
    
    # Check bit at position $t8
    li $k0, 1
    sllv $k0, $k0, $t8
    and $k0, $k0, $t9 # Result is non-zero if bit is 1
    
    # If bit is 1, set bit in accumulator at position (7 - s2)
    beqz $k0, bit_is_zero
    
    # Bit is 1
    li $k1, 1
    li $k0, 7
    sub $k0, $k0, $s2 # Shift amount = 7 - count
    sllv $k1, $k1, $k0
    or $s1, $s1, $k1
    
bit_is_zero:
    addi $s2, $s2, 1
    
    # Check if buffer full
    li $k0, 8
    beq $s2, $k0, flush_byte
    
    addi $t8, $t8, -1
    j pack_bits_loop

flush_byte:
    sb $s1, 0($s0) # Write byte
    addi $s0, $s0, 1
    li $s1, 0 # Reset buffer
    li $s2, 0 # Reset count
    
    addi $t8, $t8, -1
    j pack_bits_loop

next_char_encode:
    addi $s3, $s3, 1
    addi $s4, $s4, -1
    j encode_loop

encode_done:
    # Flush remaining bits if any
    beqz $s2, finish_compress
    sb $s1, 0($s0)
    addi $s0, $s0, 1
    
finish_compress:
    # Calculate Total Size
    la $t1, output_content
    sub $v0, $s0, $t1 # v0 = current_ptr - start_ptr
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function: decompress_data
# Arguments: $a0 = compressed file size
# Output: Decodes to output_content, Returns size in $v0
decompress_data:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $s7, $a0 # Compressed file size
    
    # 1. Recover Frequency Table from Header
    # Size 1024 bytes.
    la $t0, file_content
    la $t1, frequency_table
    li $t2, 0
    li $t3, 256
    
    # Also calculate total_chars to know when to stop
    li $s6, 0 # Total chars
    
recover_header_loop:
    beq $t2, $t3, recover_header_end
    
    lw $t4, 0($t0)
    sw $t4, 0($t1)
    
    add $s6, $s6, $t4 # Add to total chars
    
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j recover_header_loop
    
recover_header_end:
    # 2. Rebuild Tree
    # Calling build_huffman_tree uses 'frequency_table' which we just restored.
    # It constructs 'nodes' and leaves the root at the end.
    
    # Save key registers before call
    # s6 has total chars
    # s7 has file size
    
    sw $s6, -4($sp)
    sw $s7, -8($sp)
    addi $sp, $sp, -8
    
    jal build_huffman_tree
    
    addi $sp, $sp, 8
    lw $s7, -8($sp)
    lw $s6, -4($sp)
    
    # 3. Find Root Node
    # build_huffman_tree leaves next_node_index in $s0? 
    # Logic in build: 'li $s0, 256' ... 'addi $s0, $s0, 1'.
    # So valid root is at $s0 - 1.
    # Root is the node with parent == -1.
    
    la $t0, nodes
    li $t1, 256 # Start check
    li $s5, 0 # Root index
    
find_root_loop:
    # Pick a char with freq > 0.
    li $t2, 0
find_leaf_loop:
    beq $t2, 256, decode_init # No chars? Empty file.
    
    mul $t3, $t2, 20
    add $t3, $t3, $t0
    lw $t4, 0($t3) # freq
    bgtz $t4, found_leaf
    addi $t2, $t2, 1
    j find_leaf_loop
    
found_leaf:
    # Trace up to root
    move $t5, $t2 # current
trace_root_loop:
    mul $t3, $t5, 20
    add $t3, $t3, $t0
    lw $t6, 4($t3) # parent
    
    li $t7, -1
    beq $t6, $t7, root_found
    move $t5, $t6
    j trace_root_loop
    
root_found:
    move $s5, $t5 # Root Index
    
decode_init:
    # 4. Decode Stream
    # Data starts at file_content + 1024
    la $s0, file_content
    addi $s0, $s0, 1024
    
    # Data size = File Size ($s7) - 1024
    sub $s1, $s7, 1024
    
    la $s2, output_content
    move $s3, $s5 # Current Node = Root
    li $s4, 0 # Symbol count extracted
    
    # Bit reading
decode_loop:
    blez $s1, decode_done # End of bytes (should stop by count first)
    bge $s4, $s6, decode_done # All chars decoded
    
    lbu $t1, 0($s0) # Load byte
    li $t2, 7       # Bit index
    
process_bits_loop:
    bltz $t2, next_byte_decode
    bge $s4, $s6, decode_done
    
    # Extract bit
    li $t3, 1
    sllv $t3, $t3, $t2
    and $t3, $t3, $t1
    
    # Traverse Tree
    mul $t4, $s3, 20
    add $t4, $t4, $t0 # pointer to current node
    
    beqz $t3, go_left
    # Go Right
    lw $s3, 12($t4)
    j check_leaf
    
go_left:
    lw $s3, 8($t4)
    
check_leaf:
    # Check if leaf
    mul $t4, $s3, 20
    add $t4, $t4, $t0
    lw $t5, 16($t4) # IsLeaf
    
    beqz $t5, next_bit
    
    # Found Char!
    # Which char? It's the index $s3 (if < 256).
    sb $s3, 0($s2) # Write char
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    
    move $s3, $s5 # Reset to Root
    
next_bit:
    addi $t2, $t2, -1
    j process_bits_loop

next_byte_decode:
    addi $s0, $s0, 1
    addi $s1, $s1, -1
    j decode_loop
    
decode_done:
    # Return unpacked size ($s4)
    move $v0, $s4
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Function: show_progress_bar
    
    # Loop 20 times
    li $t0, 0
    li $t1, 20
progress_loop:
    bge $t0, $t1, progress_end
    
    # Print '#'
    li $v0, 11
    li $a0, '#'
    syscall
    
    # Sleep 100ms
    li $v0, 32
    li $a0, 100
    syscall
    
    addi $t0, $t0, 1
    j progress_loop
    
progress_end:
    # Print closing bracket
    li $v0, 11
    li $a0, ']'
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

wait_enter:
    li $v0, 4
    la $a0, str_pause
    syscall
    
    # Read string (pause)
    li $v0, 12   # Read char
    syscall
    
    j main
