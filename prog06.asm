TITLE Program 6    (proj06.asm)

; Author: Danny Tran
; Description: ?????????????????????????????????????? Designing low-level I/O procedures 
; Last Modified: 3/1/2020

INCLUDE Irvine32.inc
include macros.inc
BUFFERSIZE = 12
MAX_SINT = 80000000h

;getString should display a prompt, then get the user’s keyboard input into a memory location
getString MACRO prompt, string, bytesRead
	push	eax
	push	edx
	push	ecx

	displayString [prompt]  ;; ask user to enter input on keyboard
	mov		edx, string
	mov		ecx, bytesRead
	call	ReadString
	mov		bytesRead, eax
	pop		ecx
	pop		edx
	pop		eax
ENDM

;displayString should print the string which is stored in a specified memory location.
displayString MACRO string
	push	edx
	push	ecx

	mov		edx, string
	call	WriteString

	pop		ecx
	pop		edx
ENDM

; (insert constant definitions here)
.data
retInt				sdword	?
description0		byte	"Please provide 10 signed decimal integers. ", 0dh, 0ah, 0
description1		byte	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value. " , 0dh, 0ah, 0
errorUnsigned		byte	"You did not enter a signed number or your number caused carry/overflow.  ", 0dh, 0ah, 0
promptSign			byte	"Please enter a signed number:", 0dh, 0ah, 0
rePromptSign		byte	"Please try again:", 0dh, 0ah, 0
resultsMsg			byte	"You entered the following numbers: ", 0dh, 0ah, 0
sumMsg				byte	"The sum of these numbers is: ",  0
averageMsg			byte	"The rounded average is: ",  0
programIntro0		byte	0dh, 0ah,"--Program Intro--", 0dh, 0ah, 0
extraCredit			byte	"**EC: DESCRIPTION ", 0dh, 0ah, 0
extraCredit1		byte	" - Implement procedures ReadVal and WriteVal for floating point values, using the FPU. ", 0dh, 0ah, 0
.code
main PROC   

	call	intro

mov ecx, 100
l1:
	push ecx
	push	offset errorUnsigned ;+16
	push	offset promptSign   ;+12
	push	offset retInt		;+8
	call	readVal

	push	offset retInt
	call	writeVal
	call crlf
	pop ecx
loop l1
	exit	; exit to operating system
main ENDP

; (insert additional procedures here)
;-----------------------------------------------------
; readVal should invoke the getString macro to get the user’s string of digits.
; It should then convert the digit string to numeric, while validating the user’s input.
;-----------------------------------------------------
readVal PROC 
	local _char:byte, _sign:dword, _buffer[BUFFERSIZE]:byte, _bytesRead:dword, maxInt:qword
	
	jmp GetUserInput
	errorMsg:

		displayString	[ebp+16]	;display error msg

	; invoke the getString macro to get the user’s string of digits.
	GetUserInput:
		mov			_bytesRead, BUFFERSIZE	;bytesRead passes number of bytes to pass into ecx for ReadString, and recieves number of bytes read from EAX
		lea			esi, _buffer
		getString	ebp+12, esi, _bytesRead ;prompt argument , _buffer, _bytesRead
	
	pushad

	; initialize registers to 0 for conversionLoop label
	mov		ecx, _bytesRead	; set up conversion loop counter to 0
	xor		eax, eax	; eax is temp. variable to convert string to integer
	mov		_sign, 0	; init sign to 'false' indicating postive int	mwrite 'testing 2147483649'


	; check if 1st byte of string is '-' symbol
	mov		_char, "-"
	lea		edi, _char
	lea		esi, _buffer
	cmpsb
	jne checkPositiveSymbol	
	
	; string contains '-' symbol, increment loop count, set _sign to true and jump to loop  (without resetting esi)
	dec		ecx
	mov		_sign, 1
	jmp conversionLoop		

	; check if 1st byte of string is '+'  symbol
	checkPositiveSymbol:
		mov		_char, "+"
		lea		edi, _char
		lea		esi, _buffer		
		cmpsb
		jne noSymbol

	; string contains '+' symbol, increment loop count, and jump to loop (without resetting esi)
	dec		ecx	
	jmp conversionLoop	;jump to loop without resetting esi

	; if no symbols are found, reset esi. ecx and eax should be still 0
	noSymbol:		
		lea		esi, _buffer

	conversionLoop:			;convert the digit string to numeric		
		mov		ebx, 10 ;10 * a
		mul		ebx
		jc		errorMsg	; number is too big, carry flag set
		
		push	eax
		xor		eax,eax
		lodsb	;load character at esi in to eax

		; check if eax > 48 && eax < 57
		cmp		eax, 48	; zero 
		jl		errorMsg

		cmp		eax, 57 ; nine
		jg		errorMsg	

		sub		eax, 48 ;(x[i] - 48)
		pop		ebx
		add		eax, ebx	
		loop	conversionLoop
		
	; convert int into negative number based on _sign value
	cmp		_sign, 1
	jne		notNegative	; string does not contain '-' symbol
	neg		eax				; string contains '-' symbol
	cmp		eax, MAX_SINT	; check if number < 80000000h
	jo		errorMsg
	jmp		validNumber		; valid negative number

	notNegative:	; number is postive
		cmp		eax, MAX_SINT	; check if number > 80000000h 
		jns		errorMsg	

	validNumber:
 		mov		edi, [ebp+8] 	;store eax into retInt (ebp+8)
		stosd
		popad
	ret 12
readVal ENDP

; writeVal should convert a numeric value to a string of digits, 
; and invoke the displayString macro to produce the output
writeVal PROC
	local numDigits:byte
	mov		esi, [ebp + 8]
	mov		eax, [esi]
	call crlf
	call	writeint


		call dumpregs

	mov		numDigits, 0


	;displayString	


	ret 4
writeVal ENDP

intro PROC
	displayString	offset programIntro0
	displayString	offset extraCredit
	displayString	offset extraCredit1
	displayString	offset description0
	displayString	offset description1
ret
intro ENDP
END main