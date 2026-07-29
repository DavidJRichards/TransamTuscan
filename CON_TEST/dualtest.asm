; ==============================================================================
; TUSCAN SYSTEM 1 - DUAL-MODE HARDWARE I/O PORT VERIFICATION TOOL
; Target Assembler: Standalone GNU z80asm
; Hexadecimal Prefix: $
; Memory Footprint: Runs entirely out of EPROM (Requires 0 Bytes of RAM)
; Dynamic on-the-fly switching between Serial and Local VDU hardware profiles.
; ==============================================================================

; ------------------------------------------------------------------------------
; TUSCAN SYSTEM I/O REGISTER MAPPINGS
; ------------------------------------------------------------------------------
RSS:        EQU     $00             ; RS232 UART Status Input Port
RSDO:       EQU     $00             ; RS232 Data Output Port
RSDI:       EQU     $01             ; RS232 Data Input Port
VDU:        EQU     $02             ; Onboard VDU Strobe Output Port
IOSEL:      EQU     $04             ; Hardware Configuration Jumper Input Port
KEYB:       EQU     $05             ; Onboard Keyboard Latch Register
RSHS:       EQU     $06             ; RS232 Handshake Evaluation Pin

; ------------------------------------------------------------------------------
; START OF DIAGNOSTIC CODE SPACE
; ------------------------------------------------------------------------------
            ORG     $F800           ; Base entry point for your test EPROM
TRUMP:      JP      PON             ; Force absolute jump to break hardware boot mode

PON:        DI                      ; Disable all masks and interrupts

; ------------------------------------------------------------------------------
; MASTER DUAL-ROUTE EVALUATION DISPATCH LOOP
; ------------------------------------------------------------------------------
POLL_RIG:
            IN      A,(IOSEL)       ; Sample your custom Port $04 switcher register
            AND     $30             ; Mask bits 4 and 5 exactly like the stock ROM
            JR      Z,DO_SERIAL     ; If 00, route execution straight to Serial Mode

            ; ------------------------------------------------------------------
            ; ONBOARD VDU MODE INPUT & STROBE ROUTING
            ; ------------------------------------------------------------------
            IN      A,(KEYB)        ; Sample your Port $05 keyboard reader
            AND     A               ; Test the Z80 sign flag metrics
            JP      P,POLL_RIG      ; If Bit 7 is 0, cache is empty. Loop back.

            ; Key found! Process and echo it via VDU Out (Port $02)
            AND     $7F             ; Strip top bit to isolate clean 7-bit ASCII
            CALL    LOCAL_VDU       ; Display natively on the VDU port
            JR      POLL_RIG        ; Loop back to scan again

            ; ------------------------------------------------------------------
            ; SERIAL RS232 MODE INPUT & OUTPUT ROUTING
            ; ------------------------------------------------------------------
DO_SERIAL:
            IN      A,(RSS)         ; Sample your Port $00 UART Status register
            AND     $01             ; Test Bit 0 (Data Available)
            JR      Z,POLL_RIG      ; If 0, no key is waiting. Loop back.

            IN      A,(RSDI)        ; Key found! Pull the clean byte from Port $01
            AND     $7F             ; Normalize to 7-bit ASCII
            CALL    REMOTE_SER      ; Transmit natively via the Serial ports
            JR      POLL_RIG        ; Loop back to scan again

; ------------------------------------------------------------------------------
; ONBOARD VDU OUTPUT SUB-ROUTINE (PORT $02 DRIVER - PRE-SHIFTED & EDGE-TRIGGERED)
; ------------------------------------------------------------------------------
LOCAL_VDU:
            PUSH    AF              ; Preserve character on the stack
            DEC     A               ; Apply Tuscan hardware pre-shift correction
            AND     $7F             ; Force Bit 7 LOW (Strobe Low)
            OUT     (VDU),A         ; 1st strobe step
            OR      $80             ; Toggle Bit 7 HIGH (Strobe High - Latch Trigger)
            OUT     (VDU),A         ; 2nd strobe step
            AND     $7F             ; Force Bit 7 LOW (Strobe Low Reset)
            OUT     (VDU),A         ; 3rd strobe step
            POP     AF              ; Restore character
            RET

; ------------------------------------------------------------------------------
; SERIAL RS232 OUTPUT SUB-ROUTINE (PORT $00 DRIVER - RAW & HANDSHAKED)
; ------------------------------------------------------------------------------
REMOTE_SER:
            PUSH    AF              ; Save character code
            LD      B,A             ; Cache data byte in register B

SER_WAIT:   IN      A,(RSHS)        ; Read the serial handshake pin on Port $06
            AND     $01             ; Test Bit 0 (Clear to Send status flag)
            JR      Z,SER_WAIT      ; Spin here while the line is blocked

            IN      A,(RSS)         ; Read the UART status register on Port $00
            AND     $10             ; Test Bit 4 (Transmitter Buffer Empty)
            JR      Z,SER_WAIT      ; Spin here while the transmit register is busy

            LD      A,B             ; Restore character from cache register
            OUT     (RSDO),A        ; Output raw unshifted ASCII straight to Port $00
            POP     AF              ; Clean up stack
            RET

