# =============================================================================
#  hexdump.s  —  Hex-to-ASCII display, runnable x86-64 Linux (GNU as, AT&T syntax)
# -----------------------------------------------------------------------------
#  This is a REAL, runnable translation of the textbook (Hamacher) pseudo-assembly
#  from Chapter 3 Problem 3.2 / Example 3.4:
#
#       Move     R2, #LOC          ->  source pointer
#       LoadByte R6, (R2)          ->  movzbl (%rsi), %eax
#       And      R5, R6, #0x0F     ->  isolate low nibble
#       RotateR / shift for high   ->  shr $4 for high nibble
#       LoadByte R7, TABLE(R5)     ->  movzbl hextab(%r_,%r_), index into table
#       StoreByte R7, DISP_DATA    ->  write(1, ...) syscall to stdout
#
#  The textbook writes each character to the memory-mapped display register
#  DISP_DATA. On a real OS we don't touch hardware directly; the equivalent is
#  the Linux "write" system call to file descriptor 1 (stdout). We build the
#  whole output line in a buffer, then write it in one syscall.
#
#  BUILD & RUN:
#     as --64 -o hexdump.o hexdump.s
#     ld -o hexdump hexdump.o
#     ./hexdump
#
#  (Or in one go with gcc:  gcc -nostdlib -static -o hexdump hexdump.s )
#
#  EXPECTED OUTPUT (for the sample DATA bytes below):
#     3A 05 FF 10 00 7E 41 42 39 0D
# =============================================================================

        .section .data

# ---- The 10 source bytes we want to display in hex (the textbook's "LOC") ----
data:   .byte 0x3A, 0x05, 0xFF, 0x10, 0x00, 0x7E, 0x41, 0x42, 0x39, 0x0D
        .equ  DATALEN, 10            # number of bytes in `data`

# ---- Hex-to-ASCII lookup table (the textbook's TABLE / DATABYTE 0x30..0x46) ---
#      index 0..15  ->  ASCII of hex digit '0'..'9','A'..'F'
hextab: .ascii "0123456789ABCDEF"    # 16 bytes: 0x30..0x39, 0x41..0x46

        .section .bss
# ---- Output buffer: 10 bytes * 3 chars ("XX ") = 30 chars, +1 for newline ----
        .lcomm outbuf, 64

        .section .text
        .globl _start

# =============================================================================
#  _start — main program
# =============================================================================
_start:
        lea     data(%rip),   %rsi      # %rsi = source pointer   (R2 = #LOC)
        lea     outbuf(%rip), %rdi      # %rdi = output write ptr
        lea     hextab(%rip), %rbx      # %rbx = base of lookup TABLE
        mov     $DATALEN,     %rcx      # %rcx = byte counter      (R3 = 10)

byteloop:
        movzbl  (%rsi), %eax            # %al  = current byte      (LoadByte R6,(R2))

        # ---- high nibble: top 4 bits, shifted down to a 0..15 value ----
        mov     %eax, %edx
        shr     $4,   %edx              # %edx = high nibble (0..15)  (RotateR #4)
        and     $0x0F,%edx              # safety mask (keep low 4 bits)
        movzbl  (%rbx,%rdx,1), %edx     # TABLE + highnibble -> ASCII (LoadByte R7,TABLE(R5))
        mov     %dl,  (%rdi)            # store char into outbuf    (StoreByte DISP_DATA)
        inc     %rdi

        # ---- low nibble: bottom 4 bits ----
        mov     %eax, %edx
        and     $0x0F,%edx              # %edx = low nibble (0..15)  (And R5,R6,#0x0F)
        movzbl  (%rbx,%rdx,1), %edx     # TABLE + lownibble -> ASCII
        mov     %dl,  (%rdi)
        inc     %rdi

        # ---- separating space (ASCII 0x20) ----
        movb    $0x20, (%rdi)           # (Move R7,#0x20 ; StoreByte DISP_DATA)
        inc     %rdi

        inc     %rsi                    # next source byte          (Add R2,R2,#1)
        dec     %rcx                    # counter--                 (Subtract R3,R3,#1)
        jnz     byteloop                # loop while counter > 0     (Branch_if_[R3]>0)

        # ---- replace the final trailing space with a newline for tidy output ----
        movb    $0x0A, -1(%rdi)         # outbuf[last] = '\n'

        # =====================================================================
        #  write(fd=1 stdout, buf=outbuf, count = (%rdi - outbuf))
        # =====================================================================
        lea     outbuf(%rip), %rsi      # buf
        mov     %rdi, %rdx              # %rdx = current end ptr
        sub     %rsi, %rdx              # %rdx = bytes written = end - start
        mov     $1,   %rdi              # fd = 1 (stdout)
        mov     $1,   %rax              # syscall number 1 = write
        syscall

        # =====================================================================
        #  exit(0)
        # =====================================================================
        xor     %rdi, %rdi             # status = 0
        mov     $60,  %rax             # syscall number 60 = exit
        syscall
