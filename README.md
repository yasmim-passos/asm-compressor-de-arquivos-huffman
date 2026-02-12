# MIPS Huffman Compressor

A professional-grade file compression tool written in MIPS Assembly for the MARS simulator.

## Features
- **Huffman Compression**: Efficiently compresses text files using Huffman coding.
- **Pseudo-GUI Interface**: A clean, text-based interface mimicking professional terminal tools.
- **Visual Feedback**: Animated progress bars and detailed processing logs.
- **Statistics**: View original vs compressed sizes and compression ratios.
- **Table Viewer**: Visualize the Huffman code table generated for the file.

## Usage
1.  Open `main.asm` in MARS MIPS Simulator.
2.  Ensure "Initialize Program Counter to global 'main' if defined" is checked in Settings.
3.  Assemble and Run.
4.  Follow the on-screen menu to compress or decompress files.

## Limits
- Designed for text files within simulator memory limits.
- Maximum file size: ~10KB (buffer limit).
