; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 1 OF 8
; Source: MITSI Monitor for Tuscan System 1 (Brendan Owen, 1980)
; Target Assembler: z80asm / z88dk (Strict syntax, labels with colons)
; Hexadecimal Prefix: $
; Fixed Targets: CASLOC = $F8A0, RSST = $F882
; ==============================================================================

;            PSECT   ABS             ; Line 0001
; ------------------------------------------------------------------------------
; MITSI - MONITOR IN TUSCAN SYSTEM 1
; BY BRENDAN OWEN (23/3/80)
; COPYRIGHT 1980, TCL SOFTWARE PRODUCTS LTD.
; ------------------------------------------------------------------------------

ETX:        EQU     $03             ; Line 0011 ; End of Text (^C)
EOT:        EQU     $04             ; Line 0012 ; End of Transmission (^D)
BS:         EQU     $08             ; Line 0013 ; Backspace
TAB:        EQU     $09             ; Line 0014 ; Horizontal Tab
LF:         EQU     $0A             ; Line 0015 ; Line Feed
CR:         EQU     $0D             ; Line 0016 ; Carriage Return
FF:         EQU     $0C             ; Line 0017 ; Form Feed
XOFF:       EQU     $13             ; Line 0018 ; Transmission Off (^S)
ESC:        EQU     $1B             ; Line 0019 ; Escape
CHOME:      EQU     $1C             ; Line 0020 ; Cursor Home
SPAC:       EQU     $20             ; Line 0021 ; Space character
DEL:        EQU     $7F             ; Line 0022 ; Delete character

DECMRK:     EQU     '#'             ; Line 0024 ; Decimal number flag (JS)
PROMPT:     EQU     '*'             ; Line 0025 ; Monitor prompt symbol

JUMP:       EQU     $C3             ; Line 0027 ; Z80 JP instruction opcode
BRK:        EQU     $FF             ; Line 0028 ; RST 38H opcode for breakpoint

BUFSIZ:     EQU     80              ; Line 0030 ; Length of input buffer
NBP:        EQU     8               ; Line 0031 ; Number of breakpoints allowed
DEFLEN:     EQU     127             ; Line 0032 ; Default display func length

MONORG:     EQU     $F800           ; Line 0034 ; Monitor ROM starting address
MONPAG:     EQU     MONORG/256      ; Line 0035 ; Page number of monitor ROM
EDIT:       EQU     $F7FD           ; Line 0036 ; Editor firmware entry address
PASCAL:     EQU     $08000          ; Line 0037 ; Pascal system entry address
TRACE:      EQU     $F000           ; Line 0038 ; Trace tracking routine address
MMOUT:      EQU     $D400           ; Line 0039 ; Memory mapped VDU routine
MMINIT:     EQU     $D700           ; Line 0040 ; VDU Initialization routine
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 2 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; ==============================================================================

; ------------------------------------------------------------------------------
; I/O PORT DESIGNATIONS
; ------------------------------------------------------------------------------
RSDO:       EQU     $00             ; Line 0044 ; RS232 Data Output
TAPEDO:     EQU     $01             ; Line 0045 ; Tape Data Output
VDU:        EQU     $02             ; Line 0046 ; Onboard VDU Port
PRINT:      EQU     $03             ; Line 0047 ; Centronics Printer Port
PRINTST:    EQU     $07             ; Line 0048 ; Centronics Strobe (Bit 0)
RSS:        EQU     $00             ; Line 0049 ; RS232 UART Status
RSDI:       EQU     $01             ; Line 0050 ; RS232 Data Input
TAPES:      EQU     $02             ; Line 0051 ; Tape UART Status
TAPEDI:     EQU     $03             ; Line 0052 ; Tape Data Input
IOSEL:      EQU     $04             ; Line 0053 ; I/O Configuration (Bits 4-7)
KBD:        EQU     $05             ; Line 0064 ; Onboard Keyboard Port
RSHS:       EQU     $06             ; Line 0065 ; RS232 Handshake (Bit 0)
PRINTHS:    EQU     $07             ; Line 0066 ; Centronics Handshake (Bit 0)

; ------------------------------------------------------------------------------
; FIXED WORKING STORAGE AND SYSTEM OVERLAYS
; ------------------------------------------------------------------------------
            ORG     $0003           ; Line 0070 
IOBYTE:     DEFS    1               ; Line 0072 ; Byte mapping current active I/O

            ORG     $0038           ; Line 0074 
RST7:       DEFS    3               ; Line 0076 ; Core Monitor Restart vector field

            ORG     $0040           ; Line 0078 
CHBUFF:     DEFS    1               ; Line 0080 ; Keyboard character buffer
CURPOS:     DEFS    1               ; Line 0081 ; Cursor tracking position for VDU
CHCNT:      DEFS    1               ; Line 0082 ; Character counter for input operations
PRMP:       DEFS    1               ; Line 0083 ; Saved cursor position at prompt
BUFAD:      DEFS    2               ; Line 0084 ; Dynamic pointer to input buffer text
BUFPTR:     DEFS    2               ; Line 0085 ; Tracking pointer to next buffered character
TOPRAM:     DEFS    2               ; Line 0086 ; Evaluated end-of-RAM boundary + 1
PAR1:       DEFS    2               ; Line 0087 ; First workspace parameter
PAR2:       DEFS    2               ; Line 0088 ; Second workspace parameter
NPARS:      DEFS    1               ; Line 0089 ; Quantified parsed arguments count
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 3 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; ==============================================================================

BPTAB:      DEFS    NBP*3           ; Line 0091 ; Breakpoint Storage Table
ISAV:       DEFS    2               ; Line 0092 ; Saved Environment: Register I
AFSAV:      DEFS    2               ; Line 0093 ; Saved Environment: Registers AF
BCSAV:      DEFS    2               ; Line 0094 ; Saved Environment: Registers BC
DESAV:      DEFS    2               ; Line 0095 ; Saved Environment: Registers DE
HLSAV:      DEFS    2               ; Line 0096 ; Saved Environment: Registers HL
IXSAV:      DEFS    2               ; Line 0097 ; Saved Environment: Register IX
IYSAV:      DEFS    2               ; Line 0098 ; Saved Environment: Register IY
SPSAV:      DEFS    2               ; Line 0099 ; Saved Environment: Stack Pointer SP
PCSAV:      DEFS    2               ; Line 0100 ; Saved Environment: Program Counter PC
DISPAD:     DEFS    2               ; Line 0101 ; Memory address currently viewed/dumped
NXTCH:      DEFS    1               ; Line 0102 ; Latched input tracking character byte

PRNTSW:     DEFS    1               ; Line 0103 ; Printer routing switch state
LOCKSW:     DEFS    1               ; Line 0106 ; Alpha-lock keyboard toggle state

SRAM1:      DEFS    1               ; Line 0110 ; Single-step hardware execution cache
SRAM2:      DEFS    1               ; Line 0111 
SRAM3:      DEFS    1               ; Line 0112 
SRAM4:      DEFS    1               ; Line 0113 
SRAM5:      DEFS    1               ; Line 0114 
SRAM6:      DEFS    1               ; Line 0115 
SRAM7:      DEFS    1               ; Line 0116 
INBUFF:     DEFS    1               ; Line 0117 ; Baseline monitor buffer footprint index
            DEFS    BUFSIZ          ; Line 0118 ; Active data text entry area array
WORKE:      EQU     $               ; Line 0119 ; End calculation bound for monitor space

            ORG     $0100           ; Line 0121 
MONSTK:     DEFS    0               ; Line 0122 ; Re-initialized Supervisor Stack base

; ------------------------------------------------------------------------------
; MONITOR COLD BOOT & SYSTEM INITIALIZATION
; ------------------------------------------------------------------------------
            ORG     MONORG          ; Line 0124 ; $F800 EPROM Vector Target
TRUMP:      JP      PON             ; Line 0126 ; Jump immediately to power-on routine

PON:        LD      SP,MONSTK       ; Line 0128 ; Load supervisor tracking stack
            LD      A,JUMP          ; Line 0129 ; Build dynamic redirection jump
            LD      (RST7),A        ; Line 0130 ; Inject JP opcode to vector at $0038
            LD      HL,MONLP        ; Line 0131 ; Target address is supervisor loop
            LD      (RST7+1),HL     ; Line 0132 ; Complete the absolute jump injection
            IN      A,(IOSEL)       ; Line 0133 ; Pull peripheral line settings
            LD      (IOBYTE),A      ; Line 0134 ; Establish initial state of IOBYTE
            AND     $30             ; Line 0135 ; Check bits masking VDU hardware
            CP      $30             ; Line 0136 ; Is memory-mapped terminal flagged?
            CALL    Z,MMINIT        ; Line 0137 ; Yes, initialize video system interface
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 4 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; Verified Targets: RSST = $F882, CASLOC = $F8A0
; ==============================================================================

            LD      B,NBP*3         ; Line 0138 ; Clear breakpoints array allocation
            LD      HL,BPTAB        ; Line 0139 
            LD      A,MONPAG        ; Line 0140 ; Fill array with ROM page identifier
CLRTAB:     LD      (HL),A          ; Line 0141 ; Marking elements inactive
            INC     HL              ; Line 0142 
            DJNZ    CLRTAB          ; Line 0143 
            LD      B,23            ; Line 0144 ; Clear user register cache space
            XOR     A               ; Line 0145 
CLRREG:     LD      (HL),A          ; Line 0146 ; Set matching states to zero
            INC     HL              ; Line 0147 
            DJNZ    CLRREG          ; Line 0148 ; Loop until entire cache footprint is zero
            CPL                     ; Line 0149 ; Bring accumulator to high logic level
            OUT     (PRINTST),A     ; Line 0150 ; Set Centronics printer strobe high
            LD      DE,SGNON        ; Line 0151 ; Load address of welcome message
            CALL    BUFFCR          ; Line 0152 ; Display banner and print line break
            LD      L,$00           ; Line 0153 ; Begin systemic RAM check process
TESTM:      LD      B,(HL)          ; Line 0154 ; Read original memory contents
            SUB     A               ; Line 0155 ; Clear variable state index tracking
TESTM1:     LD      (HL),A          ; Line 0156 ; Write test pattern directly to memory
            CP      (HL)            ; Line 0157 ; Verify bit line response accuracy
            JR      NZ,MERR         ; Line 0158 ; Mismatch found, RAM boundary discovered
            INC     A               ; Line 0159 ; Step test pattern code forward
            JR      NZ,TESTM1       ; Line 0160 ; Verify complete byte cycle responses
            LD      (HL),B          ; Line 0161 ; Restore original non-volatile RAM state
            INC     H               ; Line 0162 ; Increment tracking focus to next memory page
            JR      TESTM           ; Line 0163 ; Repeat complete sweep validation
MERR:       LD      (TOPRAM),HL     ; Line 0164 ; Save calculated upper RAM bound
            LD      (SPSAV),HL      ; Line 0165 ; Assign default user Stack Pointer to top
            RST     $38             ; Line 0166 ; Formally step into Supervisor Loop

