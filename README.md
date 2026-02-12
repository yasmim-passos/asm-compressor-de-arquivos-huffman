# MIPS Huffman Compressor

Uma ferramenta profissional de compressão de arquivos escrita em MIPS Assembly para o simulador MARS.

## Funcionalidades
- **Compressão Huffman**: Comprime eficientemente arquivos de texto usando codificação Huffman.
- **Interface Pseudo-GUI**: Uma interface de texto limpa que imita ferramentas de terminal profissionais.
- **Feedback Visual**: Barras de progresso animadas e logs detalhados de processamento.
- **Estatísticas**: Visualize o tamanho original vs comprimido e a taxa de compressão.
- **Visualizador de Tabela**: Visualize a tabela de códigos Huffman gerada para o arquivo.

## Uso
1.  Abra `main.asm` no Simulador MARS MIPS.
2.  Certifique-se de que a opção "Initialize Program Counter to global 'main' if defined" esteja marcada nas Configurações.
3.  Monte (Assemble) e Execute (Run).
4.  Siga o menu na tela para comprimir ou descomprimir arquivos.

## Limites
- Projetado para arquivos de texto dentro dos limites de memória do simulador.
- Tamanho máximo do arquivo: ~10KB (limite do buffer).
