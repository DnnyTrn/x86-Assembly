TITLE Program 6    (proj06.asm)

; Author: Danny Tran
; Description: ?????????????????????????????????????? Designing low-level I/O procedures 
; Last Modified: 3/1/2020
; fix to pass by address	getString	ebp+12, esi, _bytesRead
; update functions to use constants

INCLUDE Irvine32.inc
include macros.inc
BUFFERSIZE = 12
MAX_SINT = 80000000h
NEGATIVE_SYMBOL = "-"
POSITIVE_SYMBOL = "+"
ARRAYSIZE = 10
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

	mov		edx, string
	call	WriteString

	pop		edx
ENDM

; (insert constant definitions here)
.data
array				sdword	ARRAYSIZE DUP(1)
retInt				sdword	?
sum					sdword	?
average				sdword  ?
retString			byte	BUFFERSIZE DUP(?)
description0		byte	"Please provide 10 signed decimal integers. ", 0dh, 0ah, 0
description1		byte	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value. " , 0dh, 0ah, 0
errorUnsigned		byte	"You did not enter a signed number or your number caused carry/overflow. Please try again", 0dh, 0ah, 0
promptSign			byte	0dh, 0ah, "Please enter a signed number: ", 0
;rePromptSign		byte	"Please try again:", 0dh, 0ah, 0
subTotalMsg			byte	"Subtotal: ", 0
resultsMsg			byte	0dh, 0ah, "You entered the following numbers: ", 0dh, 0ah, 0
sumMsg				byte	0dh, 0ah, "The sum of these numbers is: ",  0
averageMsg			byte	"The rounded average is: ",  0
programIntro0		byte	0dh, 0ah,"--Program Intro--", 0dh, 0ah, 0
extraCredit			byte	"**EC: DESCRIPTION ", 0dh, 0ah, 0
extraCredit1		byte	"Number each line of user input and display a running subtotal of the users numbers.  ", 0dh, 0ah, 0
.code
main PROC   
	push 12
	push 8
	call tester
	call	intro ; fix this low prio
	comment *
	mov ecx, 100
	l1:

	push	offset errorUnsigned 
	push	offset promptSign  
	push	offset retInt		
	call	readVal

	push	offset retInt
	call	writeVal
	loop l1
	*
	
	push	offset sumMsg
	push	offset sum
	push	LENGTHOF array
	push	offset array
	call	getSum
	
	; get ten numbers from user, numbers are stored in array
	push	offset subTotalMsg
	push	offset errorUnsigned 
	push	offset promptSign  	
	push	LENGTHOF array
	push	offset array
	call	fillArray	
	
	; display numbers in array in a comma separated format
	push	offset resultsMsg
	push	LENGTHOF array
	push	offset array
	call	displayList

	push	offset sumMsg
	push	offset sum
	push	LENGTHOF array
	push	offset array
	call	getSum
	;push	LENGTHOF retString
	;push	offset retString
	;call	clearArray



	
	exit	 
main ENDP

; (insert additional procedures here)

tester PROC uses eax ebx, 
	p1: dword, p2: dword 
	local a:dword, b:dword
PARAMS = 2
LOCALS = 2
SAVED_REGS = 2
mov a,0AAAAh
mov b,0BBBBh
INVOKE WriteStackFrame, PARAMS, LOCALS, SAVED_REGS
ret
tester endp

; fillArray - takes an array, and array size to fill array with user-generated signed integers
fillArray	PROC USES EAX ECX ESI,
	_array:ptr byte, _arraySize:dword, promptMsg:ptr byte, errorMsg:ptr byte
	local	_runningSubTotal:dword
	mov		_runningSubTotal, 0
	
	mov		esi, _array	
	mov		ecx, _arraySize; array size
	
	; use readVal to get user integer and put in array
	fillArrayLoop:
		push	errorMsg ; error message
		push	promptMsg ; prompt message
		push	esi ; array
		call	readVal
		inc		_runningSubTotal
		displayString [ebp+24]

		mov		eax, _runningSubTotal
		call	WriteDec

		add		esi, type sdword
		loop	fillArrayLoop
		
	ret		20
fillArray	ENDP

displayList	PROC USES ECX EDX
	local _arrayType:dword
	
	displayString [ebp+16] ; You entered the following numbers: 
	mov edx, [ebp+8]
	mov _arrayType, TYPE edx
	mov	ecx, [ebp + 12]

	printNumber:
		push edx
		call writeVal
		add edx, _arrayType
		
		cmp ecx, 1			; end loop after printing number
		je endDisplayList

		mov al, ","
		call writechar
		mov  al, " "
		call writechar

		loop printNumber
	endDisplayList:
		
	ret		12
displayList	ENDP

getSum	PROC USES EAX ECX EDX EDI ESI 
	local _sum:dword

	mov  esi, [ebp + 8]
	mov ecx, [ebp + 12]
	xor eax, eax
	Accumulator:		
		add eax, [esi]
		add esi, TYPE esi
	loop Accumulator

	displayString [ebp + 20]
	call writeint

	ret	16