; ------------------------------------------------------------------------------
; CONSOLE HARDWARE INTERFACE DRIVERS
; ------------------------------------------------------------------------------
CONST:      CALL    ACONST          ; Line 1176 ; Poll keyboard status
            RET     Z               ; Line 0177 ; Return if no key pressed
            CALL    CONIN           ; Line 0178 ; Retrieve key byte
            CP      XOFF            ; Line 0179 ; Is it a hold command (^S)?
            RET     NZ              ; Line 0180 ; Return key if not hold
            CALL    CONIN           ; Line 0181 ; Loop until next key clears hold
            CP      ETX             ; Line 0182 ; Is it an abort signal (^C)?
            JP      Z,RST7          ; Line 0183 ; Jump directly to monitor reset loop
            XOR     A               ; Line 0184 ; Clear accumulator
            RET                     ; Line 0185 ; Resume program execution

ACONST:     LD      A,(IOBYTE)      ; Line 0187 ; Evaluate active I/O mapping configuration
            AND     $30             ; Line 0188 ; Mask out console device lines
            JR      Z,RSST          ; Line 0189 ; Routing to RS232, else local keyboard (JS)
            PUSH    HL              ; Line 0190 
            PUSH    BC              ; Line 0191 
            LD      HL,CHBUFF       ; Line 0192 ; Keyboard data buffer address pointer
            IN      A,(KBD)         ; Line 0193 ; Read interface line
            LD      B,A             ; Line 0194 ; Cache hardware line state
            XOR     (HL)            ; Line 0195 ; Evaluate line transitions
            CALL    M,KEYP          ; Line 0196 ; Determine action state updates
            XOR     A               ; Line 0197 ; Signal no character active
EXCONS:     POP     BC              ; Line 0198 
            POP     HL              ; Line 0199 
            RET                     ; Line 0200 

KEYP:       LD      A,B             ; Line 0201 ; Restore internal tracking line state
            LD      (HL),B          ; Line 0202 ; Cache current configuration
            OR      A               ; Line 0203 ; Test line logic levels
            RET     P               ; Line 0204 
            POP     HL              ; Line 0205 
KRDY:       OR      $FF             ; Line 0206 ; Set hardware ready indicator
            JR      EXCONS          ; Line 0207 
; ------------------------------------------------------------------------------
; RS232 SERIAL HANDSHAKE & STATUS DRIVERS
; ------------------------------------------------------------------------------
RSST:       IN      A,(RSS)         ; Line 0209 ; Read RS232 interface link status
            AND     $01             ; Line 0210 ; Evaluate Data Available flag state
            RET     Z               ; Line 0211 ; Return empty if buffer clear
            OR      $FF             ; Line 0212 ; Signal serial character present
            RET                     ; Line 0213 
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 5 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; Verified Targets: CASLOC = $F8A0
; ==============================================================================
; ------------------------------------------------------------------------------
; CONIN - GET CHARACTER FROM CONSOLE
; ------------------------------------------------------------------------------
CONIN:      LD      A,(IOBYTE)      ; Line 0220 ; Check active console routing
            AND     $30             ; Line 0221 ; Isolate console configuration bits
            JR      Z,RSIN          ; Line 0222 ; Route to RS232, else local keyboard
            LD      A,(CHBUFF)      ; Line 0223 ; Pull keyboard buffer state
            CP      $81             ; Line 0224 ; Evaluate strobe and character state
            JR      NC,GOTCH        ; Line 0225 ; Branch if character latch active
KWAIT:      CALL    ACONST          ; Line 0226 ; Check key status matrix
            JR      Z,KWAIT         ; Line 0227 ; Wait if no key active
GOTCH:      LD      A,(CHBUFF)      ; Line 0228 ; Retrieve key byte from cache

CASLOC:     AND     $7F             ; Line 0229 ; Strip bit 7 parity marker
            PUSH    BC              ; Line 0230 
            LD      B,A             ; Line 0231 ; Cache pure character value
            LD      A,$80           ; Line 0232 ; Prepare character read reset token
            LD      (CHBUFF),A      ; Line 0233 ; Update local terminal state tracking
            LD      A,(LOCKSW)      ; Line 0234 ; Evaluate keyboard alpha-lock switch
            AND     A               ; Line 0235 ; Is tracking active?
            LD      A,B             ; Line 0236 ; Restore character working value
            POP     BC              ; Line 0237 
            RET     Z               ; Line 0238 ; Return character if alpha-lock off
UCMASK:     CP      'A'+$20         ; Line 0239 ; Check against lower-case bound 'a'
            RET     C               ; Line 0240 ; Return character if unchanged
            CP      'Z'+1+$20       ; Line 0241 ; Check against upper-case boundary 'z'
            RET     NC              ; Line 0242 ; Return character if outside range
            SUB     $20             ; Line 0243 ; Translate character value to uppercase
            RET                     ; Line 0244 

RSIN:       CALL    RSST            ; Line 0246 ; Poll serial interface status
            JR      Z,RSIN          ; Line 0247 ; Wait until serial line is ready
            IN      A,(RSDI)        ; Line 0248 ; Read input character from serial line
            JR      CASLOC          ; Line 0249 ; Jump to tracking parity and shift loops
; ------------------------------------------------------------------------------
; TAPE CASSETTE PERIPHERAL DRIVERS
; ------------------------------------------------------------------------------
TAPE:       CALL    CONST           ; Line 0262 ; Check console line for dynamic abort
            CALL    READER          ; Line 0263 ; Pull active data byte from interface
            LD      B,A             ; Line 0264 ; Cache byte value
            IN      A,(TAPES)       ; Line 0265 ; Query tape controller UART status register
            AND     $0E             ; Line 0266 ; Mask framing, parity, and overrun flags
            LD      A,B             ; Line 0267 ; Restore tape data byte
            RET     Z               ; Line 0268 ; Return with data if no errors present
            LD      A,'?'           ; Line 0269 ; Initialize error notification flag
            LD      (PAR1),A        ; Line 0270 ; Update tracking cache interface state
;            RET                     ; Line 0272 
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 6 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; ==============================================================================

; ------------------------------------------------------------------------------
; CONOUT - OUTPUT CHARACTER TO USERS CONSOLE
; ------------------------------------------------------------------------------
CONOUT:     EXX                     ; Line 0278 ; Swap to alternate registers
            PUSH    AF              ; Line 0279 ; Save output character
            CP      TAB             ; Line 0280 ; Is it a horizontal tab?
            JR      NZ,DISCH        ; Line 0281 ; No, output char directly
TABON:      LD      A,SPAC          ; Line 0282 ; Load space character
            CALL    CHOUT           ; Line 0283 ; Output space
            LD      A,(CHCNT)       ; Line 0284 ; Check current cursor position
            AND     7               ; Line 0285 ; Is it a multiple of 8?
            JR      NZ,TABON        ; Line 0286 ; No, continue expanding tabs
DISCH:      CALL    CHOUT           ; Line 0287 ; Send character to output device
            POP     AF              ; Line 0288 ; Restore character
            EXX                     ; Line 0289 ; Restore original registers
            RET                     ; Line 0290 

CHOUT:      LD      C,A             ; Line 0292 ; Cache character in C
            CALL    CONST           ; Line 0293 ; Check for pause requests (^S)
            LD      A,C             ; Line 0294 ; Restore character
            CALL    ACONOUT         ; Line 0295 ; Write to primary console hardware
            LD      A,(PRNTSW)      ; Line 0296 ; Check external printer routing switch
            OR      A               ; Line 0297 ; Is the printer stream active? (JS)
            LD      A,C             ; Line 0298 ; Restore character
            CALL    NZ,LIST         ; Line 0299 ; If active, mirror stream to printer
            LD      HL,CHCNT        ; Line 0300 ; Pointer to stream column counter
            CP      LF              ; Line 0301 ; Is it a line feed?
            JR      Z,ZERCNT        ; Line 0302 ; Reset column count if so
            CP      BS              ; Line 0303 ; Is it a backspace?
            JR      Z,BACK          ; Line 0304 ; Decrement counter if so
            AND     A               ; Line 0305 ; Is it a null character?
            RET     Z               ; Line 0306 ; Ignore nulls
            CP      EOT             ; Line 0307 ; Is it end-of-transmission?
            RET     Z               ; Line 0308 ; Ignore EOTs
            AND     $EF             ; Line 0309 ; Mask code space bits
            SUB     CR              ; Line 0310 ; Is it a carriage return?
            JR      Z,ZERCNT        ; Line 0311 ; Reset counter
            DEC     A               ; Line 0312 ; Is it an escape character?
            JR      Z,ZERCNT        ; Line 0313 ; Reset counter
            DEC     A               ; Line 0314 ; Is it form feed or home cursor?
            JR      Z,ZERCNT        ; Line 0315 ; Reset counter
            INC     (HL)            ; Line 0316 ; Regular printable character, increment count
            RET                     ; Line 0317 
ZERCNT:     LD      (HL),0          ; Line 0318 ; Clear column counter
            RET                     ; Line 0319 
BACK:       DEC     (HL)            ; Line 0320 ; Step column counter back one step
            RET                     ; Line 0321 

ACONOUT:    PUSH    BC              ; Line 0323 ; Save work registers
            LD      A,(IOBYTE)      ; Line 0324 ; Read global I/O allocation mapping
            AND     $30             ; Line 0325 ; Extract console parameters
            JR      Z,RSSTK         ; Line 0326 ; Route to serial line if zero
            CP      $30             ; Line 0327 ; Is it a memory-mapped display layout?
            JR      Z,MMSTK         ; Line 0328 ; Route to memory-mapped VDU if so
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 7 OF 8
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; ==============================================================================

VDUOUT:     LD      A,C             ; Line 0329 ; (JS)
            AND     $7F             ; Line 0330 ; Bring strobe line low
            OUT     (VDU),A         ; Line 0331 
            OR      $80             ; Line 0332 ; Pull strobe line high
            OUT     (VDU),A         ; Line 0333 
            AND     $7F             ; Line 0334 ; Clear strobe back to low
            OUT     (VDU),A         ; Line 0335 
            CP      FF              ; Line 0336 ; Is it a Form Feed command?
            JR      NZ,NOHOME       ; Line 0337 
HOME:       LD      B,132           ; Line 0338 ; Load 132ms padding delay value
CHAR0:      SUB     A               ; Line 0339 ; Reset accumulator to 0
            LD      (CURPOS),A      ; Line 0340 ; Zero VDU screen cursor position
VDUDEL:     CALL    DBMS            ; Line 0341 ; Process execution timing delay
RESTRI:     POP     BC              ; Line 0342 ; Restore workspace registers
            RET                     ; Line 0343 
NOHOME:     CP      CR              ; Line 0344 ; Is it a Carriage Return?
            LD      B,15            ; Line 0345 ; Load 15ms command execution delay
            JR      Z,CHAR0         ; Line 0346 
            LD      A,C             ; Line 0347 ; Retrieve cached character byte
            AND     A               ; Line 0348 ; Check for non-printing null character
            JR      Z,US80          ; Line 0349 
            CP      EOT             ; Line 0350 ; Is it an End of Transmission character?
            JR      Z,US80          ; Line 0351 
            CP      LF              ; Line 0352 ; Is it a Line Feed character?
            JR      Z,VDUDEL        ; Line 0353 ; Branch to timing padding delay routine
            CP      ESC             ; Line 0354 ; Is it an Escape character?
            JR      Z,VDUDEL        ; Line 0355 ; Branch to loop delay for screen scrolling
            LD      A,(CURPOS)      ; Line 0356 ; Load current screen column index
            INC     A               ; Line 0357 
            CP      64              ; Line 0358 ; Does row reach terminal boundary (64 chars)?
            JR      Z,CHAR0         ; Line 0359 ; Yes, execute automatic CRLF loop reset
            LD      (CURPOS),A      ; Line 0360 ; Update tracking index register cache
