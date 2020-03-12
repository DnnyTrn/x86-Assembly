TITLE Program 6    (proj06.asm)

; Author: Danny Tran
; Description: Calculates the sum and average of ten signed integers
; Last Modified: 3/1/2020
; fix to pass by address	getString	ebp+12, esi, _bytesRead
; update functions to use constants

INCLUDE Irvine32.inc
include macros.inc
BUFFERSIZE = 13
MAX_SINT = 80000000h
NEGATIVE_SYMBOL = "-"
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
array				sdword	ARRAYSIZE DUP (1)
sum					sdword	?
average				sdword  ?
retString			byte	BUFFERSIZE DUP(?)
author              byte    "Author: Danny Tran " , 0dh, 0ah, 0 
programTitle        byte    "Title: Designing low-level I/O procedures ", 0dh, 0ah, 0
description0		byte	"Please provide 10 signed decimal integers. ", 0dh, 0ah, 0
description1		byte	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value. " , 0dh, 0ah, 0
errorUnsigned		byte	"You did not enter a signed number or your number caused carry/overflow. Please try again", 0dh, 0ah, 0
promptSign			byte	0dh, 0ah, "Please enter a signed number: ", 0
subTotalMsg			byte	"Subtotal: ", 0
resultsMsg			byte	0dh, 0ah, "You entered the following numbers: ", 0dh, 0ah, 0
sumMsg				byte	0dh, 0ah, "The sum of these numbers is: ",  0
averageMsg			byte	10, 13, "The rounded average is: ",  0
programIntro0		byte	0dh, 0ah,"--Program Intro--", 0dh, 0ah, 0
extraCredit			byte	"**EC: DESCRIPTION ", 0dh, 0ah, 0
extraCredit1		byte	"Number each line of user input and display a running subtotal of the users numbers.  ", 0dh, 0ah, 0
.code
main PROC   
	
			call dumpregs
		push	offset resultsMsg
	push	LENGTHOF array
	push	offset array
	call	displayList
	
	call dumpregs

	push	offset programIntro0
	push	offset extraCredit
	push	offset extraCredit1
	push	offset description0
	push	offset description1
	push	offset programTitle
	push	offset author
	call	intro 
			call dumpregs

	; get ten numbers from user, numbers are stored in array
	push	offset subTotalMsg
	push	offset errorUnsigned 
	push	offset promptSign  	
	push	LENGTHOF array
	push	offset array
	call	fillArray	
		call dumpregs

	; display numbers in array in a comma separated format
	push	offset resultsMsg
	push	LENGTHOF array
	push	offset array
	call	displayList
			 call dumpregs

	; calculate sum of 10 numbers, return sum 
	push	offset sumMsg
	push	offset sum
	push	LENGTHOF array
	push	offset array
	call	getSum
			call dumpregs

	; display message and sum
	displayString offset sumMsg
	push offset sum
	call writeVal
			call dumpregs

	; calculate average, return average
	push	offset average
	push	LENGTHOF array
	push	offset array
	call	getAverage
			call dumpregs

	; display message and average 
	displayString offset averageMsg
	push	offset average
	call	writeval

			call dumpregs

	exit	 
main ENDP

; (insert additional procedures here)
;-----------------------------------------------------
; readVal should invoke the getString macro to get the user’s string of digits.
; It should then convert the digit string to numeric, while validating the user’s input.
;-----------------------------------------------------
; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
readVal PROC USES EAX EBX ECX EDX EDI ESI, 
	_retInt:ptr sdword, _promptMsg:ptr byte, _errorMsg:ptr byte
	local _char:byte, _sign:dword, _buffer[BUFFERSIZE]:byte, _bytesRead:dword
	cld
	jmp GetUserInput
		errorMsg:		
		displayString _errorMsg

	; invoke the getString macro to get the user’s string of digits.
	GetUserInput:
		mov			_bytesRead, BUFFERSIZE	;bytesRead passes number of bytes to pass into ecx for ReadString, and recieves number of bytes read from EAX
		lea			esi, _buffer
		getString	_promptMsg, esi, _bytesRead 
	
	
	mov		ecx, _bytesRead	
	xor		eax, eax	
	mov		_sign, 0	

	; check if 1st byte of string is '-' symbol
	mov		_char, NEGATIVE_SYMBOL
	lea		edi, _char
	lea		esi, _buffer
	cmpsb
	jne		checkPositiveSymbol	
	
	; string contains '-' symbol
	dec		_bytesRead
	mov		ecx, _bytesRead	; set counter to n-1
	mov		_sign, 1
	mov		edi, esi	; save address +1
	jmp		ValidateString 		

	; check if 1st byte of string is '+'  symbol
	checkPositiveSymbol:
		mov		_char, "+"
		lea		edi, _char
		lea		esi, _buffer		
		cmpsb	
		jne		noSymbol

		; string contains '+' symbol
		dec		_bytesRead	
		mov		ecx, _bytesRead	; set counter to n-1
		mov		edi, esi	; save address +1
		jmp		ValidateString	

	; if no symbols are found, scan string from beginning, validate string for non-integer characters
	noSymbol:		
		lea		esi, _buffer
		mov		edi, esi	; save address
		xor		eax, eax	

	ValidateString:
		lodsb
		cmp		eax, 39h	; greater than '9'
		jg		errorMsg

		cmp		eax, 30h	; less than '0'
		jl		errorMsg
		loop	ValidateString

			
	; convert the digit string to numeric		
	mov		esi, edi
	xor		eax, eax	; eax is temp. variable to convert string to integer
	mov		ecx, _bytesRead
	conversionLoop:			
		mov		ebx, 10 ;10 * a
		mul		ebx
		jc		errorMsg	; number is too big, carry flag set
		
		push	eax	; save first term
		xor		eax,eax	; reset register to load byte
		lodsb	; load character at esi in to eax
		sub		eax, 30h ;(x[i] - 48)
		pop		ebx
		add		eax, ebx	; a = 10 * a + (x[i] - 48);
		loop	conversionLoop
	
	; if string contains '-', negate number and check sign flag is true
	cmp		_sign, 1
	jne		notNegative		; string does not contain '-' symbol
	neg		eax				
	test	eax, eax
	jns		errorMsg
	jmp		validNumber		; valid negative number

	notNegative:	; number is postive
		test	eax, eax
		js		errorMsg
		
	validNumber:
		mov		edi, _retInt 	
		stosd ;		;store eax into retInt (ebp+8)

	ret
