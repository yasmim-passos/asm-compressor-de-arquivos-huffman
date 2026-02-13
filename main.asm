
.data
# Constantes
BUFFER_SIZE:    .word 10240     # Buffer de 10KB
filename_buffer: .space 256
file_content:   .space 10240
output_content: .space 10240
frequency_table: .space 1024 # 256 palavras * 4 bytes
nodes:          .space 10240 # 512 nos * 20 bytes = 10240
huffman_codes:  .space 2048  # 256 entradas * 8 bytes (len, code)

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
str_input_file: .asciiz "Digite o caminho do arquivo de entrada: "
str_processing: .asciiz "\nProcessando...\n"
output_filename_huff: .asciiz "out.huff"
output_filename_txt:  .asciiz "out.txt"
str_err_write:      .asciiz "Erro ao escrever arquivo!\n"
str_done:       .asciiz "\nConcluido!\n"
str_pause:      .asciiz "\nPressione Enter para continuar..."
str_about_text: .asciiz "Huffman Compressor v1.0\nDesenvolvido em MIPS Assembly.\nAlgoritmo de compressao sem perdas.\n"
str_table_header: .asciiz "Char | Freq | Codigo\n--------------------\n"
str_tab:        .asciiz "\t| "
str_stats_header: .asciiz "     ESTATISTICAS     \n"
str_orig_size:  .asciiz "Tamanho Original: "
str_comp_size:  .asciiz "Tamanho Comprimido: "
str_ratio:      .asciiz "Taxa de Compressao: "
str_bytes:      .asciiz " bytes\n"

# Vars
stat_orig_size: .word 0
stat_comp_size: .word 0

output_path_buffer: .space 256
str_input_folder:   .asciiz "\n\nDigite o caminho da pasta de saida (Enter para local atual): "
str_slash:          .asciiz "\\"

.text
.globl main

# LOOP DO MENU PRINCIPAL
main:
    # Limpar tela (imprimir novas linhas)
    li $v0, 4
    la $a0, str_newline
    syscall
    syscall
    syscall
    
    # Imprimir Cabecalho
    li $v0, 4
    la $a0, str_separator
    syscall
    
    li $v0, 4
    la $a0, str_title
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    # Imprimir Opcoes
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
    
    # Solicitar Escolha
    li $v0, 4
    la $a0, str_prompt
    syscall
    
    # Ler Escolha Inteira
    li $v0, 5
    syscall
    move $t0, $v0
    
    # Desvio (Branching)
    beq $t0, 1, opt_compress
    beq $t0, 2, opt_decompress
    beq $t0, 3, opt_view_table
    beq $t0, 4, opt_stats
    beq $t0, 5, opt_about
    beq $t0, 0, opt_exit
    
    # Opcao Invalida
    li $v0, 4
    la $a0, str_invalid
    syscall
    j wait_enter