US80:       LD      A,(IOBYTE)      ; Line 0361 ; Check CPU clock configuration settings
            AND     $30             ; Line 0362 
            CP      $20             ; Line 0363 ; Is system running at 4MHz speed?
            JR      NZ,RESTRI       ; Line 0364 ; 2MHz profile, skip extra loop padding
            LD      A,8             ; Line 0365 ; Initialize ~40 microseconds loop counter
US40:       DEC     A               ; Line 0366 
            JR      NZ,US40         ; Line 0367 
            JR      RESTRI          ; Line 0368 

; ------------------------------------------------------------------------------
; DBMS - MULTI-SPEED MILLISECOND DELAY GENERATOR LOOP
; ------------------------------------------------------------------------------
DBMS:       PUSH    AF              ; Line 0370 
DIMS:       LD      A,(IOBYTE)      ; Line 0371 
            AND     $30             ; Line 0372 ; Isolate speed metrics bits
            CP      $20             ; Line 0373 ; Is it 4MHz operation?
            LD      A,246           ; Line 0374 ; Load counter state value for 4MHz
            JR      Z,DLOOP         ; Line 0375 
            LD      A,121           ; Line 0376 ; Load counter state value for 2MHz
DLOOP:      DEC     A               ; Line 0377 
            JR      NZ,DLOOP        ; Line 0378 
            DJNZ    DIMS            ; Line 0379 ; Loop through execution blocks B times
            POP     AF              ; Line 0380 
            RET                     ; Line 0381 

RSSTK:      IN      A,(RSHS)        ; Line 0383 ; Read serial handshake line state
            AND     $01             ; Line 0384 
            JR      Z,RSSTK         ; Line 0385 ; Wait if hardware interface states busy
            IN      A,(RSS)         ; Line 0386 ; Pull UART internal buffer flags
            AND     $10             ; Line 0387 ; Check Transmitter Buffer Empty flag
            JR      Z,RSSTK         ; Line 0388 ; Loop if transmit shift path full
            LD      A,C             ; Line 0389 ; Retrieve cached data byte
            OUT     (RSDO),A        ; Line 0390 ; Route byte out to RS232 port interface
            POP     BC              ; Line 0391 
            RET                     ; Line 0392 

MMSTK:      CALL    MMOUT           ; Line 0394 ; Route to custom memory mapped display driver
            POP     BC              ; Line 0395 
            RET                     ; Line 0396 

LIST:       PUSH    BC              ; Line 0403 
            LD      C,A             ; Line 0404 
            LD      A,(IOBYTE)      ; Line 0405 ; Read current configuration vector
            AND     $C0             ; Line 0406 ; Extract destination printer stream codes
            JR      Z,RSSTK         ; Line 0407 ; Route to serial data line channel
            CP      $40             ; Line 0408 ; Is onboard VDU terminal designated?
            JP      Z,VDUOUT        ; Line 0409 ; Jump directly to active hardware output
WTPHS:      IN      A,(PRINTHS)     ; Line 0410 ; Query parallel hardware interface pin status
            AND     $01             ; Line 0411 
            JR      NZ,WTPHS        ; Line 0412 ; Wait if Centronics printer line busy
            LD      A,C             ; Line 0413 ; Load data byte
            OUT     (PRINT),A       ; Line 0414 ; Write character to printer data lines
            XOR     A               ; Line 0415 
            OUT     (PRINTST),A     ; Line 0416 ; Bring print data strobe line low
            CPL                     ; Line 0417 
            OUT     (PRINTST),A     ; Line 0418 ; Return printer strobe to high level
            LD      A,C             ; Line 0419 
            POP     BC              ; Line 0420 
            RET                     ; Line 0421 
; snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE - PART 8 OF 8 (FINAL SECTION)
; Source: MITSI Monitor for Tuscan System 1
; Target Assembler: z80asm / z88dk
; ==============================================================================

; ------------------------------------------------------------------------------
; PUNHL - OUTPUT THE DOUBLE BYTE IN HL TO TAPE
; ------------------------------------------------------------------------------
PUNHL:      LD      A,L             ; Line 0428 ; Send low byte <L> first
            CALL    PUNCH           ; Line 0429 
            LD      A,H             ; Line 0430 ; Prepare high byte <H> next
                                    ; Line 0431 ; Fall straight into PUNCH

; ------------------------------------------------------------------------------
; PUNCH - OUTPUT BYTE TO MODEM (TAPE DATA LINK)
; ------------------------------------------------------------------------------
PUNCH:      PUSH    AF              ; Line 0437 ; Cache target output data byte
PUNCH1:     IN      A,(TAPES)       ; Line 0438 ; Pull tape control status register
            AND     $10             ; Line 0439 ; Is Transmitter Buffer Empty true?
            JR      Z,PUNCH1        ; Line 0440 ; Loop if transmit channel is busy
            POP     AF              ; Line 0441 ; Restore target data byte
            OUT     (TAPEDO),A      ; Line 0442 ; Send byte to serial tape output port
            RET                     ; Line 0443 

; ------------------------------------------------------------------------------
; READER - ROUTINE TO EXTRACT DATA BYTE FROM MODEM LINK
; ------------------------------------------------------------------------------
READER:     IN      A,(TAPES)       ; Line 0450 ; Read tape serial link status flags
            AND     $01             ; Line 0451 ; Is Data Available flag asserted?
            JR      Z,READER        ; Line 0452 ; Loop until link receive latch completes
            IN      A,(TAPEDI)      ; Line 0453 ; Pull waiting byte from hardware port
            RET                     ; Line 0454 

; ------------------------------------------------------------------------------
; GETBUF - INITIALIZE AND HOOK LINE INPUT WORKING BUFFER Footprint
; ------------------------------------------------------------------------------
GETBUF:     LD      DE,INBUFF+1     ; Line 0462 ; Establish structural pointer to text zone
            LD      (BUFPTR),DE     ; Line 0463 ; Reset working scan tracking register pointer
            DEC     DE              ; Line 0464 
            LD      A,BUFSIZ        ; Line 0465 ; Load maximum baseline buffer size
            LD      (DE),A          ; Line 0466 ; Write length byte limit descriptor into array
;add missing
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART A
; Core Function: Console Line Buffer Entry, Delete, and Controls
; ==============================================================================

; ------------------------------------------------------------------------------
; BUFFIN - ROUTINE TO READ A LINE INTO AN INPUT BUFFER
; ------------------------------------------------------------------------------
BUFFIN:     EX      DE,HL           ; Line 0484 ; HL=PTR TO BUFFER
            LD      C,(HL)          ; Line 0485 ; C=MAX BUFFER LENGTH
            DEC     C               ; Line 0486 ; ALLOW FOR <CR>
            LD      A,(CHCNT)       ; Line 0487 ; GET END OF PROMPT POS
            LD      (PRMP),A        ; Line 0488 ; REMEMBER IT FOR DELTAB
            LD      (BUFAD),HL      ; Line 0489 ; PTR TO TEXT AREA
LINLOOP:    LD      B,0             ; Line 0490 ; B=CURRENT LENGTH=0
CHLOOP:     CALL    CONIN           ; Line 0491 ; GET CHARACTER
            CP      LF              ; Line 0492 ; LF?
            JR      Z,GOTBUF        ; Line 0493 ; YES, DONE
            CP      CR              ; Line 0494 ; CR?
            JR      Z,GOTBUF        ; Line 0495 ; YES, DONE
            CP      DEL             ; Line 0496 ; DELETE?
            JR      NZ,NODEL        ; Line 0497 
DELET:      LD      A,B             ; Line 0498 ; GET CURRENT BUFF LENGTH
            OR      A               ; Line 0499 ; =0?
            JR      Z,CHLOOP        ; Line 0500 ; YES, IGNORE
            LD      A,(HL)          ; Line 0501 ; GET CHAR TO DELETE
            DEC     B               ; Line 0502 ; BACKUP CTR & PTR
            DEC     HL              ; Line 0503 
            PUSH    HL              ; Line 0504 
            PUSH    BC              ; Line 0505 
            CALL    DELETE          ; Line 0506 ; DO DELETION
            POP     BC              ; Line 0507 
            POP     HL              ; Line 0508 
            JR      CHLOOP          ; Line 0509 ; GET REPLACEMENT
NODEL:      CP      BS              ; Line 0510 ; BS?
            JR      Z,DELET         ; Line 0511 ; TREAT AS DELETE
            CP      $15             ; Line 0512 ; ^U?
            JR      NZ,NOCAN        ; Line 0513 ; NO
LINDEL:     LD      A,(PRMP)        ; Line 0514 ; FIND PROMPT POSITION
            LD      HL,CHCNT        ; Line 0515 ; PTR TO CURSOR NOW
            CP      (HL)            ; Line 0516 ; SAME?
            LD      HL,(BUFAD)      ; Line 0517 ; RESET BUFFER PTR
            JR      NC,LINLOOP      ; Line 0518 
            CALL    ERA             ; Line 0519 ; NO, DELETE ONE CHAR
            JR      LINDEL          ; Line 0520 
NOCAN:      CP      $10             ; Line 0521 ; ^P?
            JR      NZ,NOTOG        ; Line 0522 
            LD      DE,PRNTSW       ; Line 0523 ; PTR TO SWITCH
TOGSW:      LD      A,(DE)          ; Line 0524 ; GET IT
            CPL                     ; Line 0525 ; TOGGLE IT
            LD      (DE),A          ; Line 0526 
            JR      CHLOOP          ; Line 0527 ; GET NEXT CHAR
NOTOG:      CP      $01             ; Line 0528 ; ^A (ALPHA LOCK)?
            JR      NZ,NOLOCK       ; Line 0529 ; NO
            LD      DE,LOCKSW       ; Line 0530 ; GET SWITCH
            JR      TOGSW           ; Line 0531 ; TOGGLE SWITCH
NOLOCK:     INC     HL              ; Line 0532 ; MUST BE ORDINARY CHAR
            LD      (HL),A          ; Line 0533 ; SAVE IT IN BUFF
            CALL    CONOUT          ; Line 0534 ; ECHO CHAR
            INC     B               ; Line 0535 ; BUMP CTR
            CP      ETX             ; Line 0536 ; ^C?
            LD      A,B             ; Line 0537 ; FIRST CHARACTER?
            JR      NZ,LENTST       ; Line 0538 ; NOT ^C
            CP      1               ; Line 0539 
            JP      Z,RST7          ; Line 0540 ; RESTART IF SO
LENTST:     CP      C               ; Line 0541 ; BUFFER FULL?
            JR      C,CHLOOP        ; Line 0542 ; NO
GOTBUF:     INC     HL              ; Line 0543 ; PTR TO NEXT FREE
            LD      (HL),CR         ; Line 0544 ; MARK END OF BUFFER
            RET                     ; Line 0545 

