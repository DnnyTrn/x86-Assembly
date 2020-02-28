TITLE Project 05    (proj05.asm)

; Author: Danny Tran
; Last Modified: 2/27/2020
; OSU email address: trandan@oregonstate.edu
; Course number/section: COMPUTER ARCH & ASSEM LANGUAGE (CS_271_C400_W2020)
; Project Number: 5                Due Date: 3/1/2020
; Description:  

INCLUDE Irvine32.inc

; (insert constant definitions here)
LO = 10
HI = 29
ARRAYSIZE = 200
COUNTSIZE = 20
BUFFERSIZE = 200

.data
; (insert variable definitions here) 
array               dword   ARRAYSIZE DUP(?)
counts              dword   30 DUP(0)
author              byte    "Author: Danny Tran " , 0dh, 0ah, 0 
programTitle        byte    "Title: Sorting and Counting Random integers! ", 0dh, 0ah, 0
instructions0       byte    "This program generates 200 random numbers in the range [10 ... 29], displays the original list, sorts the list, displays the median value, displays the list sorted in ascending order, then displays the number of instances of each generated value.", 0
terminatingMsg      byte    "End of program goodbye ", 0
error0              byte    "Out of range. Enter a number in [1 .. 400] ", 0dh, 0ah, 0
unsortListTitle     byte    0dh, 0ah,"Your unsorted random numbers:", 0dh, 0ah, 0
sortedListTitle     byte    0dh, 0ah,"Your sorted random numbers:", 0dh, 0ah, 0
countListTitle      byte    0dh, 0ah,"Your list of instances of each generated number, starting with the number of 10s:", 0dh, 0ah, 0
medianTitle         BYTE    0dh, 0ah,"List Median: ",0
filename            BYTE    "randonumbers.bin",0
buffer              dword   BUFFERSIZE DUP(0)
fileHandle          HANDLE  ?

.code
main PROC   
    call intro  ;Display your name and program title on the output screen.    
    call displayInstructions ;  inform user program instructions

    call randomize  ;call randomize before calling fillArray or fillArrayToFile

    push offset buffer
    push offset filename   
    push offset fileHandle      ;+24
    push  ARRAYSIZE ;+20
    push  LO ;+16
    push   HI ;+12
    push OFFSET array ;+8
    call fillArrayToFile
    
    push OFFSET array 
    push ARRAYSIZE 
    push OFFSET unsortListTitle
    call displayList   
  
    push OFFSET array  ;20 
    push ARRAYSIZE  ;16
    push OFFSET counts ;12
    push COUNTSIZE ;8
    call countList

    push OFFSET counts
    push COUNTSIZE  ;first 20 elements in counts
    push offset countListTitle
    call displayList

    push HI
    push LO
    push OFFSET array
    push OFFSET counts 
    call sortList

    mov edx, OFFSET medianTitle
    call writestring

    push offset array
    push ARRAYSIZE
    call displayMedian

    push OFFSET array 
    push ARRAYSIZE 
    push OFFSET sortedListTitle
    call displayList

    call displayFarewell ; Display a terminating message. 

    exit    ; exit to operating system
main ENDP

; (insert additional procedures here)
; ***************************************************************
; Generate ARRAYSIZE random integers in the range [LO = 10 .. HI = 29], 
;   storing them in consecutive elements of an array. ARRAYSIZE should be set to 200.

    ;Generate the numbers into a file;  
    ;then read the file into the array. (3pts)