readVal ENDP
	
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
; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
fillArray	PROC USES EAX ECX ESI,
	_array:ptr byte, _arraySize:dword, promptMsg:ptr byte, errorMsg:ptr byte, _subTotalMsg: ptr byte
	local	_runningSubTotal:dword
	mov		_runningSubTotal, 30h	; init subtotal to 0
	
	mov		esi, _array	
	mov		ecx, _arraySize; array size
	
	; use readVal to get user integer and put in array
	fillArrayLoop:
		push	errorMsg ; error message
		push	promptMsg ; prompt message
		push	esi ; array
		call	readVal
		inc		_runningSubTotal
		displayString _subTotalMsg

		lea		eax, _runningSubTotal
		displayString	eax

		add		esi, type _array
		loop	fillArrayLoop
		
	ret		
fillArray	ENDP

; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
displayList	PROC USES  ecx edx esi,
	_array:ptr sdword, _arraysize:dword, _title:ptr byte
	local comma:dword
	mov comma, 0000202Ch ; comma and space hex values

	displayString _title ; You entered the following numbers: 
	mov esi, _array
	mov	ecx, _arraysize

	printNumber:
		push esi
		call writeVal
		add esi, TYPE _array
		
		cmp ecx, 1			; end loop after printing number
		je endDisplayList

		lea edx, comma
		displayString edx
		
;		lea edx, space
;		displayString edx
		loop printNumber
	endDisplayList:
		
	ret		12
displayList	ENDP

; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
getAverage PROC USES EAX ECX ESI EDI,
	_array:ptr sdword, _length:dword, _avg:ptr sdword
	local _sum:sdword
	   
	; get sum from array
	lea		edi, _sum
	push	edi
	push	_length
	push	_array
	call	getSum

	; check if sum is sign
	cdq
	mov		eax, _sum
	test	eax, eax
	jns		calculateAverage

	; convert sum to negative
	neg		eax
	mov		ebx, -1
	imul	ebx
	
	; calculate average
	calculateAverage:	
	mov		ebx, _length
	idiv	ebx

	; return average
	mov		edi, _avg
	stosd			
	

ret	
getAverage ENDP

; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
getSum	PROC USES EAX ECX ESI EDI,
	_array:ptr sdword, _length:dword, _sum:ptr sdword

	; calculate sum (eax)
	mov  esi, _array
	mov ecx, _length
	xor eax, eax
		
	Accumulator:		
		add eax, [esi]
		add esi, TYPE _array
	loop Accumulator
	
	; check if sum is too big

	; return sum
	mov edi, _sum
	stosd

	
	ret	
getSum	ENDP

; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
; writeVal should convert a numeric value to a string of digits, 
; and invoke the displayString macro to produce the output
writeVal PROC USES EAX EBX ECX EDX EDI ESI,
	_integer:ptr sdword
	local _string[BUFFERSIZE]:byte
	
	; empty _string
	push	LENGTHOF _string
	lea		edi, _string
	push	edi
	call	clearArray	

	; check if number is signed
	mov		esi, _integer
	lodsd	; load integer (esi to eax)
	xor	    ecx, ecx  ; number counter	
	test	eax, eax
	jns		NumberToAscii
	inc		ecx
	neg		eax
	
	;notSign:
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
		jnz  	NumberToAscii		
	
	; push '-' if _integer is signed
	mov		esi, _integer
	mov		eax, [esi]	
	test	eax, eax
	jns		NoSymbol

	mov		eax, NEGATIVE_SYMBOL
	push	eax

	; pop ascii numbers to _string array
	NoSymbol:
		lea		edi, _string
		cld
	AsciiToString:
		pop		eax
		stosb	;eax to edi
		loop	AsciiToString
	
	; display string 
	lea		edi, _string
	displayString	edi
		
	ret		
writeVal ENDP
; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
clearArray	PROC USES EAX EDX EDI,
	_array:ptr byte, _arraySize:dword
	xor		eax, eax
	mov		ecx, _arraySize
	mov		edi, _array
	cld
	rep		stosb
	ret		
clearArray	ENDP

; ***************************************************************
; Procedure to display program description, 
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100
; registers changed: eax, ebx, ecx, edi
; ***************************************************************
intro PROC	uses EDX,
	_author:ptr byte, _title:ptr byte, _string1:ptr byte, _string2:ptr byte, _string3:ptr byte, _string4:ptr byte, _string5:ptr byte
	displayString	_author
	displayString	_title
	displayString	_string1
	displayString	_string2
	displayString	_string3
	displayString	_string4
	displayString	_string5
	ret
intro ENDP
END main