DELETE:     AND     A               ; Line 0547 ; NULL?
            RET     Z               ; Line 0548 ; IGNORE
            CP      EOT             ; Line 0549 ; EOT?
            RET     Z               ; Line 0550 
            LD      C,A             ; Line 0551 ; SAVE CHAR
            AND     $EF             ; Line 0552 ; MASK OUT BIT 4
            CP      $0B             ; Line 0553 ; ESC?
            RET     Z               ; Line 0554 
            CP      FF              ; Line 0555 
            RET     Z               ; Line 0556 
            LD      A,C             ; Line 0557 ; RESTORE CHAR
            POP     HL              ; Line 0558 ; UNSTACK RETURN ADDR
            POP     BC              ; Line 0559 ; TO GET AT BC
            PUSH    BC              ; Line 0560 ; B = CHARS IN BUFFER
            PUSH    HL              ; Line 0561 ; STACK RESTORED
            LD      HL,(BUFAD)      ; Line 0562 ; GET BUFFER ADDRESS
            LD      A,(PRMP)        ; Line 0563 ; GET END OF PROMPT
            LD      C,A             ; Line 0564 ; C=CURSOR POSITION AFTER DELETE
CALPOS:     LD      A,B             ; Line 0565 ; SEE IF MORE CHARS TO DELETE
            AND     A               ; Line 0566 
            JR      Z,DELCNT        ; Line 0567 ; NO, SEE HOW FAR TO BS
            INC     HL              ; Line 0568 ; BUMP PTR
            LD      A,(HL)          ; Line 0569 ; GET CHAR FROM BUFFER
            DEC     B               ; Line 0570 ; DEC COUNT TO BE READ
            INC     C               ; Line 0571 ; BUMP NEW POSITION
            CP      TAB             ; Line 0572 ; IS THIS A TAB?
            CALL    Z,TABPOS        ; Line 0573 ; YES, MOVE TO NEXT TAB
            JR      CALPOS          ; Line 0574 ; YES
DELCNT:     LD      A,(CHCNT)       ; Line 0575 ; GET OLD CURSOR POSITION
            SUB     C               ; Line 0576 ; SUBTRACT NEW, A = CHARS TO BACKUP
ERACH:      PUSH    AF              ; Line 0577 ; BACK SPACE
            CALL    ERA             ; Line 0578 
            POP     AF              ; Line 0579 
            DEC     A               ; Line 0580 ; UNTIL A=0
            JR      NZ,ERACH        ; Line 0581 
            RET                     ; Line 0582 

TABPOS:     LD      A,C             ; Line 0583 ; GET CURSOR POSITION
            AND     $F8             ; Line 0584 ; STRIP OFF LS 3 BITS
            ADD     A,8             ; Line 0585 ; MOVE TO NEXT TAB
            LD      C,A             ; Line 0586 
            RET                     ; Line 0587 
ERA:        CALL    BACKSP          ; Line 0588 ; BACKSPACE
            CALL    SPACE           ; Line 0589 ; SPACE TO ERASE
BACKSP:     LD      A,BS            ; Line 0590 ; BACKSPACE
            JP      CHOUT           ; Line 0591 

BUFFOUT:    PUSH    AF              ; Line 0600 
BUFF1:      LD      A,(DE)          ; Line 0601 ; GET CHAR
            CALL    CONOUT          ; Line 0602 ; PRINT IT
            INC     DE              ; Line 0603 ; BUMP PTR
            CP      EOT             ; Line 0604 ; END?
            JR      NZ,BUFF1        ; Line 0605 ; NO
            POP     AF              ; Line 0606 
            RET                     ; Line 0607 
BUFFCR:     CALL    BUFFOUT         ; Line 0609 ; PRINT STRING
CRLF:       PUSH    AF              ; Line 0618 
            LD      A,CR            ; Line 0619 
            CALL    CONOUT          ; Line 0620 
            LD      A,LF            ; Line 0621 
            CALL    CONOUT          ; Line 0622 
            POP     AF              ; Line 0623 
            RET                     ; Line 0624 
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART B1 OF 4
; Core Function: Tape System Layout Entry and Data File Export Channels
; ==============================================================================

; ------------------------------------------------------------------------------
; WRITE - FUNCTION TO SAVE A TARGET FILE TO TAPE STAGE LINK
; ------------------------------------------------------------------------------
WRITE:      CALL    PCHECK          ; Line 0632 ; Load parameters 1 and 2
            CP      ','             ; Line 0633 ; Verify comma separator holds
WERR:       JP      NZ,PARER        ; Line 0634 
            LD      A,(NPARS)       ; Line 0635 ; Verify exact argument volume count
            CP      2               ; Line 0636 
            JR      NZ,WERR         ; Line 0637 
            LD      HL,(PAR2)       ; Line 0638 
            EX      DE,HL           ; Line 0639 ; DE = End Address limit bounds
            LD      HL,(BUFPTR)     ; Line 0640 
            LD      B,H             ; Line 0641 
            LD      C,L             ; Line 0642 ; BC = Primary file identifier string
            LD      HL,(PAR1)       ; Line 0643 ; HL = Start Address origin point

FILOUT:     PUSH    DE              ; Line 0662 ; Cache file limit boundary address
            CALL    BLANK           ; Line 0663 ; Dump padding delay leader line tape
            LD      E,64            ; Line 0664 ; Load structural block byte count
            LD      A,CR            ; Line 0665 ; Leader byte layout value token
OUTLDR:     CALL    PUNCH           ; Line 0666 ; Transmit leader tracking sequence
            DEC     E               ; Line 0667 
            JR      NZ,OUTLDR       ; Line 0668 ; Loop until entire frame clears
            XOR     A               ; Line 0669 ; Clear terminal sync marker byte
            CALL    PUNCH           ; Line 0670 
            PUSH    BC              ; Line 0671 ; Preserve file name string reference
GETLEN:     LD      A,(BC)          ; Line 0672 ; Extract description byte segment
            INC     E               ; Line 0673 ; Increment calculated text length counter
            INC     BC              ; Line 0674 
            CP      CR              ; Line 0675 ; End indicator discovered?
            JR      NZ,GETLEN       ; Line 0676 ; Continue calculation until complete
            DEC     E               ; Line 0677 ; Normalize text payload balance
            LD      A,E             ; Line 0678 
            CALL    PUNCH           ; Line 0679 ; Transmit header text string volume count
            POP     BC              ; Line 0680 ; Restore directory lookup text link
OUTHDR:     LD      A,(BC)          ; Line 0681 ; Read filename character segment
            CALL    PUNCH           ; Line 0682 ; Transmit to system file record
            INC     BC              ; Line 0683 
            DEC     E               ; Line 0684 ; Continue processing block space characters
            JR      NZ,OUTHDR       ; Line 0685 
            LD      A,1             ; Line 0686 ; Identify system target file structure as absolute
            CALL    PUNCH           ; Line 0687 
            CALL    PUNHL           ; Line 0688 ; Transmit starting address metadata field
            EX      (SP),HL         ; Line 0689 ; Extract file ending address limit bound
            CALL    PUNHL           ; Line 0690 ; Transmit closing frame boundary
            POP     DE              ; Line 0691 ; DE=Start Address, HL=End Address bounds
OUTDATA:    LD      A,(DE)          ; Line 0693 ; Extract data payload byte segment
            CALL    PUNCH           ; Line 0694 ; Write byte to audio stream layer
            CALL    DPCMP           ; Line 0695 ; Compare loop memory offset markers
            INC     DE              ; Line 0696 
            JR      NZ,OUTDATA      ; Line 0697 ; Loop until memory array maps fully

BLANK:      PUSH    BC              ; Line 0698 
            LD      C,40            ; Line 0699 ; Pad delay operational interval frame loop
D250:       LD      B,250           ; Line 0700 
            CALL    DBMS            ; Line 0701 ; Run delay generator
            DEC     C               ; Line 0702 
            JR      NZ,D250         ; Line 0703 
            POP     BC              ; Line 0704 
            RET                     ; Line 0705 

DPCMP:      PUSH    HL              ; Line 0712 ; Preserve register values
            OR      A               ; Line 0713 ; Clear Carry flag indicators
            SBC     HL,DE           ; Line 0714 ; Execute word compare subtraction loop
            POP     HL              ; Line 0715 
            RET                     ; Line 0716 
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART B2 OF 4
; Core Function: Tape Audio Demodulator Sync and File Import Loops
; ==============================================================================

; ------------------------------------------------------------------------------
; READ - FUNCTION TO RETRIEVE AND PARSE FILE PAYLOADS FROM TAPE
; ------------------------------------------------------------------------------
READ:       LD      HL,(BUFPTR)     ; Line 0732 ; Pull file lookup parameters
            LD      B,H             ; Line 0733 
            LD      C,L             ; Line 0734 ; Target file name string in BC

FILIN:      LD      H,B             ; Line 0745 ; Match lookup index reference
            LD      L,C             ; Line 0746 
            LD      (BUFAD),HL      ; Line 0747 
            LD      DE,TPROMP       ; Line 0748 ; Print scan status banner
            CALL    BUFFOUT         ; Line 0749 
GETFIL:     CALL    CRLF            ; Line 0750 
            LD      HL,(BUFAD)      ; Line 0751 ; Restore active string pointer
GETLDR:     LD      B,32            ; Line 0752 ; Require 32 leader sync bytes
GETLD:      CALL    READER          ; Line 0753 ; Pull byte from tape interface
            CP      CR              ; Line 0754 ; Is leader code correct?
            JR      NZ,GETLDR       ; Line 0755 ; Sync lost, re-initialize scan
            DEC     B               ; Line 0756 
            JR      NZ,GETLD        ; Line 0757 ; Confirm leader block matches
WAITMRK:    CALL    READER          ; Line 0758 ; Look for end-of-leader mark
            AND     A               ; Line 0759 ; Is value zero (00H)?
            JR      NZ,WAITMRK      ; Line 0760 
            CALL    READER          ; Line 0761 ; Extract header length byte
            LD      B,A             ; Line 0762 
GETHDR:     CALL    READER          ; Line 0763 ; Read tape filename character
            CALL    CONOUT          ; Line 0764 ; Print character to screen
            CP      (HL)            ; Line 0765 ; Match active search target?
            JR      NZ,PRTHDR       ; Line 0766 ; Discrepancy found, dump frame
            DEC     B               ; Line 0767 
            INC     HL              ; Line 0768 ; Advance parameter index pointer
            JR      NZ,GETHDR       ; Line 0769 ; Loop until filename field ends
            LD      A,(HL)          ; Line 0770 ; Verify clean closing parameter
            CP      CR              ; Line 0771 
            JR      NZ,GETFIL       ; Line 0772 ; Length error, drop back to loop
            XOR     A               ; Line 0773 
            LD      (PAR1),A        ; Line 0774 ; Reset error status tracker flag
            CALL    READER          ; Line 0775 ; Discard file type descriptor
            CALL    TAPE            ; Line 0776 ; Pull load address low byte
            LD      L,A             ; Line 0777 
            CALL    TAPE            ; Line 0778 ; Pull load address high byte
            LD      H,A             ; Line 0779 
            PUSH    HL              ; Line 0780 ; Save memory load target vector
            CALL    TAPE            ; Line 0781 ; Pull file end boundary low byte
            LD      E,A             ; Line 0782 
            CALL    TAPE            ; Line 0783 ; Pull file end boundary high byte
            LD      D,A             ; Line 0784 
LDFIL:      CALL    TAPE            ; Line 0785 ; Read data payload byte segment
            LD      (HL),A          ; Line 0786 ; Write byte directly to system RAM
            CALL    DPCMP           ; Line 0787 ; Terminal boundaries reach parity?
            INC     HL              ; Line 0788 ; Advance memory writing pointer
            JR      NZ,LDFIL        ; Line 0789 ; Repeat write until file ends
            POP     HL              ; Line 0790 ; Restore starting address vector
            LD      A,(PAR1)        ; Line 0791 ; Check checksum transmission status
            AND     A               ; Line 0792 ; Evaluate flags matrix result
            RET                     ; Line 0793 
