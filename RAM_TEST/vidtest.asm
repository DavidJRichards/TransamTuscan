; ==============================================================================
; TUSCAN SYSTEM 1 - ZERO-RAM VIDEO TERMINAL DIAGNOSTIC (VIDEO VERSION)
; Target Assembler: Standalone GNU z80asm
; Hexadecimal Prefix: $
; Memory Footprint: Runs entirely out of EPROM (Requires 0 Bytes of RAM)
; Strict 8KB Motherboard Bound Check Included.
; ==============================================================================

; ------------------------------------------------------------------------------
; HARDWARE PORT ASSIGNMENTS (MATCHING TUSCAN DISPLAY INTERFACE SPECIFICATION)
; ------------------------------------------------------------------------------
VDU:        EQU     $02             ; Onboard VDU Strobe Port

; ------------------------------------------------------------------------------
; MONITOR COLD BOOT & SYSTEM INITIALIZATION
; ------------------------------------------------------------------------------
            ORG     $F800           ; Base entry point for your test EPROM
TRUMP:      JP      PON             ; Force absolute jump to break hardware boot mode

PON:        DI                      ; Disable all masks and interrupts
            
            ; Output an initial clear/form feed command to settle display hardware
            LD      A,$0C           ; ASCII Form Feed (FF / Clear Screen)
            JR      VDU_OUT
FF_DONE:    

            ; Print Sign-On character 'V' (Video Testing Initialising)
            LD      A,'V'
            JR      VDU_OUT
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
            JR      VDU_OUT
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

            ; Total 8KB Motherboard Scan Pass successful! Print 'P' and restart
            LD      A,'P'
            JR      VDU_OUT
PASS_DONE:  JR      PON             ; Infinite loop diagnostic testing pass (To PON)

; ------------------------------------------------------------------------------
; DIAGNOSTIC FAILURE MONITOR EMISSION LOOP
; ------------------------------------------------------------------------------
FAIL_TRAP:  
            LD      A,'E'           ; Error flag indicator token
            JR      VDU_OUT
ERR_DONE:   
            LD      A,H             ; Pull the bad address High Page byte
            JR      VDU_OUT
HIGH_DONE:  
            LD      A,L             ; Pull the bad address Low Offset byte
            JR      VDU_OUT
LOW_DONE:   
            JR      FAIL_TRAP       ; Repeat emission loop infinitely

; ------------------------------------------------------------------------------
; ZERO-STACK VIDEO TERMINAL OUTPUT INLINE DRIVER SUB-ROUTINE
; ------------------------------------------------------------------------------
VDU_OUT:    
            DEC     A               ; Match the monitor's physical driver baseline
            AND     $7F             ; Bring hardware strobe line low
            OUT     (VDU),A         ; Pulse Port $02
            OR      $80             ; Pull strobe line high
            OUT     (VDU),A         
            AND     $7F             ; Clear strobe back down to low safety logic level
            OUT     (VDU),A         
            INC     A               ; Restore true ASCII byte into accumulator
            
            ; Delay padding to protect legacy video controllers from overrun crashes
            LD      E,120           ; Load timing loop parameter
VDU_PAD:    DEC     E
            JR      NZ,VDU_PAD

            ; ------------------------------------------------------------------
            ; STATE-DRIVEN RETURN VECTOR REDIRECTION ROUTER
            ; ------------------------------------------------------------------
            CP      'V'
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
            CP      $0C             ; Was it the form feed initialization?
            JR      Z,FF_DONE
            
            JR      PON             ; Emergency escape hatch back to initialization