# MANIPULADORES DE OPCAO
opt_compress:
    # Limpar tela
    li $v0, 4
    la $a0, str_newline
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    # Obter Nome do Arquivo de Entrada
    jal prompt_filename
    
    # Ler Arquivo
    jal read_file
    move $s7, $v0 # Salvar tamanho do arquivo em s7
    
    # Verificar se leitura foi bem sucedida (v0 > 0)
    blez $v0, file_error
    
    # Processamento falso 
    li $v0, 4
    la $a0, str_processing
    syscall
    
    jal show_progress_bar

    # LOGICA DE COMPRESSAO
    
    # 1. Analise de Frequencia
    move $a0, $s7 # Passar tamanho do arquivo
    jal count_frequencies
    
    # 2. Construir Arvore de Huffman
    jal build_huffman_tree
    
    # 3. Gerar Codigos
    jal generate_codes
    
    # 4. Comprimir Dados
    jal compress_data
    move $t9, $v0 # Salvar tamanho comprimido para escrita
    move $s6, $v0 # Salvar para estatisticas
    
    sw $s7, stat_orig_size
    sw $s6, stat_comp_size
    
    # Escrever Arquivo
    la $a0, output_filename_huff
    jal prompt_output_folder
    move $a0, $v0 # Passar caminho completo para write_file
    move $t9, $s6 # Restaurar tamanho (pois t9 foi alterado)
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
    # Limpar tela
    li $v0, 4
    la $a0, str_newline
    syscall
    
    li $v0, 4
    la $a0, str_separator
    syscall
    
    jal prompt_filename
    
    jal read_file
    move $s7, $v0 # Tamanho do arquivo
    
    blez $v0, file_error
    
    li $v0, 4
    la $a0, str_processing
    syscall
    
    jal show_progress_bar
    
    # Descomprimir
    move $a0, $s7
    jal decompress_data
    
    move $s6, $v0 # Salvar tamanho descomprimido em s6
    
    # Escrever Saida (nome fixo 'out.txt')
    # Usar buffer output_filename mas mudar conteudo?
    # Apenas usar nome fixo por enquanto ou sobrescrever logica de string output_filename se necessario.
    # Por simplicidade, vamos apenas escrever para 'out.txt' se pudermos mudar a string.
    # Ou apenas usar 'out.huff' mas isso e confuso.
    # Vamos atualizar output_filename para "out.txt" manualmente na memoria?
    
    la $a0, output_filename_txt
    jal prompt_output_folder
    move $a0, $v0
    move $t9, $s6 # Restaurar tamanho
    jal write_file
    
    li $v0, 4
    la $a0, str_done
    syscall
    
    j wait_enter


opt_view_table:
    # Mostrar Cabecalho da Tabela
    li $v0, 4
    la $a0, str_newline
    syscall
    la $a0, str_table_header
    syscall
    
    # Iterar sobre huffman_codes e imprimir
    la $t0, huffman_codes
    li $t1, 0 # char index
    
table_loop:
    beq $t1, 256, table_end
    
    # Carregar comprimento
    mul $t2, $t1, 8
    add $t2, $t2, $t0
    lw $t3, 0($t2) # length
    
    # Se comprimento > 0, imprimir
    blez $t3, next_table_char
    
    # Imprimir Char (se for imprimivel) OU Hex
    # Por simplicidade, imprimir Int do Char
    
    # Imprimir Char Formatado
    li $v0, 11
    li $a0, '|'
    syscall
    
    li $v0, 11
    li $a0, ' '
    syscall
    
    # Se for quebra de linha (10) ou espaco?
    # Vamos imprimir o valor inteiro para clareza em todos os casos
    li $v0, 1
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, str_tab
    syscall
    
    # Imprimir Frequencia
    la $t4, frequency_table
    mul $t5, $t1, 4
    add $t5, $t5, $t4
    lw $a0, 0($t5)
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, str_tab
    syscall
    
    # Imprimir Codigo Binario
    # O codigo esta em 4($t2)
    lw $t6, 4($t2) # Codigo
    move $a0, $t6
    move $a1, $t3 # Comprimento
    jal print_binary_code
    
    li $v0, 4
    la $a0, str_newline
    syscall
    
next_table_char:
    addi $t1, $t1, 1
    j table_loop
    
table_end:
    j wait_enter