PRTHDR:     DEC     B               ; Line 0795 ; Complete stream dump sequence
            JR      Z,GETFIL        ; Line 0796 ; Balance failed, jump to next file
            CALL    READER          ; Line 0797 ; Read remaining text byte field
            CALL    CONOUT          ; Line 0798 ; Flush character out to screen
            JR      PRTHDR          ; Line 0799 ; Complete line printout loop
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART B3 OF 4
; Core Function: Character Scanner Parsing Loops and Validation Filters
; ==============================================================================

GETCH:      PUSH    HL              ; Line 0808 
            LD      HL,(BUFPTR)     ; Line 0809 ; Extract active parsing line pointer
            LD      A,(HL)          ; Line 0810 ; Pull targeted working character
            INC     HL              ; Line 0811 ; Advance token pointer to next element
            LD      (BUFPTR),HL     ; Line 0812 ; Save updated scan tracking address vector
            POP     HL              ; Line 0813 
            RET                     ; Line 0814 

; ------------------------------------------------------------------------------
; GETUCT - EXTRACT CHARACTER FROM STREAM AND VALIDATE TERMINATION LOGIC
; ------------------------------------------------------------------------------
GETUCT:     CALL    GETCH           ; Line 0825 ; Extract byte from execution line buffer
            CALL    UCMASK          ; Line 0826 ; Translate value to uppercase spectrum
TERM:       CP      ','             ; Line 0827 ; Delimiter character matched?
            SCF                     ; Line 0828 
            RET     Z               ; Line 0829 ; Return true with Carry active if comma found
            CP      CR              ; Line 0830 ; End of text command line discovered?
            SCF                     ; Line 0831 
            RET     Z               ; Line 0832 ; Return true with Carry active if line finished
            CP      '^'             ; Line 0833 ; Step-back navigational indicator discovered?
            SCF                     ; Line 0834 
            RET     Z               ; Line 0835 ; Return true with Carry active if backstep set
            CCF                     ; Line 0836 ; No match, reset Carry parameter state to zero
            RET                     ; Line 0837 

GETDEC:     CALL    GETUCT          ; Line 0852 ; Extract character segment parameter
            RET     C               ; Line 0853 ; Return immediately if boundary delimiter found
DECCHK:     SUB     '0'             ; Line 0854 ; Strip decimal base formatting bias character code
            JR      C,PARER         ; Line 0855 ; Less than zero ascii, syntax exception error
            CP      9+1             ; Line 0856 ; Check value limits boundaries
            CCF                     ; Line 0857 
            RET     NC              ; Line 0858 ; Balanced value processed completely, return integer
            JR      PARER           ; Line 0859 

GETHEX:     CALL    GETUCT          ; Line 0861 ; Retrieve tracking character text parameter
            RET     C               ; Line 0862 ; Return instantly if line delimiter found
HEXCHK:     SUB     '0'             ; Line 0863 ; Evaluate alphanumeric character layout parameters
            JR      C,PARER         ; Line 0864 
            CP      9+1             ; Line 0865 
            CCF                     ; Line 0866 
            RET     NC              ; Line 0867 ; Return value segment if digit matches 0-9
            SUB     'A'-'0'-10      ; Line 0868 ; Convert character formatting logic hex bias code
            CP      10              ; Line 0869 
            JR      C,PARER         ; Line 0870 ; Value less than boundary index 'A'
            CP      16              ; Line 0871 ; Verify upper bound limit index constraint 'F'
            CCF                     ; Line 0872 
            RET     NC              ; Line 0873 ; Return converted integer character element
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART B4 OF 4
; Core Function: Parameter Extraction, Error Buffers, and Target Parsing
; ==============================================================================

; ------------------------------------------------------------------------------
; PARER - ROUTINE TO DEAL WITH ERRORS IN PARAMETERS
; ------------------------------------------------------------------------------
PARER:      LD      HL,(BUFPTR)     ; Line 0889 ; PTR TO NEXT CHARACTER
            DEC     HL              ; Line 0890 ; BACK UP TO ERROR
            LD      (HL),'?'        ; Line 0891 ; MARK ERROR WITH '?'
            INC     HL              ; Line 0892 
            LD      (HL),EOT        ; Line 0893 ; MARK END OF BUFFER
            LD      DE,INBUFF+1     ; Line 0894 ; PTR TO INPUT LINE
            CALL    BUFFOUT         ; Line 0895 ; PRINT ERROR BUFFER
            RST     $38             ; Line 0896 ; RESTART MONITOR SUPERVISOR

MODPAR:     CALL    PRTASP          ; Line 0907 ; PRINT OLD PARAMETER & VALUE
                                    ; Line 0908 ; FALL THROUGH TO READ NEW ONE

READPAR:    CALL    GETBUF          ; Line 0918 ; READ LINE FROM KEYBOARD
                                    ; Line 0919 ; FALL THROUGH TO PARAM PARSER

; ------------------------------------------------------------------------------
; PARAM - SR TO LOAD A 16 BIT PARAMETER INTO HL
; ------------------------------------------------------------------------------
PARAM:      CALL    GETUCT          ; Line 0934 ; GET CHARACTER
            LD      HL,0            ; Line 0935 ; DEFAULT VALUE TO 0000
            RET     C               ; Line 0936 ; TERMINATOR FOUND
            CP      39; '\''            ; Line 0937 ; ASCII LITERAL FLAG?
            JR      NZ,NOTLIT       ; Line 0938 ; NO, TRY FOR DECIMAL TYPE
            CALL    GETCH           ; Line 0939 ; GET LITERAL VALUE
            CP      CR              ; Line 0940 ; CHECK FOR EMPTY FIELD
            JR      Z,PARER         ; Line 0941 ; SYNTAX FAULT
            LD      L,A             ; Line 0942 ; CACHE ASCII STRING DATA
            CALL    GETUCT          ; Line 0943 ; CHECK LINKING TERMINATOR
            JR      NC,PARER        ; Line 0944 ; FAULT DISCOVERED
            CCF                     ; Line 0945 ; CLEAR CARRY STATE
            RET                     ; Line 0946 
NOTLIT:     CP      DECMRK          ; Line 0947 ; DECIMAL SYMBOL FLAG?  (JS)
            JR      NZ,HEX          ; Line 0948 ; NO, SKIP TO HEX INTERPRETER
DECPAR:     CALL    GETDEC          ; Line 0949 ; EXTRACT VALUE DIGIT
            CCF                     ; Line 0950 ; SYNC CONTROL STATE
            RET     NC              ; Line 0951 ; GOT LINE TERMINATOR (JS)
            PUSH    HL              ; Line 0952 
            POP     DE              ; Line 0953 ; HL COPY IN DE
            ADD     HL,HL           ; Line 0954 ; SCALE HL BY 10 (HL=HL*2)
            ADD     HL,HL           ; Line 0955 ; (HL=HL*4)
            ADD     HL,DE           ; Line 0956 ; (HL=HL*5)
            ADD     HL,HL           ; Line 0957 ; (HL=HL*10)
            LD      B,0             ; Line 0958 
            LD      C,A             ; Line 0959 ; BC = RETRIEVED VAL DIGIT
            ADD     HL,BC           ; Line 0960 ; ACCUMULATE TOTAL
            JR      DECPAR          ; Line 0961 ; PARSE SUBSEQUENT DIGITS
HEX:        CALL    HEXCHK          ; Line 0962 ; VALIDATE CHARACTER AS HEX
HEXPAR:     ADD     HL,HL           ; Line 0963 ; SCALE HL BY 16 (HL=HL*2)
            ADD     HL,HL           ; Line 0964 ; (HL=HL*4)
            ADD     HL,HL           ; Line 0965 ; (HL=HL*8)
            ADD     HL,HL           ; Line 0966 ; (HL=HL*16)
            ADD     A,L             ; Line 0967 ; INJECT NEW VALUE SYMBOL
            LD      L,A             ; Line 0968 
            CALL    GETHEX          ; Line 0969 ; ATTEMPT NEXT FIELD VALUE
            JR      NC,HEXPAR       ; Line 0970 ; CONTINUITY OBSERVED
            CCF                     ; Line 0971 
            RET                     ; Line 0972 
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART C1 OF 4
; Core Function: Dual-Parameter Validation & Supervisor Core Instruction Router
; ==============================================================================

GET2PAR:    XOR     A               ; Line 0984 ; Reset parameter counter to 0
            EX      AF,AF'          ; Line 0985 ; Store counter in alternate register
            CALL    PARAM           ; Line 0986 ; Parse first input parameter
            JR      C,ALLREAD       ; Line 0987 ; Branch if empty parameter found
            LD      (PAR1),HL       ; Line 0988 ; Store verified value in PAR1
            CP      ','             ; Line 0989 ; Is another argument linked?
            EX      AF,AF'          ; Line 0990 ; Retrieve parameter counter
            INC     A               ; Line 0991 ; Increment parsed value count
            EX      AF,AF'          ; Line 0992 ; Save counter status back
            JR      NZ,ALLREAD      ; Line 0993 ; Line ended, terminal parameter reached
            CALL    PARAM           ; Line 0994 ; Parse second input parameter
            LD      (PAR2),HL       ; Line 0995 ; Store value in PAR2 cache
            EX      AF,AF'          ; Line 0996 
            INC     A               ; Line 0997 ; Increment parsed value count to 2
            EX      AF,AF'          ; Line 0998 
ALLREAD:    EX      AF,AF'          ; Line 0999 ; Pull parameter count to A
            LD      (NPARS),A       ; Line 1000 ; Store quantified execution count
            EX      AF,AF'          ; Line 1001 ; Restore ending line character
            RET                     ; Line 1002 

PCHECK:     CALL    GET2PAR         ; Line 1016 ; Pull instruction parameter variables
            PUSH    AF              ; Line 1017 ; Cache line character indicator
            LD      A,(NPARS)       ; Line 1018 ; Verify parsed arguments count
            AND     A               ; Line 1019 
            JR      Z,PARER         ; Line 1020 ; Empty target fields, break with error
            POP     AF              ; Line 1021 
            RET                     ; Line 1022 

PRTA:       PUSH    AF              ; Line 1029 ; Save working byte parameter
            RRCA                    ; Line 1030 ; Extract upper 4-bit nibble value
            RRCA                    ; Line 1031 
            RRCA                    ; Line 1032 
            RRCA                    ; Line 1033 
            CALL    HXCVRT          ; Line 1034 ; Convert and display upper hex digit
            POP     AF              ; Line 1035 ; Retrieve lower 4-bit nibble value
HXCVRT:     AND     $0F             ; Line 1036 ; Isolate hex value parameters
            ADD     A,'0'           ; Line 1037 ; Convert to visual ASCII character base
            CP      '9'+1           ; Line 1038 ; Evaluate character index threshold
            JR      C,HXPRN         ; Line 1039 ; 0-9 numerical value confirmed
            ADD     A,7             ; Line 1040 ; Adjust spacing offset for hex A-F range
HXPRN:      JP      CONOUT          ; Line 1041 ; Flush digit out to terminal screen

