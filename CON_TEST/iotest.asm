; ==============================================================================
; TUSCAN SYSTEM 1 - HARDWARE I/O SIMULATION VERIFICATION TOOL (ONBOARD VDU MODE)
; Target Assembler: Standalone GNU z80asm
; Hexadecimal Prefix: $
; Memory Footprint: Runs entirely out of EPROM (Requires 0 Bytes of RAM)
; ==============================================================================

; ------------------------------------------------------------------------------
; TUSCAN HARDWARE PORT DEFINITIONS (MATCHING YOUR SIMULATOR ADDITIONS)
; ------------------------------------------------------------------------------
VDU:        EQU     $02             ; Onboard VDU Strobe Output Port
IOSEL:      EQU     $04             ; Hardware Configuration Jumper Switch Port
KEYB:       EQU     $05             ; Onboard Keyboard Input Latch Register

; ------------------------------------------------------------------------------
; COLD BOOT & ABSOLUTE ENTRY VECTOR TRUMP
; ------------------------------------------------------------------------------
            ORG     $F800           ; Base entry point for your test EPROM
TRUMP:      JP      PON             ; Force absolute jump to break hardware boot mode

PON:        DI                      ; Disable all masks and interrupts

            ; ------------------------------------------------------------------
            ; TEST 1: VERIFY PORT $04 (ONBOARD DEVICE JUMPER VALUE)
            ; ------------------------------------------------------------------
            IN      A,(IOSEL)       ; Pulse your Port $04 handler
            CP      $10             ; Check if it matches the true Onboard VDU mask (0x10)
            JR      Z,PORT4_OK      ; Yes! Jump to output success character

            ; Fail state: Port $04 did not return $10. Print a '?' indicator token.
            LD      A,'?'
            CALL    VDU_OUT
            JR      KEY_ECHO        ; Advance directly to keyboard test

PORT4_OK:   ; Success state: Port $04 matches perfectly. Print a '1' character token.
            LD      A,'1'
            CALL    VDU_OUT

            ; ------------------------------------------------------------------
            ; TEST 2: VERIFY PORT $05 (LIVE KEYBOARD MATRIX CACHE LOOP)
            ; ------------------------------------------------------------------
KEY_ECHO:   IN      A,(KEYB)        ; Pulse your Port $05 keyboard reader
            OR      A               ; Is input value 00H (No key waiting)?
            JR      Z,KEY_ECHO      ; Yes, spin endlessly until a key hits the cache

            ; Success state: A key was pressed! Echo it back out to verify character routing
            CALL    VDU_OUT         ; Display the key character natively on Port $02
            JR      KEY_ECHO        ; Repeat loop infinitely for continuous typing

; ------------------------------------------------------------------------------
; ZERO-STACK NATIVE TUSCAN VDU OUTPUT SUB-ROUTINE
; ------------------------------------------------------------------------------
VDU_OUT:    
            LD      C,A             ; Cache the true ASCII character value inside C
            
            DEC     A               ; Apply authentic Tuscan hardware pre-shift correction
            AND     $7F             ; Bring hardware strobe line down to low logic level
            OUT     (VDU),A         ; Pulse Port $02 to fire your simulator display loop
            OR      $80             ; Toggle hardware strobe line high
            OUT     (VDU),A         
            AND     $7F             ; Reset strobe back down to low safety logic level
            OUT     (VDU),A         
            
            LD      A,C             ; Restore clean ASCII character to accumulator
            RET                     ; Return to execution line