opt_stats:
    li $v0, 4
    la $a0, str_newline
    syscall
    la $a0, str_separator
    syscall
    la $a0, str_stats_header
    syscall
    la $a0, str_separator
    syscall
    
    # Tamanho Original
    li $v0, 4
    la $a0, str_orig_size
    syscall
    
    li $v0, 1
    lw $a0, stat_orig_size
    syscall
    
    li $v0, 4
    la $a0, str_bytes
    syscall
    
    # Tamanho Comprimido
    li $v0, 4
    la $a0, str_comp_size
    syscall
    
    li $v0, 1
    lw $a0, stat_comp_size
    syscall
    
    li $v0, 4
    la $a0, str_bytes
    syscall
    
    # Taxa de Compressao
    # Formula: 100 - (compressed * 100 / original)
    lw $t0, stat_orig_size
    lw $t1, stat_comp_size
    
    blez $t0, skip_ratio # Evitar divisao por zero
    
    mul $t2, $t1, 100
    div $t2, $t0
    mflo $t3 # % do original
    
    li $t4, 100
    sub $t5, $t4, $t3 # % economia
    
    li $v0, 4
    la $a0, str_ratio
    syscall
    
    li $v0, 1
    move $a0, $t5
    syscall
    
    li $v0, 11
    li $a0, '%'
    syscall
    
    li $v0, 4
    la $a0, str_newline
    syscall
    
skip_ratio:
    la $a0, str_separator
    syscall
    j wait_enter

# Helper to print binary code
# $a0 = code, $a1 = length
print_binary_code:
    move $t8, $a0
    move $t9, $a1
    
    # Start loop from len-1 down to 0
    addi $t9, $t9, -1
    
print_bin_loop:
    bltz $t9, print_bin_end
    
    # Check bit
    li $t7, 1
    sllv $t7, $t7, $t9
    and $t7, $t7, $t8
    
    beqz $t7, print_zero
    
    li $v0, 11
    li $a0, '1'
    syscall
    j next_bit_print
    
print_zero:
    li $v0, 11
    li $a0, '0'
    syscall
    
next_bit_print:
    addi $t9, $t9, -1
    j print_bin_loop
    
print_bin_end:
    jr $ra

opt_about:
    # Tela Sobre
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

# FUNCOES AUXILIARES

# Funcao: count_frequencies
# Argumentos: $a0 = tamanho do buffer
# Saida: Atualiza 'frequency_table'
count_frequencies:
    # Limpar tabela primeiro
    la $t0, frequency_table
    li $t1, 0
    li $t2, 256 # 256 entradas
clear_loop:
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    bne $t1, $t2, clear_loop
    
    # Contar caracteres
    la $t0, file_content
    move $t1, $a0  # Contador do loop (tamanho do arquivo)
    la $t2, frequency_table
    
freq_loop:
    blez $t1, freq_end
    
    lbu $t3, 0($t0)  # Carregar byte (unsigned)
    
    # Calcular deslocamento (offset): table_base + (char * 4)
    sll $t4, $t3, 2
    add $t4, $t4, $t2
    
    # Incrementar contagem
    lw $t5, 0($t4)
    addi $t5, $t5, 1
    sw $t5, 0($t4)
    
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    j freq_loop
    
freq_end:
    jr $ra

# Unificar manipulacao de nome de arquivo
prompt_filename:
    li $v0, 4
    la $a0, str_input_file
    syscall
    
    li $v0, 8
    la $a0, filename_buffer
    li $a1, 255
    syscall
    
    # Remover nova linha no final
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
    # Abrir Arquivo (Syscall 13)
    li $v0, 13
    la $a0, filename_buffer
    li $a1, 0    # Read mode
    li $a2, 0
    syscall
    
    move $s0, $v0  # Salvar descritor
    
    bltz $s0, read_err
    
    # Ler Conteudo (Syscall 14)
    li $v0, 14
    move $a0, $s0
    la $a1, file_content
    lw $a2, BUFFER_SIZE
    syscall
    
    move $s1, $v0  # Bytes lidos
    
    # Fechar Arquivo (Syscall 16)
    li $v0, 16
    move $a0, $s0
    syscall
    
    move $v0, $s1  # Retornar bytes lidos
    jr $ra
    
read_err:
    li $v0, -1
    jr $ra

    jr $ra