HEXC:       CALL    PCHECK          ; Line 1053 ; Extract entry validation fields
            LD      HL,(PAR1)       ; Line 1054 ; Retrieve base data value
            LD      A,(NPARS)       ; Line 1055 ; Query parsed field volume count
            DEC     A               ; Line 1056 
            JR      Z,PRTHLSP       ; Line 1057 ; Print 16-bit address parameters
            INC     HL              ; Line 1058 ; Target relative instruction jump logic offset
            INC     HL              ; Line 1059 
            EX      DE,HL           ; Line 1060 
            LD      HL,(PAR2)       ; Line 1061 ; Retrieve target jump location field
            SBC     HL,DE           ; Line 1062 ; Calculate offset spacing bounds parameters
                                    ; Line 1063 ; Fall down directly to output functions

PNLHLSP:    CALL    CRLF            ; Line 1073 ; Output clear carriage return line break
PRTHLSP:    LD      A,H             ; Line 1074 ; Load upper address tracking byte
            CALL    PRTA            ; Line 1075 ; Visual hex generation dispatch
            LD      A,L             ; Line 1076 ; Load lower address tracking byte
                                    ; Line 1077 ; Fall down directly to spacing interface

PRTASP:     CALL    PRTA            ; Line 1084 ; Visual character hex generation out
SPACE:      LD      A,' '           ; Line 1092 ; Load standard terminal spacing character
            JP      CONOUT          ; Line 1093 ; Clear to stream pipeline module

; ------------------------------------------------------------------------------
; MONLP - SUPERVISOR SYSTEM MONITOR COMMAND INTERPRETATION VECTOR DISPATCH LOOP
; ------------------------------------------------------------------------------
MONLP:      LD      SP,MONSTK       ; Line 1103 ; Force reset supervisor stack location
            CALL    CRLF            ; Line 1104 ; Inject line interface spacer formatting
            LD      A,PROMPT        ; Line 1105 ; Load system user input prompt marker
            CALL    CONOUT          ; Line 1106 ; Output tracking prompt string character
            CALL    GETBUF          ; Line 1107 ; Hook active console command input stream
            CALL    CRLF            ; Line 1108 
            CALL    GETUCT          ; Line 1109 ; Retrieve character instruction routing token
            LD      HL,MONLP        ; Line 1110 ; Establish structural return reference
            PUSH    HL              ; Line 1111 ; Cache supervisor path tracking vector frame
            CP      '-'             ; Line 1112 ; Query clear breakpoint command indicator
            JR      Z,MINUSB        ; Line 1113 ; Dispatched breakpoint manipulation parser
            SUB     'A'             ; Line 1114 ; Generate jump dictionary entry value index
            JP      Z,ASCII         ; Line 1115 ; Command Action Vector target: [A]ascii
            DEC     A               ; Line 1116 
            JP      Z,SETBPT        ; Line 1117 ; Command Action Vector target: [B]reakpoint
            DEC     A               ; Line 1118 
            DEC     A               ; Line 1119 
            JP      Z,DUMP          ; Line 1120 ; Command Action Vector target: [D]ump hex
            DEC     A               ; Line 1121 
            JP      Z,EDIT          ; Line 1122 ; Command Action Vector target: [E]dit firmware
            DEC     A               ; Line 1123 
            JP      Z,FILL          ; Line 1124 ; Command Action Vector target: [F]ill memory
            DEC     A               ; Line 1125 
            JP      Z,GO            ; Line 1126 ; Command Action Vector target: [G]o run execute
            DEC     A               ; Line 1127 
            JR      Z,HEXC          ; Line 1128 ; Command Action Vector target: [H]ex conversion
            SUB     5               ; Line 1129 
            JP      Z,MOVE          ; Line 1130 ; Command Action Vector target: [M]ove array block
            SUB     3               ; Line 1131 
            JP      Z,PASCAL        ; Line 1132 ; Command Action Vector target: [P]ascal overlay
            DEC     A               ; Line 1133 
            DEC     A               ; Line 1134 
            JP      Z,READ          ; Line 1135 ; Command Action Vector target: [R]ead stream file
            DEC     A               ; Line 1136 
            JP      Z,SET           ; Line 1137 ; Command Action Vector target: [S]et modify byte
            DEC     A               ; Line 1138 
            JP      Z,TRACE         ; Line 1139 ; Command Action Vector target: [T]race debugger
            SUB     3               ; Line 1140 
            JP      Z,WRITE         ; Line 1141 ; Command Action Vector target: [W]rite storage file
            DEC     A               ; Line 1142 
            JP      Z,XAMIN         ; Line 1143 ; Command Action Vector target: [X]examine register

COMER:      JP      PARER           ; Line 1145 ; Exception caught, command invalid error
MINUSB:     CALL    GETUCT          ; Line 1147 ; Parse following flag qualifier token
            CP      'B'             ; Line 1148 ; Is breakpoint operational argument validated?
            JR      NZ,COMER        ; Line 1149 ; Bad command layout option, throw exception
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART C2 OF 4
; Core Function: Breakpoint Table Shifting, Installation, and Clearance Loops
; ==============================================================================

CLRBPT:     CALL    PARAM           ; Line 1168 ; Parse address argument if present
            LD      B,NBP           ; Line 1169 ; Load total breakpoint loop limit count
            LD      IX,BPTAB        ; Line 1170 ; Point to breakpoint storage matrix area
            JR      C,CLRALL        ; Line 1171 ; Empty argument, proceed to wipe table
CLRSRC:     LD      E,(IX+0)        ; Line 1172 ; Extract low address tracker byte from table
            LD      D,(IX+1)        ; Line 1173 ; Extract high address tracker byte from table
            CALL    DPCMP           ; Line 1174 ; Match address field query parameters
            JR      Z,CLEAR         ; Line 1175 ; Match discovered, remove breakpoint entry
            INC     IX              ; Line 1176 ; Advance table workspace focus pointer
            INC     IX              ; Line 1177 
            INC     IX              ; Line 1178 
            DJNZ    CLRSRC          ; Line 1179 ; Loop through active elements inside table
LSTBPT:     LD      B,NBP           ; Line 1181 ; Query and report active target vectors
            LD      DE,BPTAB        ; Line 1182 
LSTB:       LD      A,(DE)          ; Line 1183 ; Extract tracking address low byte register
            LD      L,A             ; Line 1184 
            INC     DE              ; Line 1185 
            LD      A,(DE)          ; Line 1186 ; Extract tracking address high byte register
            LD      H,A             ; Line 1187 
            INC     DE              ; Line 1188 
            INC     DE              ; Line 1189 
            CP      MONPAG          ; Line 1190 ; Is address field marked as inactive ROM page?
            JR      Z,LASTB         ; Line 1191 ; Yes, end of directory listings reached
            CALL    PRTHLSP         ; Line 1192 ; Print active address reference out to terminal
            DJNZ    LSTB            ; Line 1193 ; Loop until table list outputs completely
LASTB:      JP      CRLF            ; Line 1194 

CLEAR:      DEC     B               ; Line 1196 ; Calculate size adjustments shift metrics
            LD      A,B             ; Line 1197 
            ADD     A,A             ; Line 1198 ; Scale row entry sizes offset elements (Row * 2)
            ADD     A,B             ; Line 1199 ; (Row * 3 size matrix)
            LD      C,A             ; Line 1200 ; Set loop index constraint size count in BC
            LD      B,0             ; Line 1201 
            PUSH    IX              ; Line 1202 
            POP     DE              ; Line 1203 ; DE = Starting address location of empty entry
            JR      Z,NOMOVE        ; Line 1204 ; Array row bounds matched, skip moving layout
            LD      H,D             ; Line 1205 ; Establish memory block copy address vectors
            LD      L,E             ; Line 1206 
            INC     HL              ; Line 1207 
            INC     HL              ; Line 1208 
            INC     HL              ; Line 1209 
            LDIR                    ; Line 1210 ; Compress array table space to close gap
NOMOVE:     LD      A,MONPAG        ; Line 1211 ; Load standard monitor page identifier flag
            INC     DE              ; Line 1212 
            LD      (DE),A          ; Line 1213 ; Mark newly exposed row index slots empty
            JR      LSTBPT          ; Line 1214 ; Output revised active breakpoint map grid

CLRALL:     INC     IX              ; Line 1216 ; Advance table address pointer location focus
            LD      DE,3            ; Line 1217 ; Load structural matrix entry stride dimension
            LD      A,MONPAG        ; Line 1218 ; Load baseline inactive identifier marker code
CLRBPN:     LD      (IX+0),A        ; Line 1219 ; Inject empty code value into high index byte
            ADD     IX,DE           ; Line 1220 ; Step matrix focus register to next row path
            DJNZ    CLRBPN          ; Line 1221 
            RET                     ; Line 1222 

SETBPT:     CALL    PARAM           ; Line 1233 ; Extract target entry location parameters
            JR      C,LSTBPT        ; Line 1234 ; Argument clear, proceed directly to display lists
            LD      IX,BPTAB        ; Line 1235 ; Track master target breakpoint array memory base
            LD      B,NBP           ; Line 1236 ; Load maximum internal storage allocation bounds
SETB:       LD      E,(IX+0)        ; Line 1237 ; Read active row vector tracking indices low byte
            LD      D,(IX+1)        ; Line 1238 ; Read active row vector tracking indices high byte
            LD      A,D             ; Line 1239 
            CP      MONPAG          ; Line 1240 ; Is slot currently empty/inactive configuration?
            JR      Z,SETIT         ; Line 1241 ; Empty slot discovered, inject user parameters
            CALL    DPCMP           ; Line 1242 ; Check if address vector duplicate is present
            JR      Z,LSTBPT        ; Line 1243 ; Already configured, skip addition sequence
            INC     IX              ; Line 1244 ; Shift tracking focus pointer to following row
            INC     IX              ; Line 1245 
            INC     IX              ; Line 1246 
            DJNZ    SETB            ; Line 1247 ; Loop until entire storage block evaluates fully
            LD      DE,ALLSET       ; Line 1248 
            CALL    BUFFCR          ; Line 1249 ; Array table footprint saturated message block
            JR      LSTBPT          ; Line 1250 
SETIT:      LD      (IX+0),L        ; Line 1252 ; Inject destination address parameters into table
            LD      (IX+1),H        ; Line 1253 
            JR      LSTBPT          ; Line 1254 ; Display refreshed layout overview trace
;snip
; ==============================================================================
; Z80 ASSEMBLY SOURCE CODE — MISSING BLOCK PART C3 OF 4
; Core Function: Memory Array Fill, ASCII Injection, and Runtime Execution Loops
; ==============================================================================

; ------------------------------------------------------------------------------
; FILL - FUNCTION TO DATA-FILL A TARGET REGION OF SYSTEM RAM
; ------------------------------------------------------------------------------
FILL:       CALL    PCHECK          ; Line 1262 ; Extract boundary setup metrics
            CP      ','             ; Line 1263 ; Verify syntax parsing comma divider
FERR:       JP      NZ,PARER        ; Line 1264 ; Invalid parameters array syntax layout
            CALL    PARAM           ; Line 1265 ; Extract fill data token argument
            LD      A,L             ; Line 1266 ; Assign character byte value parameter
            LD      HL,(PAR1)       ; Line 1267 ; Load start coordinate address value
            EX      DE,HL           ; Line 1268 ; Move start vector address to DE
            LD      HL,(PAR2)       ; Line 1269 ; Extract destination end marker address
