; ==============================================================================
; TUSCAN SYSTEM 1 - ZERO-RAM FIRST-STAGE BOOT DIAGNOSTIC (SERIAL VERSION)
; Target Assembler: Standalone GNU z80asm
; Hexadecimal Prefix: $
; Memory Footprint: Runs entirely out of EPROM (Requires 0 Bytes of RAM)
; Strict 8KB Motherboard Bound Check Included.
; ==============================================================================

; ------------------------------------------------------------------------------
; HARDWARE PORT ASSIGNMENTS (MATCHING TUSCAN HARDWARE SPECIFICATIONS)
; ------------------------------------------------------------------------------
RSDO:       EQU     $00             ; Serial Data Output Port
RSS:        EQU     $00             ; Serial UART Status Port
RSHS:       EQU     $06             ; Serial Handshake Evaluation Pin

; ------------------------------------------------------------------------------
; MONITOR COLD BOOT & SYSTEM INITIALIZATION
; ------------------------------------------------------------------------------
            ORG     $F800           ; Base entry point for your test EPROM
TRUMP:      JP      PON             ; Force absolute jump to break hardware boot mode

PON:        DI                      ; Disable all masks and interrupts
            
            ; Output an initial carriage return and line feed to settle terminal
            LD      A,13            ; Carriage Return
            JR      SER_OUT
CR_DONE:    LD      A,10            ; Line Feed
            JR      SER_OUT
LF_DONE:    

            ; Print Sign-On character 'T' (Testing Initialising)
            LD      A,'T'
            JR      SER_OUT
SIGN_DONE:  

            ; Initialize RAM Scanner Address Register Tracking Pair
            LD      H,$00           ; Reset High Address byte parameter
            LD      L,$00           ; Reset Low Address byte parameter

; ------------------------------------------------------------------------------
; MASTER MEMORY EVALUATION LOOP
; ------------------------------------------------------------------------------
RAM_LOOP:   
            ; Check if we have hit a new page boundary (Low byte = $00)
            LD      A,L
            CP      $00
            JR      NZ,SWEEP_BYTE
            
            LD      A,'.'           ; Heartbeat indicator character token
            JR      SER_OUT
DOT_DONE:   

SWEEP_BYTE: 
            ; Test Pattern 1: Alternating Bit Checkerboard ($55 = 01010101)
            LD      B,(HL)          ; Preserve the original byte in register B
            LD      A,$55           ; Load test matrix pattern 1
            LD      (HL),A          ; Write directly to the physical RAM chip
            CP      (HL)            ; Verify the bit cells latched accurately
            JR      NZ,FAIL_TRAP    ; Mismatch found! RAM error triggered
            
            ; Test Pattern 2: Inverted Checkerboard ($AA = 10101010)
            LD      A,$AA           ; Load test matrix pattern 2
            LD      (HL),A          ; Write directly to the physical RAM chip
            CP      (HL)            ; Verify the bit cells flipped cleanly
            JR      NZ,FAIL_TRAP    ; Mismatch found! RAM error triggered
            
            LD      (HL),B          ; Restore the original byte back to RAM cell

            ; Increment scanner address workspace to target next cell location
            INC     HL              
            
            ; Check if the scanner has passed the 8KB motherboard limit ($1FFF)
            ; If H reaches $20 (High byte of $2000), motherboard RAM is complete.
            LD      A,H
            CP      $20             ; Check if High byte hits $20
            JR      NZ,RAM_LOOP     ; If not, keep sweeping motherboard RAM

            ; Total System Scan Pass successful! Print 'P' (Passed) and restart loop
            LD      A,'P'
            JR      SER_OUT
PASS_DONE:  JR      PON             ; Infinite loop diagnostic testing pass (To PON)

; ------------------------------------------------------------------------------
; DIAGNOSTIC FAILURE MONITOR EMISSION LOOP
; ------------------------------------------------------------------------------
FAIL_TRAP:  
            LD      A,'E'           ; Error flag indicator token
            JR      SER_OUT
ERR_DONE:   
            LD      A,H             ; Pull the bad address High Page byte
            JR      SER_OUT
HIGH_DONE:  
            LD      A,L             ; Pull the bad address Low Offset byte
            JR      SER_OUT
LOW_DONE:   
            JR      FAIL_TRAP       ; Repeat emission loop infinitely

; ------------------------------------------------------------------------------
; ZERO-STACK SERIAL OUTPUT INLINE DRIVER SUB-ROUTINE
; ------------------------------------------------------------------------------
SER_OUT:    
            LD      C,A             ; Cache output character value parameter inside C

TX_WAIT:    IN      A,(RSHS)        ; Read the serial handshake line port status
            AND     $01             ; Mask bit 0
            JR      Z,TX_WAIT       ; Spin if external terminal is busy
            
            IN      A,(RSS)         ; Pull internal UART flag parameters
            AND     $10             ; Test Transmitter Buffer Empty flag ($10)
            JR      Z,TX_WAIT       ; Spin if internal shift registers are full
            
            LD      A,C             ; Restore character value out of register cache
            OUT     (RSDO),A        ; Write data byte directly to serial transmit line $00

            ; ------------------------------------------------------------------
            ; STATE-DRIVEN RETURN VECTOR REDIRECTION ROUTER
            ; ------------------------------------------------------------------
            CP      'T'
            JR      Z,SIGN_DONE
            CP      '.'
            JR      Z,DOT_DONE
            CP      'P'
            JR      Z,PASS_DONE
            CP      'E'
            JR      Z,ERR_DONE
            CP      H               ; Was it the bad address high byte?
            JR      Z,HIGH_DONE
            CP      L               ; Was it the bad address low byte?
            JR      Z,LOW_DONE
            CP      13              ; Was it the Carriage Return initialization?
            JR      Z,CR_DONE
            CP      10              ; Was it the Line Feed initialization?
            JR      Z,LF_DONE
            
            JR      PON             ; Emergency escape hatch back to initialization