# Funcao: prompt_output_folder
# Argumento: $a0 = nome do arquivo padrao (ex: out.huff)
# Saida: Retorna em $v0 o endereco do caminho completo (output_path_buffer)
prompt_output_folder:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $t9, $a0 # Salvar nome do arquivo
    
    # 1. Solicitar Pasta
    li $v0, 4
    la $a0, str_input_folder
    syscall
    
    # 2. Ler String
    li $v0, 8
    la $a0, output_path_buffer
    li $a1, 255
    syscall
    
    # 3. Remover Newline e verificar se vazio
    la $t0, output_path_buffer
    li $t1, 0 # comprimento
    
check_nl_folder:
    lb $t2, 0($t0)
    beq $t2, 10, found_nl_folder # \n
    beq $t2, 0, found_null_folder
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j check_nl_folder
    
found_nl_folder:
    sb $zero, 0($t0) # Substituir \n por \0
    
found_null_folder:
    # Se comprimento == 0 (apenas enter), tentar usar diretorio do arquivo de entrada
    beqz $t1, try_smart_default
    
    # Caso contrario, verificar se termina com barra
    addi $t0, $t0, -1
    lb $t2, 0($t0)
    li $t3, '\\'
    li $t4, '/'
    beq $t2, $t3, append_name
    beq $t2, $t4, append_name
    
    # Adicionar barra se necessario
    addi $t0, $t0, 1
    sb $t3, 0($t0) # Adicionar '\'
    
append_name:
    addi $t0, $t0, 1 # Mover para proxima posicao livre
    move $t5, $t9    # Endereco do nome do arquivo
    
loop_append:
    lb $t6, 0($t5)
    beqz $t6, end_append
    sb $t6, 0($t0)
    addi $t0, $t0, 1
    addi $t5, $t5, 1
    j loop_append
    
end_append:
    sb $zero, 0($t0) # Terminar string
    la $v0, output_path_buffer
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
try_smart_default:
    # Verificar se filename_buffer tem um caminho (slashes)
    la $t0, filename_buffer
    li $t2, 0 # Indice atual
    li $t3, -1 # Posicao da ultima barra
    
find_slash_loop:
    lb $t4, 0($t0)
    beqz $t4, check_smart_found
    
    li $t5, '\\'
    li $t6, '/'
    beq $t4, $t5, mark_slash
    beq $t4, $t6, mark_slash
    j next_slash_char
    
mark_slash:
    move $t3, $t2 # Atualizar pos da ultima barra
    
next_slash_char:
    addi $t0, $t0, 1
    addi $t2, $t2, 1
    j find_slash_loop

check_smart_found:
    li $t5, -1
    beq $t3, $t5, use_simple_default # Nenhuma barra encontrada
    
    # Barra encontrada em indice $t3. Copiar ate $t3 (inclusive) para output_path_buffer
    la $t0, filename_buffer
    la $t1, output_path_buffer
    li $t2, 0 # contador
    addi $t3, $t3, 1 # Tamanho para copiar (indice + 1)
    