FILLM:      LD      (DE),A          ; Line 1270 ; Inject data value directly into RAM target
            CALL    DPCMP           ; Line 1271 ; Evaluate pointer loop end state targets
            INC     DE              ; Line 1272 ; Advance writing pointer address
            JR      NZ,FILLM        ; Line 1273 ; Repeat execution pass loop completely
            RET                     ; Line 1274 

; ------------------------------------------------------------------------------
; ASCII - FUNCTION TO INJECT STRINGS DIRECTLY INTO TARGET ADDRESS
; ------------------------------------------------------------------------------
ASCII:      CALL    PARAM           ; Line 1286 ; Extract destination address vector
            JP      C,PARER         ; Line 1287 ; Target address absent, trigger error path
            PUSH    HL              ; Line 1288 ; Cache writing base address point
            CALL    GETBUF          ; Line 1289 ; Collect target text line string from kbd
            POP     HL              ; Line 1290 ; Restore base memory write coordinate
ASCL:       CALL    GETCH           ; Line 1291 ; Extract text stream byte token element
            LD      (HL),A          ; Line 1292 ; Commit character byte string directly to RAM
            INC     HL              ; Line 1293 ; Advance tracking buffer target index
            CP      CR              ; Line 1294 ; Is string line completion reached?
            JR      NZ,ASCL         ; Line 1295 ; Continue string generation loop pass
            DEC     HL              ; Line 1296 ; Adjust boundary focus back over return byte
            LD      (HL),EOT        ; Line 1297 ; Inject End of Transmission sentinel tracking
            CALL    CRLF            ; Line 1298 
            JP      PRTHLSP         ; Line 1299 ; Print final writing index tracking vector

; ------------------------------------------------------------------------------
; GO - FUNCTION TO TRANSFER ABSOLUTE SYSTEM CONTROLS TO TARGET APPLICATION
; ------------------------------------------------------------------------------
GO:         CALL    PARAM           ; Line 1312 ; Query code execution entry address
            JR      C,CONTINUE      ; Line 1313 ; Missing input parameter, continue old task
            LD      (PCSAV),HL      ; Line 1314 ; Load target entry path vector code to PC
CONTINUE:   LD      HL,BREAK        ; Line 1316 ; Intercept Core Restart tracking loop trap
            LD      (RST7+1),HL     ; Line 1317 ; Route vector directly into BREAK interface
            LD      HL,BPTAB        ; Line 1318 ; Master tracking base of Breakpoint Array
            LD      B,NBP           ; Line 1319 ; Initialize loop tracking limit index span
INSTALL:    LD      E,(HL)          ; Line 1320 ; Extract active trap point address low byte
            INC     HL              ; Line 1321 
            LD      D,(HL)          ; Line 1322 ; Extract active trap point address high byte
            INC     HL              ; Line 1323 
            PUSH    HL              ; Line 1324 ; Cache array scanning layout index pointer
            LD      HL,(PCSAV)      ; Line 1325 ; Extract application program start counter
            CALL    DPCMP           ; Line 1326 ; Entry coordinate matches breakpoint target?
            POP     HL              ; Line 1327 ; Restore pointer context element state
            LD      A,(DE)          ; Line 1328 ; Fetch user app native operation opcode
            LD      (HL),A          ; Line 1329 ; Store operation byte into cache row block
            JR      Z,MISS          ; Line 1330 ; Entry vector alignment conflict, skip mask
            LD      A,BRK           ; Line 1331 ; Load software trap restart instruction code
            LD      (DE),A          ; Line 1332 ; Overwrite program code line with active trap
MISS:       INC     HL              ; Line 1333 
            DJNZ    INSTALL         ; Line 1334 ; Continue code loop initialization pass
            LD      SP,ISAV         ; Line 1335 ; Swap execution stack focus over register cache
;snip
            POP     AF              ; Line 1336 
            LD      I,A             ; Line 1337 ; Restore Register I
            POP     AF              ; Line 1338 ; Restore Registers AF
            POP     BC              ; Line 1339 ; Restore Registers BC
            POP     DE              ; Line 1340 ; Restore Registers DE
            POP     HL              ; Line 1341 ; Restore Registers HL
            POP     IX              ; Line 1342 ; Restore Index Register IX
            POP     IY              ; Line 1343 ; Restore Index Register IY
            POP     HL              ; Line 1344 ; Pull saved Stack Pointer
            LD      SP,HL           ; Line 1345 ; Set active Stack Pointer SP
            LD      HL,(PCSAV)      ; Line 1346 ; Load user app start vector
            PUSH    HL              ; Line 1347 ; Force target onto stack layer
            LD      HL,(HLSAV)      ; Line 1348 ; Restore target value to HL
            RET                     ; Line 1349 ; Control transfer to user app

BREAK:      LD      (HLSAV),HL      ; Line 1357 ; Capture current HL state
            LD      (DISPAD),HL     ; Line 1358 ; Assign address as hex dump base
            POP     HL              ; Line 1359 ; Pull program counter from stack
            DEC     HL              ; Line 1360 ; Offset back over executed trap
            LD      (PCSAV),HL      ; Line 1361 ; Capture execution address
            LD      (SPSAV),SP      ; Line 1362 ; Capture application stack bounds
            LD      SP,SPSAV        ; Line 1363 ; Relocate stack focus to workspace
            PUSH    IY              ; Line 1364 ; Snapshot registers/flags matrices
            PUSH    IX              ; Line 1365 
            DEC     SP              ; Line 1366 ; Skip structural slot for HLSAV
            DEC     SP              ; Line 1367 
            PUSH    DE              ; Line 1368 
            PUSH    BC              ; Line 1369 
            PUSH    AF              ; Line 1370 
            LD      A,I             ; Line 1371 ; Capture interrupt register flag
            PUSH    AF              ; Line 1372 
            LD      SP,MONSTK       ; Line 1373 ; Re-establish supervisor stack
            LD      HL,BPTAB        ; Line 1374 ; Target base of Breakpoint Table
            LD      B,NBP           ; Line 1375 ; Initialize table cleaning count
RESETBP:    LD      E,(HL)          ; Line 1376 ; Pull trap vector low byte
            INC     HL              ; Line 1377 
            LD      D,(HL)          ; Line 1378 ; Pull trap vector high byte
            INC     HL              ; Line 1379 
            LD      A,(HL)          ; Line 1380 ; Extract cached original opcode
            INC     HL              ; Line 1381 
            LD      (DE),A          ; Line 1382 ; Patch app line back to original
            DJNZ    RESETBP         ; Line 1383 ; Loop until breakpoint clears
            LD      HL,MONLP        ; Line 1384 ; Load primary monitor execution path
            LD      (RST7+1),HL     ; Line 1385 ; Standardize vectors back to monitor
;snip
STATUS:     CALL    RDIS            ; Line 1390 ; Output current register snapshots
            RST     $38             ; Line 1391 ; Loop control back into command line interpreter

RDIS:       LD      DE,REGHDR       ; Line 1393 ; Load register summary interface layout
            CALL    BUFFCR          ; Line 1394 
            CALL    FLAGDIS         ; Line 1395 ; Map out text summary parameters for flags
            LD      DE,ISAV+1       ; Line 1396 ; Target stored register snapshot: I
            LD      A,(DE)          ; Line 1397 
            INC     DE              ; Line 1398 
            INC     DE              ; Line 1399 
            CALL    PRTASP          ; Line 1400 ; Output hex register details followed by spacing
            LD      A,(DE)          ; Line 1401 ; Target stored register snapshot: A
            INC     DE              ; Line 1402 
            CALL    PRTASP          ; Line 1403 ; Output hex register details followed by spacing
            LD      B,7             ; Line 1404 ; Initialize 16-bit register looping cycle index
PRTDBL:     LD      A,(DE)          ; Line 1405 ; Extract structural byte data from register array
            LD      L,A             ; Line 1406 
            INC     DE              ; Line 1407 
            LD      A,(DE)          ; Line 1408 
            LD      H,A             ; Line 1409 
            INC     DE              ; Line 1410 
            CALL    PRTHLSP         ; Line 1411 ; Output 16-bit word block data index
            DJNZ    PRTDBL          ; Line 1412 ; Loop until all 7 master snapshot registers clear
            RET                     ; Line 1413 

FLAGDIS:    LD      HL,FLGTAB       ; Line 1415 ; Point to system bitmask testing parameter array
            LD      B,6             ; Line 1416 ; Set iteration limit spanning the 6 Z80 flags
PRTFLG:     LD      A,(AFSAV)       ; Line 1417 ; Pull cached application flags state register
            AND     (HL)            ; Line 1418 ; Isolate current query focus bit layer
            INC     HL              ; Line 1419 
            LD      A,(HL)          ; Line 1420 ; Extract visual ASCII symbol assigned to target flag
            JR      NZ,FLAGSET      ; Line 1421 ; Flag logic bit active, output symbol directly
            LD      A,'-'           ; Line 1422 ; Bit clear, override output character with spacer dash
FLAGSET:    CALL    CONOUT          ; Line 1423 ; Write character out to console display line
            INC     HL              ; Line 1424 
            DJNZ    PRTFLG          ; Line 1425 ; Loop until flags tracking pass satisfies entirely
            JP      SPACE           ; Line 1426 
;snip
; ------------------------------------------------------------------------------
; XAMIN - FUNCTION TO QUERY AND INTERACTIVELY UPDATE REGISTER SNAPSHOTS
; ------------------------------------------------------------------------------
XAMIN:      CALL    GETUCT          ; Line 1442 ; Query parameter key token
            JR      C,RDIS          ; Line 1443 ; If missing token, output all
            CP      'F'             ; Line 1444 ; Target matches [F]lags?
            JR      Z,FLGMFY        ; Line 1445 
            CP      'A'             ; Line 1446 ; Target matches [A]ccumulator?
            JR      Z,ACCMFY        ; Line 1447 
            CP      'I'             ; Line 1448 ; Target matches [I]nterrupt?
            JR      Z,INTMFY        ; Line 1449 
            LD      HL,REGTAB       ; Line 1450 ; Set array list bounds focus
            LD      BC,8            ; Line 1451 
            CPIR                    ; Line 1452 ; Scan text index for character match
            JR      NZ,FPARER       ; Line 1453 ; Unmatched, parameter error
            LD      HL,AFSAV        ; Line 1454 ; Base of register storage block
            ADD     HL,BC           ; Line 1455 ; Add offset index (Words)
            ADD     HL,BC           ; Line 1456 
            PUSH    HL              ; Line 1457 
            LD      A,(HL)          ; Line 1458 ; Pull existing data byte component
            INC     HL              ; Line 1459 
            LD      H,(HL)          ; Line 1460 
            LD      L,A             ; Line 1461 
            CALL    PRTHLSP         ; Line 1462 ; Print 16-bit state to terminal
            CALL    READPAR         ; Line 1463 ; Parse number modification data
            EX      DE,HL           ; Line 1464 
            POP     HL              ; Line 1465 ; Restore context data pointer
            RET     C               ; Line 1466 ; No modification logged, exit block
            LD      (HL),E          ; Line 1467 ; Write revised lower byte to cache
            INC     HL              ; Line 1468 
            LD      (HL),D          ; Line 1469 ; Write revised upper byte to cache
            RET                     ; Line 1470 

ACCMFY:     LD      DE,AFSAV+1      ; Line 1472 ; Target register snapshot: A
            JR      MFY8            ; Line 1473 
