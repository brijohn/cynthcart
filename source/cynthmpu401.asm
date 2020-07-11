; public MIDI interface routines:
; midiDetect
; midiInit
; midiRead
; midiWrite

	processor 6502

BUFFER_SIZE_MASK equ #$FF

MIDIDATA equ $df00            ; MPU-401 Data Port
MIDISTAT equ $df01            ; MPU-401 Status Port
MIDICMD  equ $df01            ; MPU-401 Command Port

	MAC waitDDR
.wait:
	lda MIDISTAT
	and #$40
	bne .wait
	ENDM

; No detection. This file specifically implements mpu 401 support
midiDetect:
	lda #0
	sta mpuStatus
	lda MIDISTAT
	cmp #$FF
	beq noMidi
	and #$c0
	cmp #$80
	bne noMidi
	lda mpuStatus
	ora #1
	sta mpuStatus
	lda #$5
	rts
noMidi:
	lda #0
	rts


midiInit:

	; clear ringbuffer
	lda #0
	sta midiRingbufferReadIndex
	sta midiRingbufferWriteIndex

	lda mpuStatus
	and #01
	beq notInstalled
	; Set IRQ routine
	sei
	lda #<midiIrq
	sta $0314
	lda #>midiIrq
	sta $0315
	cli
	lda #$FF ; MPU Reset
	jsr midiCmd
	lda #$3F ; MPU UART Mode
	jsr midiCmd

notInstalled:
	rts

midiRelease:
	lda mpuStatus
	and #01
	beq notInstalled
	lda #$FF ; Send MPU reset
	jsr midiCmd
	sei
	lda #$31
	sta $0314
	lda #$ea
	sta $0315
	cli
	rts

midiCmd:
	tax
	waitDDR
	txa
	sta MIDICMD
waitForAck:
	bit mpuStatus
	bvs setFlags
	bpl waitForAck
setFlags:
	cmp #$ff
	beq clearUart
	cmp #$3f
	bne cmdDone
	lda mpuStatus
	ora #$40
	sta mpuStatus
	jmp cmdDone
clearUart:
	lda mpuStatus
	and #$bf
	sta mpuStatus
cmdDone:
	lda mpuStatus
	and #$7f
	sta mpuStatus
	rts

midiWrite:
	rts

; read MIDI byte from ringbuffer
midiRead:
	ldx midiRingbufferReadIndex ; if the read and write pointers are different...
	cpx midiRingbufferWriteIndex
	bne processMidi  ; Slocum: modified to not wait for data...
	rts ; No new data, so return

; wait for MIDI byte and read it from ringbuffer
midiReadWait:
	ldx midiRingbufferReadIndex ; if the read and write pointers are different...
	cpx midiRingbufferWriteIndex
	bne processMidi  ; Slocum: modified to not wait for data...
	jmp midiReadWait

processMidi:
	lda midiRingbuffer,x
	tay ; save next byte into y
	inx ; increment buffer pointer...
	txa
	and #BUFFER_SIZE_MASK
	sta midiRingbufferReadIndex ; save it
	tya ; the byte read from the buffer ends up in both y and a
	rts

midiIrq:
	lda MIDISTAT
	bmi midiIrqDone
	lda MIDIDATA
	jsr midiStore
midiIrqDone:
	lda $dc0d
	pla
	tay
	pla
	tax
	pla
	rti

; get MIDI byte and store in ringbuffer
midiStore:
	cmp #$FE
	bne midiStoreByte
	lda mpuStatus
	ora #$80
	sta mpuStatus
	rts
midiStoreByte:
	ldx midiRingbufferWriteIndex
	sta midiRingbuffer,x
	inx
	txa
	and #BUFFER_SIZE_MASK
	sta midiRingbufferWriteIndex
	rts