copy_smart_path:
    beq $t2, $t3, append_smart_filename
    lb $t4, 0($t0)
    sb $t4, 0($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    j copy_smart_path

append_smart_filename:
    # Anexar nome padrao $t9
    move $t5, $t9
copy_smart_name_loop:
    lb $t4, 0($t5)
    beqz $t4, end_smart_build
    sb $t4, 0($t1)
    addi $t1, $t1, 1
    addi $t5, $t5, 1
    j copy_smart_name_loop
    
end_smart_build:
    sb $zero, 0($t1)
    la $v0, output_path_buffer
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

use_simple_default:
    # Se usuario nao digitou pasta e nao achamos caminho no input, usa so o nome
    move $v0, $t9 
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

write_file:
    move $t0, $a0 # Save filename buffer address
    
    # Abrir Arquivo (Syscall 13) - Write mode
    li $v0, 13
    move $a0, $t0   # Restore filename
    li $a1, 1    # Write mode
    li $a2, 0
    syscall
    
    move $s0, $v0
    bltz $s0, write_err
    
    # Escrever Conteudo (Syscall 15)
    li $v0, 15
    move $a0, $s0
    la $a1, output_content
    move $a2, $t9 # Comprimento (passado em t9 por enquanto)
    syscall
    
    # Fechar Arquivo
    li $v0, 16
    move $a0, $s0
    syscall
    
    jr $ra
    
write_err:
    li $v0, 4
    la $a0, str_err_write
    syscall
    jr $ra


# Funcao: build_huffman_tree
# Saida: Constroi a arvore no array 'nodes'
build_huffman_tree:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Inicializar Nos Folha
    jal init_nodes
    
    # 2. Construir Fila de Prioridade (simplificacao: apenas encontrar min2 iterativamente)
    # Idealmente deveria usar um heap ou lista ordenada. 
    # Para este projeto MIPS, usaremos um loop "encontrar minimos" ingenuo para mesclar.
    
    # Logica:
    # Loop N-1 vezes (onde N e o numero de simbolos ativos)
    # Encontrar dois nos ativos com as menores frequencias que nao tem pai ainda.
    # Criar novo no pai.
    # Atualizar seus pais.
    
    jal construct_tree_loop
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funcao: init_nodes
# Inicializa os primeiros 256 nos como folhas
init_nodes:
    la $t0, frequency_table
    la $t1, nodes
    li $t2, 0   # indice do loop (char)
    li $t3, 256
    
init_loop:
    beq $t2, $t3, init_end
    
    # Carregar frequencia
    lw $t4, 0($t0) # freq
    
    # Estrutura do No:
    # 0: Freq
    # 4: Parent (indice, -1 se nenhum)
    # 8: Left (indice, -1 se nenhum)
    # 12: Right (indice, -1 se nenhum)
    # 16: IsLeaf (1 sim, 0 nao)
    
    sw $t4, 0($t1)    # Freq
    li $t5, -1
    sw $t5, 4($t1)    # Parent
    sw $t5, 8($t1)    # Left
    sw $t5, 12($t1)   # Right
    li $t5, 1
    sw $t5, 16($t1)   # IsLeaf
    
    addi $t0, $t0, 4 # prox freq
    addi $t1, $t1, 20 # prox no
    addi $t2, $t2, 1
    j init_loop
    
init_end:
    jr $ra

# Funcao: construct_tree_loop
# Mescla nos repetidamente ate restar uma arvore
construct_tree_loop:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Novos nos comecam no indice 256
    li $s0, 256 # next_node_index
    
    # Loop indefinidamente, parar quando < 2 nos encontrados
merge_loop:
    # Inicializar minimos
    li $t0, -1   # min1_idx
    li $t1, -1   # min2_idx
    li $t2, 0x7FFFFFFF # min1_freq (MAX_INT)
    li $t3, 0x7FFFFFFF # min2_freq (MAX_INT)
    
    la $t4, nodes # Ponteiro de no ativo
    li $t5, 0     # Iterador i
    move $t6, $s0 # Limite (next_node_index)
    
find_mins_loop:
    bge $t5, $t6, check_mins
    
    # Verificar se no esta ativo (Frequencia > 0 e Parent == -1)
    # Estrutura do no: freq(0), parent(4), left(8), right(12), isLeaf(16)
    
    lw $t7, 0($t4) # freq
    lw $t8, 4($t4) # parent
    
    blez $t7, next_node # Ignorar freq 0
    li $t9, -1
    bne $t8, $t9, next_node # Ignorar se ja tem pai
    
    # Verificar contra min1
    blt $t7, $t2, update_min1
    # Verificar contra min2
    blt $t7, $t3, update_min2
    j next_node

update_min1:
    # Rebaixar min1 para min2
    move $t3, $t2
    move $t1, $t0
    # Definir novo min1
    move $t2, $t7
    move $t0, $t5
    j next_node
    
update_min2:
    # Definir novo min2
    move $t3, $t7
    move $t1, $t5
    j next_node

next_node:
    addi $t4, $t4, 20 # Prox no
    addi $t5, $t5, 1
    j find_mins_loop

check_mins:
    # Se min2_idx e -1, significa que encontramos 0 ou 1 no. Feito.
    li $t9, -1
    beq $t1, $t9, tree_done
    
    # Mesclar min1 ($t0) e min2 ($t1)
    # Criar novo no em $s0
    
    # Calcular endereco do novo no: nodes + s0 * 20
    la $t4, nodes
    mul $t5, $s0, 20
    add $t4, $t4, $t5
    
    # Nova Freq = min1_freq + min2_freq
    add $t6, $t2, $t3
    sw $t6, 0($t4) # Armazenar freq
    
    li $t7, -1
    sw $t7, 4($t4) # Parent (-1)
    
    sw $t0, 8($t4) # Left (min1)
    sw $t1, 12($t4) # Right (min2)
    
    sw $zero, 16($t4) # IsLeaf (0)
    
    
    # Atualizar Pais de min1 e min2
    # Endereco de min1: nodes + min1 * 20
    la $t8, nodes
    mul $t9, $t0, 20
    add $t8, $t8, $t9
    sw $s0, 4($t8) # parent = s0
    
    # Endereco de min2
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

# Funcao: generate_codes
# Constroi a tabela 'huffman_codes' a partir da arvore
generate_codes:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, nodes
    la $t1, huffman_codes
    li $t2, 0 # indice de char (0-255)
    
gen_loop:
    beq $t2, 256, gen_end
    
    # Verificar freq > 0
    mul $t3, $t2, 20
    add $t3, $t3, $t0 # Endereco de node[i]
    lw $t4, 0($t3) # freq
    
    blez $t4, next_char
    
    # Rastrear ate a raiz
    move $t5, $t2 # Indice do no atual
    li $t6, 0     # Bits de codigo
    li $t7, 0     # Comprimento
    
    # Precisa armazenar o caminho, mas como percorremos para cima, obtemos os bits na ordem inversa.
    
trace_up:
    mul $t8, $t5, 20
    add $t8, $t8, $t0 # Endr do no atual
    lw $t9, 4($t8)    # Indice do pai
    
    li $s1, -1
    beq $t9, $s1, trace_done
    
    # Descobrir se somos filho esquerdo ou direito
    mul $s2, $t9, 20
    add $s2, $s2, $t0 # Endr do pai
    
    lw $s3, 8($s2) # Indice do filho esquerdo
    
    # Codigo binario logic...
    
    beq $t5, $s3, is_left
    # E Direito (1)
    li $s4, 1
    sllv $s4, $s4, $t7
    or $t6, $t6, $s4
    j step_up
    
is_left:
    # E Esquerdo (0) - Nada a fazer OR, apenas incrementar comprimento
    
step_up:
    addi $t7, $t7, 1
    move $t5, $t9 # atual = pai
    j trace_up
    
trace_done:
    # Armazenar na tabela
    # Tamanho da entrada da tabela = 8 bytes (Comprimento, Codigo)
    # Endereco = huffman_codes + char * 8
    mul $s5, $t2, 8
    add $s5, $s5, $t1
    
    sw $t7, 0($s5) # Comprimento
    sw $t6, 4($s5) # Codigo
    
    j next_char

next_char:
    addi $t2, $t2, 1
    j gen_loop
    
gen_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Funcao: compress_data
# Codifica entrada usando tabela de consulta
# Saida: Retorna tamanho dos dados comprimidos (em bytes) em $v0
compress_data:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # 1. Escrever Cabecalho (Tabela de Frequencia) para Saida
    # Tamanho: 1024 bytes
    la $t0, frequency_table
    la $t1, output_content
    li $t2, 0   # contador
    li $t3, 256 # palavras
    
copy_header_loop:
    beq $t2, $t3, copy_header_end
    
    lw $t4, 0($t0)
    sw $t4, 0($t1)
    
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j copy_header_loop
    
copy_header_end:
    # $t1 agora aponta para onde o fluxo comprimido comeca
    # Manter rastreio do ponteiro de byte de saida em $s0 (originalmente $t1)
    move $s0, $t1 
    
    # Variaveis de empacotamento de bits
    li $s1, 0   # Buffer de byte atual (acumulador)
    li $s2, 0   # Contagem de bits atual (0-7)
    
    # Loop de entrada
    la $s3, file_content
    move $s4, $s7 # Tamanho do arquivo (var global da leitura)
    
encode_loop:
    blez $s4, encode_done
    
    lbu $t5, 0($s3) # Carregar char
    
    # Consultar Codigo
    la $t6, huffman_codes
    mul $t7, $t5, 8
    add $t6, $t6, $t7
    
    lw $t8, 0($t6) # Comprimento
    lw $t9, 4($t6) # Codigo
    
    # Empacotar bits
    # Precisamos enviar bits do MSB (relativo ao comprimento) para o LSB.
    
    addi $t8, $t8, -1 # indice = len - 1
pack_bits_loop:
    bltz $t8, next_char_encode
    
    # Verificar bit na posicao $t8
    li $k0, 1
    sllv $k0, $k0, $t8
    and $k0, $k0, $t9 # Resultado e nao-zero se bit e 1
    
    # Se bit e 1, definir bit no acumulador na posicao (7 - s2)
    beqz $k0, bit_is_zero
    
    # Bit e 1
    li $k1, 1
    li $k0, 7
    sub $k0, $k0, $s2 # Quantidade de deslocamento = 7 - count
    sllv $k1, $k1, $k0
    or $s1, $s1, $k1
    
bit_is_zero:
    addi $s2, $s2, 1
    
    # Verificar se buffer cheio
    li $k0, 8
    beq $s2, $k0, flush_byte
    
    addi $t8, $t8, -1
    j pack_bits_loop

flush_byte:
    sb $s1, 0($s0) # Escrever byte
    addi $s0, $s0, 1
    li $s1, 0 # Resetar buffer
    li $s2, 0 # Resetar contagem
    
    addi $t8, $t8, -1
    j pack_bits_loop

next_char_encode:
    addi $s3, $s3, 1
    addi $s4, $s4, -1
    j encode_loop

encode_done:
    # Descarregar bits restantes se houver
    beqz $s2, finish_compress
    sb $s1, 0($s0)
    addi $s0, $s0, 1
    
finish_compress:
    # Calcular Tamanho Total
    la $t1, output_content
    sub $v0, $s0, $t1 # v0 = ponteiro_atual - ponteiro_inicio
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funcao: decompress_data
# Argumentos: $a0 = tamanho do arquivo comprimido
# Saida: Decodifica para output_content, Retorna tamanho em $v0
decompress_data:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $s7, $a0 # Tamanho do arquivo comprimido
    
    # 1. Recuperar Tabela de Frequencia do Cabecalho
    # Tamanho 1024 bytes.
    la $t0, file_content
    la $t1, frequency_table
    li $t2, 0
    li $t3, 256
    
    # Tambem calcular total_chars para saber quando parar
    li $s6, 0 # Total chars
    
recover_header_loop:
    beq $t2, $t3, recover_header_end
    
    lw $t4, 0($t0)
    sw $t4, 0($t1)
    
    add $s6, $s6, $t4 # Adicionar ao total chars
    
    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    j recover_header_loop
    
recover_header_end:
    # 2. Reconstruir Arvore
    # Chamar build_huffman_tree usa 'frequency_table' que acabamos de restaurar.
    
    # Salvar registradores chave antes da chamada
    # s6 tem total chars
    # s7 tem tamanho do arquivo
    
    sw $s6, -4($sp)
    sw $s7, -8($sp)
    addi $sp, $sp, -8
    
    jal build_huffman_tree
    
    addi $sp, $sp, 8
    lw $s7, -8($sp)
    lw $s6, -4($sp)
    
    # 3. Encontrar No Raiz
    
    la $t0, nodes
    li $t1, 256 # Inicio checagem
    li $s5, 0 # Indice Raiz
    
find_root_loop:
    # Escolher um char com freq > 0.
    li $t2, 0
find_leaf_loop:
    beq $t2, 256, decode_init # Sem chars? Arquivo vazio.
    
    mul $t3, $t2, 20
    add $t3, $t3, $t0
    lw $t4, 0($t3) # freq
    bgtz $t4, found_leaf
    addi $t2, $t2, 1
    j find_leaf_loop
    
found_leaf:
    # Rastrear ate a raiz
    move $t5, $t2 # atual
trace_root_loop:
    mul $t3, $t5, 20
    add $t3, $t3, $t0
    lw $t6, 4($t3) # pai
    
    li $t7, -1
    beq $t6, $t7, root_found
    move $t5, $t6
    j trace_root_loop
    
root_found:
    move $s5, $t5 # Indice Raiz
    
decode_init:
    # 4. Decodificar Fluxo
    # Dados comecam em file_content + 1024
    la $s0, file_content
    addi $s0, $s0, 1024
    
    # Tamanho dos dados = File Size ($s7) - 1024
    sub $s1, $s7, 1024
    
    la $s2, output_content
    move $s3, $s5 # No Atual = Raiz
    li $s4, 0 # Contagem de simbolos extraidos
    
    # Leitura de bits
decode_loop:
    blez $s1, decode_done # Fim dos bytes
    bge $s4, $s6, decode_done # Todos chars decodificados
    
    lbu $t1, 0($s0) # Carregar byte
    li $t2, 7       # Indice do bit
    
process_bits_loop:
    bltz $t2, next_byte_decode
    bge $s4, $s6, decode_done
    
    # Extrair bit
    li $t3, 1
    sllv $t3, $t3, $t2
    and $t3, $t3, $t1
    
    # Percorrer Arvore
    mul $t4, $s3, 20
    add $t4, $t4, $t0 # ponteiro para no atual
    
    beqz $t3, go_left
    # Ir para Direita
    lw $s3, 12($t4)
    j check_leaf
    
go_left:
    lw $s3, 8($t4)
    
check_leaf:
    # Verificar se folha
    mul $t4, $s3, 20
    add $t4, $t4, $t0
    lw $t5, 16($t4) # IsLeaf
    
    beqz $t5, next_bit
    
    # Char Encontrado!
    sb $s3, 0($s2) # Escrever char
    addi $s2, $s2, 1
    addi $s4, $s4, 1
    
    move $s3, $s5 # Resetar para Raiz
    
next_bit:
    addi $t2, $t2, -1
    j process_bits_loop

next_byte_decode:
    addi $s0, $s0, 1
    addi $s1, $s1, -1
    j decode_loop
    
decode_done:
    # Retornar tamanho desempacotado ($s4)
    move $v0, $s4
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Funcao: show_progress_bar
# Simula uma barra de progresso [####......]
show_progress_bar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Imprimir colchete de abertura
    li $v0, 11
    li $a0, '['
    syscall
    
    # Loop 20 vezes
    li $t0, 0
    li $t1, 20
progress_loop:
    bge $t0, $t1, progress_end
    
    # Imprimir '#'
    li $v0, 11
    li $a0, '#'
    syscall
    
    # Dormir 100ms
    li $v0, 32
    li $a0, 100
    syscall
    
    addi $t0, $t0, 1
    j progress_loop
    
progress_end:
    # Imprimir colchete de fechamento
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
    
    # Ler char (pausa)
    li $v0, 12   
    syscall
    
    j main