INTMFY:     LD      DE,ISAV+1       ; Line 1475 ; Target register snapshot: I
MFY8:       LD      A,(DE)          ; Line 1476 
            PUSH    DE              ; Line 1477 ; Cache system memory entry tracker
            CALL    MODPAR          ; Line 1478 ; Print current metric and evaluate update
            POP     DE              ; Line 1479 
            RET     C               ; Line 1480 ; Value unchanged, return from handler
            LD      A,L             ; Line 1481 ; Isolate lower byte data
            LD      (DE),A          ; Line 1482 ; Save updated byte to snapshot register
            RET                     ; Line 1483 

FLGMFY:     CALL    FLAGDIS         ; Line 1485 ; Display flag bit parameters
            CALL    GETBUF          ; Line 1486 ; Pull updated descriptors array data
            LD      C,0             ; Line 1487 ; Initialize empty bitmask accumulator
FLGL:       CALL    GETUCT          ; Line 1488 ; Extract target identifier letter token
            RET     C               ; Line 1489 ; Line complete, exit block
            LD      HL,FLGTAB+1     ; Line 1490 ; Set scanning database pointer focus
            LD      B,6             ; Line 1491 
FLG2:       CP      (HL)            ; Line 1492 ; Input character matches descriptor?
            JR      Z,FSET          ; Line 1493 ; Match found, activate bit mask
            INC     HL              ; Line 1494 
            INC     HL              ; Line 1495 
            DJNZ    FLG2            ; Line 1496 ; Continue scanning options list
FPARER:     JP      PARER           ; Line 1497 ; Invalid token identifier exception

FSET:       LD      A,C             ; Line 1499 ; Pull parameter bit mask cache
            DEC     HL              ; Line 1500 ; Realign pointer over flag mask byte
            OR      (HL)            ; Line 1501 ; Inject parameter mask layer into data byte
            INC     HL              ; Line 1502 
            LD      (AFSAV),A       ; Line 1503 ; Commit updated flags byte to storage
            LD      C,A             ; Line 1504 
            JR      FLGL            ; Line 1505 ; Query stream for additional tokens
;snip
; ------------------------------------------------------------------------------
; SET - FUNCTION TO INTERACTIVELY EXAMINE AND INJECT BYTES DIRECTLY INTO RAM
; ------------------------------------------------------------------------------
SET:        CALL    PCHECK          ; Line 1518 ; Parse and verify target address
            LD      HL,(PAR1)       ; Line 1519 
            EX      DE,HL           ; Line 1520 ; Relocate tracking address pointer to DE
SETLP:      LD      H,D             ; Line 1521 ; Align address into HL for screen print
            LD      L,E             ; Line 1522 
            CALL    PNLHLSP         ; Line 1523 ; Direct print: CR, LF, Address, space
            LD      A,(DE)          ; Line 1524 ; Read existing live data byte from RAM
            PUSH    DE              ; Line 1525 
            CALL    MODPAR          ; Line 1526 ; Output current state, await new data entry
            POP     DE              ; Line 1527 
            JR      C,NOUPDAT       ; Line 1528 ; No data entry, retain baseline value
            EX      DE,HL           ; Line 1529 ; Swap writing pointers and data blocks
            LD      (HL),E          ; Line 1530 ; Write user modification into RAM
            EX      DE,HL           ; Line 1531 
NOUPDAT:    CP      '^'             ; Line 1532 ; Query command backstep indicator
            DEC     DE              ; Line 1533 ; Calculate address backward
            JR      Z,SETLP         ; Line 1534 ; Navigation token valid, cycle loop back
            INC     DE              ; Line 1535 ; Re-adjust target pointer alignments
            INC     DE              ; Line 1536 ; Advance writing index coordinates forward
            JR      SETLP           ; Line 1537 ; Repeat verification step pass
;snip
; ------------------------------------------------------------------------------
; DUMP - FUNCTION TO OUTPUT MEMORY BLOCKS VIA HEX AND ASCII DESCRIPTORS
; ------------------------------------------------------------------------------
DUMP:       CALL    GET2PAR         ; Line 1553 ; Parse text string block variables
            LD      A,(NPARS)       ; Line 1554 ; Query parsed argument metrics count
            AND     A               ; Line 1555 
            LD      HL,(DISPAD)     ; Line 1556 ; Load continuous tracking address from cache
            LD      DE,DEFLEN       ; Line 1557 ; Load system default block data span length
            JR      Z,DISPLAY       ; Line 1558 ; No parameters, use defaults
            LD      HL,(PAR1)       ; Line 1560 ; Custom parameters found, focus target
            DEC     A               ; Line 1561 ; Evaluate trailing argument limits
            JR      Z,DISPLAY       ; Line 1562 ; Single custom argument, use default bounds
            EX      DE,HL           ; Line 1563 ; Multi-argument setup coordinates
            LD      HL,(PAR2)       ; Line 1564 ; Extract custom terminal boundary block
            EX      DE,HL           ; Line 1565 ; HL = Start memory pointer, DE = End memory pointer
            JR      DISPL           ; Line 1566 
DISPLAY:    PUSH    HL              ; Line 1567 
            ADD     HL,DE           ; Line 1568 ; Factor default boundary spacing bounds
            EX      DE,HL           ; Line 1569 ; DE = Calculated end address boundary markers
            POP     HL              ; Line 1570 ; HL = Restore start layout base
DISPL:      LD      A,L             ; Line 1571 
            AND     $F0             ; Line 1572 ; Align display view row blocks onto 16-byte tracks
            LD      L,A             ; Line 1573 
            LD      A,E             ; Line 1574 
            AND     $F0             ; Line 1575 
            ADD     A,16            ; Line 1576 ; Enforce rounding ceiling limits
            LD      E,A             ; Line 1577 
            JR      NC,DISPLIN      ; Line 1578 ; Carry clear, row tracks balance
            INC     D               ; Line 1579 
DISPLIN:    PUSH    HL              ; Line 1580 ; Cache line tracking start boundary vector index
            CALL    PNLHLSP         ; Line 1581 ; Print row location out: CR, LF, Address, space
            CALL    SPACE           ; Line 1582 
            LD      B,8             ; Line 1583 ; Initialize visual dual-column loop count limit
PRTPAIR:    LD      A,(HL)          ; Line 1584 ; Fetch live data memory byte from RAM
            INC     HL              ; Line 1585 
            CALL    PRTA            ; Line 1586 ; Convert and output byte data hex digits to screen
            LD      A,(HL)          ; Line 1587 ; Fetch tracking dual data byte element
            INC     HL              ; Line 1588 
            CALL    PRTASP          ; Line 1589 ; Convert and output byte data hex digits with space
            DJNZ    PRTPAIR         ; Line 1590 ; Continue text row parsing blocks pass satisfying rows
            POP     HL              ; Line 1591 ; Restore line base address tracking focus
            LD      B,16            ; Line 1592 ; Set ASCII alternative rendering column block width
TXTPRT:     LD      A,(HL)          ; Line 1593 ; Extract byte parameter context element data
            CP      $20             ; Line 1594 ; Check character limits bounds text value space
            JR      C,NOASC         ; Line 1595 ; Character non-printable control code, hide element
            CP      $80             ; Line 1596 ; Evaluate against high parity character threshold
            JR      C,PRNT          ; Line 1597 ; Printable standard ASCII character validated clean
NOASC:      LD      A,'.'           ; Line 1598 ; Format invalid character out as placeholder dot
PRNT:       CALL    CONOUT          ; Line 1599 ; Stream character out to console display track
            INC     HL              ; Line 1600 
            DJNZ    TXTPRT          ; Line 1601 ; Loop layout text until entire 16-character column fills
            LD      (DISPAD),HL     ; Line 1602 ; Update default terminal address mapping location
            CALL    DPCMP           ; Line 1603 ; Absolute terminal block display views balanced?
            JR      NZ,DISPLIN      ; Line 1604 ; Array segment has remaining blocks, output following row
            RET                     ; Line 1605 

; ------------------------------------------------------------------------------
; MOVE - BLOCK MEMORY SHIFTING AND PROTECTION SYSTEM SUBROUTINES
; ------------------------------------------------------------------------------
MOVE:       CALL    PCHECK          ; Line 1616 ; Extract movement tracking address block parameters
            CP      ','             ; Line 1617 ; Check syntax separator structure parameters limits
            JP      NZ,PARER        ; Line 1618 ; Formatting parsing exception error, abort task path
            CALL    PARAM           ; Line 1619 ; Extract movement destination address parameters
            PUSH    HL              ; Line 1620 ; Cache destination block target mapping address vector
            LD      HL,(PAR1)       ; Line 1621 ; Extract primary source origin block starting address
            EX      DE,HL           ; Line 1622 
            LD      HL,(PAR2)       ; Line 1623 ; Extract primary source origin block terminal address
            PUSH    DE              ; Line 1624 
            OR      A               ; Line 1625 ; Reset internal carry flags matrix values to zero
            SBC     HL,DE           ; Line 1626 ; Process subtraction calculations to measure block size
            LD      B,H             ; Line 1627 ; Copy calculated data load block size parameter into BC
            LD      C,L             ; Line 1628 
            POP     HL              ; Line 1629 ; HL = Source location starting address mapping track
            POP     DE              ; Line 1630 ; DE = Destination location starting address mapping track
            CALL    DPCMP           ; Line 1631 ; Evaluate coordinates boundaries layout vectors paths
            RET     Z               ; Line 1632 ; Coordinates balance identically, no shifting needed
            JR      C,MVDWN         ; Line 1633 ; Shift path destination overlaps forward, move backward
            INC     BC              ; Line 1634 
            LDIR                    ; Line 1635 ; Secure memory shift execution pass: Bottom up tracking
            RET                     ; Line 1636 
MVDWN:      ADD     HL,BC           ; Line 1637 ; Adjust address paths focus points over block end
            EX      DE,HL           ; Line 1638 
            ADD     HL,BC           ; Line 1639 
            EX      DE,HL           ; Line 1640 ; DE = Recalculated destination terminal vector point
            INC     BC              ; Line 1641 
            LDDR                    ; Line 1642 ; Secure memory shift execution pass: Top down tracking
            RET                     ; Line 1643 
;snip
; ------------------------------------------------------------------------------
; DATA BLOCK DEFINITIONS & EXPLICIT STORAGE TABLES
; ------------------------------------------------------------------------------
FLGTAB:     DEFB    $80, 'S', $40, 'Z', $10, 'A', $04, 'P', $02, 'N', $01, 'C' ; Line 1646 
REGTAB:     DEFM    "PSYXHDB"       ; Line 1647 

SGNON:      DEFB    FF              ; Line 1649 ; Clear Screen macro instruction code
            DEFM    "TUSCAN V1.0 MITSI" ; Line 1650 ; Console initialization splash header
            DEFB    EOT             ; Line 1651 
TPROMP:     DEFM    "FILES FOUND :" ; Line 1652 
            DEFB    EOT             ; Line 1653 
ALLSET:     DEFB    CR, LF          ; Line 1654 
            DEFM    "ALL SET"       ; Line 1655 
            DEFB    EOT             ; Line 1656 
REGHDR:     DEFB    CR, LF          ; Line 1657 
            DEFM    "FLAGS   I  A  BC   DE  HL" ; Line 1658 
            DEFM    "   IX   IY   SP   PC" ; Line 1659 
            DEFB    EOT             ; Line 1660 

            END                     ; Line 1662 ; Formal End of Compiled Source Stream