getSum	ENDP
;-----------------------------------------------------
; readVal should invoke the getString macro to get the user’s string of digits.
; It should then convert the digit string to numeric, while validating the user’s input.
;-----------------------------------------------------
readVal PROC USES EAX EBX ECX EDX EDI ESI,
	_retInt:ptr sdword, _promptMsg:ptr byte, _errorMsg:ptr byte
	local _char:byte, _sign:dword, _buffer[BUFFERSIZE]:byte, _bytesRead:dword
	
	jmp GetUserInput
	
	errorMsgAlpha:		;user entered a non-numeric input
		add		esp, 4 ; release invalid integer

	errorMsgCarry:		;overflow/carry error
		displayString _errorMsg

	; invoke the getString macro to get the user’s string of digits.
	GetUserInput:
		mov			_bytesRead, BUFFERSIZE	;bytesRead passes number of bytes to pass into ecx for ReadString, and recieves number of bytes read from EAX
		lea			esi, _buffer
		;getString	ebp+12, esi, _bytesRead ;prompt argument , _buffer, _bytesRead
		getString	_promptMsg, esi, _bytesRead ;prompt argument , _buffer, _bytesRead
	
	; initialize registers to 0 for conversionLoop label
	mov		ecx, _bytesRead	; set up conversion loop counter to 0
	xor		eax, eax	; eax is temp. variable to convert string to integer
	mov		_sign, 0	; init sign to 'false' indicating postive int	mwrite 'testing 2147483649'

	; check if 1st byte of string is '-' symbol
	mov		_char, NEGATIVE_SYMBOL
	lea		edi, _char
	lea		esi, _buffer
	cmpsb
	jne		checkPositiveSymbol	
	
	; string contains '-' symbol, increment loop count, set _sign to true and jump to loop  (without resetting esi)
	dec		ecx
	mov		_sign, 1
	jmp		conversionLoop		

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
		jc		errorMsgCarry	; number is too big, carry flag set
		
		push	eax
		xor		eax,eax
		lodsb	;load character at esi in to eax

		; check if eax > 48 && eax < 57
		cmp		eax, 48	; zero 
		jl		errorMsgAlpha

		cmp		eax, 57 ; nine
		jg		errorMsgAlpha	

		sub		eax, 48 ;(x[i] - 48)
		pop		ebx
		add		eax, ebx	
		loop	conversionLoop
		
	; convert int into negative number based on _sign value
	cmp		_sign, 1
	jne		notNegative	; string does not contain '-' symbol
	neg		eax				; string contains '-' symbol
	test	eax, eax
	jns		errorMsgCarry
	;cmp		eax, MAX_SINT	; check if number < 80000000h
	;jo		errorMsg
	jmp		validNumber		; valid negative number

	notNegative:	; number is postive
		test	eax, eax
		js		errorMsgCarry


	validNumber:
		mov		edi, _retInt 	
		stosd ;		;store eax into retInt (ebp+8)

	ret 
readVal ENDP

; writeVal should convert a numeric value to a string of digits, 
; and invoke the displayString macro to produce the output
writeVal PROC USES EAX EBX ECX EDX EDI ESI
	local _string[BUFFERSIZE]:byte

	push LENGTHOF _string
	lea		edi, _string
	push  edi
	call clearArray	;empty _string

	mov		esi, [ebp+8]
	;mov		eax, [esi]	
	cld
	lodsd	; load integer (esi to eax)
	xor	    ecx, ecx  ; number counter
	; check if number is signed
	test	eax, eax
	jns		notSign
	inc		ecx
	neg		eax
	
	notSign:
	; convert number to ascii
	;mov		eax, [esi]	
	
	;lodsd	; load integer (esi to eax)
	; mov eax, [ebp + 8] ; dividend contains next integer to convert
	NumberToAscii:
		mov		ebx, 10		; divide integer by 10, to use remainder
		mov		edx, 0 
		div		ebx			; add 48 to remainder to convert to ascii
		add		edx, 48
		push	edx			; save converted number
		inc		ecx			; increase counter
		test	eax, eax
		jnz  		NumberToAscii		
	
	;loop NumberToAscii	
	mov		esi, [ebp+8]
	mov		eax, [esi]	
	test	eax, eax

	jns		NoSymbol
	mov		eax, NEGATIVE_SYMBOL
	push	eax

	NoSymbol:
	; move ascii number to string array
	lea		edi, _string
	AsciiToString:
	pop		eax
	stosb	;eax to edi
	loop	AsciiToString
	
	lea		edi, _string
	displayString	edi
		
	ret		4
writeVal ENDP

clearArray	PROC USES EAX EDX EDI EBP
	mov		ebp, esp
	xor		eax, eax
	mov		ecx, [ebp + 24]
	mov		edi, [ebp + 20]
	cld
	rep		stosb
	ret		8
clearArray	ENDP
intro PROC
	displayString	offset programIntro0
	displayString	offset extraCredit
	displayString	offset extraCredit1
	displayString	offset description0
	displayString	offset description1
	ret
intro ENDP
END main