; receives:  fileName, file handle,  array to fill, array size,
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100; registers changed: eax, ebx, ecx, edi
; ***************************************************************
fillArrayToFile PROC
    push ebp
    mov ebp, esp
    mov edi, [ebp + 24] ;file handle offset

    ;create outputfile using filename
    mov edx,  [ebp + 28] ;filename offset
    call CreateOutputFile

    mov [edi], eax ; store file handle 
    cmp eax, INVALID_HANDLE_VALUE ;if return value is equal to INVALID_HANDLE_VALUE then print error message
    je errorMsg      

    ;fill buffer with random numbers using fillArray function
    pushad
    push  [ebp + 20] ; arraysize to generate arraysize numbers
    push  [ebp + 16] ; LO value 16
    push  [ebp + 12]  ; HI value 29
    push  [ebp + 32]  ; buffer offset
    call fillArray
    popad

    ;write buffer to file using WriteToFile function
    mov eax, [ebp + 20] ;set up number of bytes by multiplying type dword and arraysize
    mov ebx, type dword
    mul ebx 
    mov ecx, eax    ; 800 bytes to write to file (param1)
    mov ebx, ecx    ; save value for readfromfile function
    mov eax, [edi]  ; file handle (param2)
    mov edx, [ebp + 32] ; buffer offset   (param3)      
    call WriteToFile ;write 800 bytes from buffer to file using the file handle
       
    mov eax, [edi]  ; close file using file handle offset in edi
    call CloseFile

    ;After writing to randonumbers.bin, call OpenInputFile to begin reading from it
    mov edx, [ebp + 28]     ;filename param for openinputfile
    call OpenInputFile      ;requires name of file offset in edx

    mov [edi], eax                ;return value is file handle stored in EAX, save this in ESI
    cmp eax, INVALID_HANDLE_VALUE ;if return value is equal to INVALID_HANDLE_VALUE then print error message
    je errorMsg  

    ;set up ReadFromFile function to read binaries into array
    mov edx, [ebp + 8]  ; array offset as param. (param1)
    mov ecx, ebx        ; 800 bytes to write (param2)
    call ReadFromFile   ;read from randonumbers.bin to array 
    jc errorMsg   ;If CF is clear, EAX = number of bytes read 
                  ;But if CF is set, EAX contains a numeric system error code.
    mov eax, [edi]
    call CloseFile

    jmp noerror ;if everything went well return
        
    errorMsg:   
        call WriteWindowsMsg ;display error message
    noerror:
        pop ebp
        ret 28
fillArrayToFile ENDP
; ***************************************************************
; Generate ARRAYSIZE random integers in the range [LO = 10 .. HI = 29], 
;   storing them in consecutive elements of an array. ARRAYSIZE should be set to 200.
; receives: fillArray {parameters: array(reference), LO (value), HI (value), ARRAYSIZE(value)} 
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100; registers changed: eax, ebx, ecx, edi
; ***************************************************************
fillArray   PROC   
    push ebp
    mov ebp, esp
    mov ecx, [ebp + 20]  ;array Size
    mov edi, [ebp + 8] ;address of array in edi
  
    L1:
        mov eax, [ebp + 12] ; assign HI
        sub eax, [ebp + 16] ; HI - LO
        inc eax     
        call randomrange
        add eax, [ebp + 16]  ;add LO

        mov [edi], eax
        add edi, TYPE DWORD
    loop L1

    pop ebp
    ret 16
fillArray ENDP

; ***************************************************************
;Display the list of integers before sorting, 
;   20 numbers per line with two spaces between each value.
; receives: {parameters: array (reference), ARRAYSIZE (value), title (reference)}
; returns: 
; preconditions: 
; ***************************************************************
displayList     PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    mov DWORD PTR [ebp-4], 0 ; count for printing a line 
    mov edi, [ebp + 16] ;  array offset
    mov ecx, [ebp + 12] ; array size
    mov edx, [ebp + 8] ; title offset
    call writestring    ;Print title of list to screen
        
    displayLoop:
        mov eax, [edi] ;print array at current edi offset
        call writedec 
        add edi, TYPE DWORD ;move to next element in array
        inc DWORD PTR [ebp-4] ;increment count for printing a line
        mov al, '  ' ;print 2 spaces onto screen
        call writechar      
        call writechar
        
        ;print a line after every 20 numbers
        cmp DWORD PTR [ebp-4], 20
        jne  skipPrintLine        
        ;call CRLF
        mov DWORD PTR [ebp-4],0 ;reset count and print line
    
    skipPrintLine:
        loop displayLoop    

    mov esp, ebp
    pop ebp
    ret 12

displayList     ENDP

; ***************************************************************
; Procedure to use counts array to build sorted array and store in array
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: 
; ***************************************************************
sortList    PROC
    push ebp
    mov ebp, esp
    mov edx, [ebp + 20] ; HI
    mov edi, [ebp + 12] ; &array
    mov esi, [ebp + 8]  ; &counts

    cld
    mov eax, [ebp + 16]  ;  set eax to LO(10), loop until HI(29)
    CountsLoop:          ; build array by using counts array
        mov ecx, [esi]    ; set ecx to value at counts for stosd         
        rep stosd         ; store eax into &array (edi)        
        add esi, TYPE DWORD ; move esi to next element of counts
        inc eax
        cmp eax, edx ; compare eax to HI (29)              
        jle CountsLoop
               
    pop ebp
    ret 28
sortList    ENDP

; ***************************************************************
; displayMedian {parameters: array (reference), ARRAYSIZE (value)}
; Calculate and display the median value, rounded to the nearest integer.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: array is sorted
; ***************************************************************
displayMedian   PROC
    push ebp
    mov ebp, esp
    mov esi, [ebp + 12]
    
    ;check if ARRAYSIZE is even
    cdq     
    mov EAX, [ebp + 8]  ;ARRAYSIZE
    mov EBX, 2
    DIV EBX       ;eax = ARRAYSIZE/2      
    cmp edx, 0    ;compare remainder (edx) to check if odd-sized array
    mov ebx, TYPE DWORD ;calculate median index 
    MUL ebx             ;eax *= 4 
    add esi, eax        ; esi is now at middle index
    mov eax, [esi]      ;save middle element
    jne endMed          ;if odd jump, print middle element

    ;if even, add the sums of middle elements
    sub esi, ebx        ;move esi back 1 index
    mov ebx, [esi]      ;save middle element - 1
    add eax, ebx        ;calculate sum of middle elements
    mov ebx, 2          ;calculate average of middle elements
    div ebx
    
endMed:
    call writedec
    pop ebp
    ret 8
displayMedian   ENDP
; ***************************************************************
; Procedure to put count squares into the array.
; receives: address of array and value of count on system stack
; returns: first count elements of array contain consecutive squares
; preconditions: count is initialized, 1 <= count <= 100; registers changed: eax, ebx, ecx, edi
; ***************************************************************
countList       PROC
   	push ebp
    mov ebp, esp
    mov esi, [ebp + 20] ; array offset
    mov edi, [ebp + 12] ; counts offset

    ;set up for loop from 0 (ecx) to 200 (arraysize)
    xor ecx, ecx
    L2:
        mov eax, [esi] ; convert eax to dword address using esi. looks something like: c[a[i]]++
        mov ebx, TYPE dword
        mul ebx     
        add edi, eax   ; add dword address to move inside counts
        mov eax, 1     ; increment number at that address 
        add [edi], eax
        mov edi, [ebp + 12] ; reset edi to beginning of counts
        add esi, TYPE dword ; move array foward
        inc ecx             ; increment loop counter
        cmp ecx, [ebp + 16] ; jump if ecx < arraysize
        jl L2
    
    ; shift index 10-29 to the left of counts by using rep movsd
    cld                
    mov esi, [ebp + 12] ;set esi to the 10th element (counts+40)
    add esi, 40         
    mov ecx, [ebp + 8]  ;set rep counter to size of counts (20)
    mov edi, [ebp + 12] ; set esi to counts[0] offset
    rep movsd           ;moves contents of esi to edi using ecx as counter
	
    pop ebp
    ret 20
countList       ENDP

;intro procedure -------------------------------------
;
;   Description: display programmer's name, program's title 
;   Receives: none
;   Returns: none
;
intro PROC
    mov     edx, OFFSET author
    call    WriteString
    mov     edx, offset programTitle
    call    WriteString
    ret
intro ENDP

;displayInstructions procedure ------------------------
   ; Description: display program's instructions 
  ;  Receives: none
 ;   Returns: none
;
displayInstructions PROC
    mov     edx, OFFSET instructions0
    call    WriteString
    ret
displayInstructions ENDP

;displayFarewell --------------------------------------
  ;  Description: displays a farwell message user
;    Receives: none
 ;   Returns: none

displayFarewell PROC
    call    CrLF
    mov     edx, offset terminatingMsg
    call    WriteString
    ret
displayFarewell ENDP
END main