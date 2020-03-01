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
programIntro        byte    "**--ProgramIntro------------------------------------------**", 0dh, 0ah, 0
extraCredit         BYTE    "EC: DESCRIPTION", 0dh, 0ah, 0
extraCredit1        BYTE    "- Display the numbers ordered by column instead of by row. (storeByColumn procedure) ", 0dh, 0ah, 0
extraCredit2        BYTE    "- Derive counts before sorting array, then use counts to sort array. (countList, sortList procedures)" , 0dh, 0ah, 0
extraCredit3        BYTE    "- Generate the numbers into a file; then read the file into the array. (fillArrayToFile procedure) ", 0dh, 0ah, 0
author              byte    "Author: Danny Tran " , 0dh, 0ah, 0 
programTitle        byte    "Title: Sorting and Counting Random integers! ", 0dh, 0ah, 0
instructions0       byte    "This program generates 200 random numbers in the range [10 ... 29], creates a file named randonumbers.bin, displays the original list, displays the number of instances of each generated value, ", 0
instructions1       byte    "sorts the list, displays the median value, then displays the list sorted in ascending order.", 0dh, 0ah, 0
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
    call storeByColumn

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
    cALL CRLF

    push OFFSET array 
    call storeByColumn

    push OFFSET array 
    push ARRAYSIZE 
    push OFFSET sortedListTitle
    call displayList
    
    call displayFarewell ; Display a terminating message. 

    exit    ; exit to operating system
main ENDP

; (insert additional procedures here)
; ***************************************************************
; storeByColumn orders numbers in an array to match a 10x20 Column-major order array
; receives: array (reference)
; returns: array containing numbers ordered by columns
; preconditions: size of array is 200
; postconditions: eax, ebx, ecx, edx, edi, esi registers are changed
; ***************************************************************
storeByColumn   PROC 
                LOCAL TempArray[200]:DWORD    

    ;fill TempArray with contents of array 
    cld 
    mov esi, [ebp + 8]  ; array
    lea edi, TempArray
    mov ecx, LENGTHOF TempArray
    rep movsd

    ; setup ArrayLoop to organize array contents by columns using movsd
    lea esi, TempArray 
    mov edi, [ebp + 8]  ; array in edi
    xor ecx, ecx    ; column index (initalized to 0)
    xor ebx, ebx    ; row index (initalized to 0)

    ArrayLoop:              
        ;calculate matrix index for edi
        mov edi, [ebp + 8]  
        mov eax, ebx ; multiply row index by elements per row
        mov edx, 20 ; 20 is elements per row (columns)
        mul edx 
        add eax, ecx    
        mov edx, TYPE DWORD
        mul edx
        add edi, eax   ; move edi to next matrix row            
        
        movsd   ; mov element from esi to new edi offset
        
        inc ebx ; increment row index
        cmp ebx, 10 ; number of rows cannot exceed 9
        jl ArrayLoop
        xor ebx, ebx    ; reset row count 

        ; go to next column
        inc ecx
        cmp ecx, 20 ; 20 columns
        jl ArrayLoop
             
    ret 4
storeByColumn   ENDP
; ***************************************************************
; fillArrayToFile generates random integers using range values. [LO .. HI]  
;   into a file and uses the file to store into an array
; receives: array (reference), HI value, LO value, array size (value), file handle(reference),
    ;file name(reference), buffer(reference)
; returns: file containing random numbers, array filled with random numbers
; preconditions: 
;   fillArray function to generate random integers using range values into a buffer 
;   Size of buffer should equal or be bigger than array size. 
;   HI LO values should be LO < HI
;   Appropriate file name and extensions such as .txt or .bin
; postconditions: eax, ebx, ecx, edx, edi registers are changed
; ***************************************************************
fillArrayToFile PROC
    push ebp
    mov ebp, esp
    mov edi, [ebp + 24] ; file handle offset

    ; create outputfile using filename
    mov edx,  [ebp + 28] ; filename offset
    call CreateOutputFile

    mov [edi], eax ; store file handle 
    cmp eax, INVALID_HANDLE_VALUE ; if return value is equal to INVALID_HANDLE_VALUE then print error message
    je errorMsg      

    ; fill buffer with random numbers using fillArray function
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
    call WriteToFile ; write 800 bytes from buffer to file using the file handle
       
    mov eax, [edi]  ; close file using file handle offset in edi
    call CloseFile

    ; After writing to randonumbers.bin, call OpenInputFile to begin reading from it
    mov edx, [ebp + 28]     ; filename param for openinputfile
    call OpenInputFile      ; requires name of file offset in edx

    mov [edi], eax                ; return value is file handle stored in EAX, save this in ESI
    cmp eax, INVALID_HANDLE_VALUE ; if return value is equal to INVALID_HANDLE_VALUE then print error message
    je errorMsg  

    ;set up ReadFromFile function to read binaries into array
    mov edx, [ebp + 8]  ; array offset as param. (param1)
    mov ecx, ebx        ; 800 bytes to write (param2)
    call ReadFromFile   ; read from randonumbers.bin to array 
    jc errorMsg   ; If CF is clear, EAX = number of bytes read 
                  ; But if CF is set, EAX contains a numeric system error code.
    mov eax, [edi]
    call CloseFile

    jmp noerror ; if everything went well return
        
    errorMsg:   
        call WriteWindowsMsg ; display error message
    noerror:
        pop ebp
        ret 28
fillArrayToFile ENDP
; ***************************************************************
; fillArray generates ARRAYSIZE random integers in the range [LO .. HI], storing them in consecutive elements of an array
; receives: array(reference), HI (value), LO (value), ARRAYSIZE(value)
; returns: array containing randomly generated integers
; preconditions:    
;   Randomize should be called in main procedure
;   HI LO values should be LO < HI
; postconditions: eax, ecx, edi registers are changed
; ***************************************************************
fillArray   PROC   
    push ebp
    mov ebp, esp
    mov ecx, [ebp + 20] ; array Size
    mov edi, [ebp + 8]  ; address of array in edi
  
    L1:
        mov eax, [ebp + 12] ; assign HI
        sub eax, [ebp + 16] ; HI - LO
        inc eax     
        call RandomRange
        add eax, [ebp + 16] ; add LO
        mov [edi], eax
        add edi, TYPE DWORD
        loop L1

    pop ebp
    ret 16
fillArray ENDP

; ***************************************************************
; displayList displays a title and a list of integers of an array in sequential order. 
; Array elements are displayed 20 numbers per line with two spaces between each value.
; receives: array (reference), ARRAYSIZE (value), title (reference)
; returns: none
; preconditions: none
; postconditions: eax, ecx, edx, edi registers are changed
; ***************************************************************
displayList     PROC
    push ebp
    mov ebp, esp
    sub esp, 4
    mov DWORD PTR [ebp-4], 0 ; count for printing a line    
    mov edi, [ebp + 16] ;  array offset
    mov ecx, [ebp + 12] ; array size
    mov edx, [ebp + 8] ; title offset
    call WriteString    ; Print title of list to screen
        
    displayLoop:
        mov eax, [edi] ; print array at current edi offset
        call WriteDec 
        add edi, TYPE DWORD ; move to next element in array
        inc DWORD PTR [ebp-4] ; increment count for printing a line
        mov al, ' ' ; print 2 spaces onto screen
        call WriteChar      
        call WriteChar
        
        ; print a line after every 20 numbers
        cmp DWORD PTR [ebp-4], 20
        jne  skipPrintLine        
        call CRLF
        mov DWORD PTR [ebp-4],0 ; reset count and print line
    
    skipPrintLine:  
        loop displayLoop    

    mov esp, ebp
    pop ebp
    ret 12

displayList     ENDP

; ***************************************************************
; sortList uses counts array to build a sorted array and stored in array
; receives: counts array (reference), array (reference), LO (value), HI (value)
; returns: sorted array
; preconditions: 
;   Procedure countList should be called before this procedure 
;   counts array should contain count values generated by countList
;   HI LO values should be LO < HI
; postconditions: eax, ebx, ecx, edx, edi, esi registers are changed
; ***************************************************************
sortList    PROC
    push ebp
    mov ebp, esp
    mov edx, [ebp + 20] ; HI
    mov edi, [ebp + 12] ; &array
    mov esi, [ebp + 8]  ; &counts

    cld
    mov eax, [ebp + 16]  ; set eax to LO(10), loop until HI(29)
    CountsLoop:          ; build array by using counts array
        mov ecx, [esi]   ; set ecx to value at counts for stosd         
        rep stosd        ; store eax into &array (edi)        
        add esi, TYPE DWORD ; move esi to next element of counts
        inc eax
        cmp eax, edx ; compare eax to HI (29)              
        jle CountsLoop
               
    pop ebp
    ret 20
sortList    ENDP

; ***************************************************************
; displayMedian displays the median value of a list rounded to the nearest integer.
; receives: array (reference), ARRAYSIZE (value)
; returns: none
; preconditions: list is sorted, array size greater than 0
; postconditions: eax, ebx, edx, esi registers are changed
; ***************************************************************
displayMedian   PROC
    push ebp
    mov ebp, esp
    mov esi, [ebp + 12] ; &array
    
    ;check if ARRAYSIZE is even
    xor edx, edx
    mov EAX, [ebp + 8]  ; ARRAYSIZE
    mov EBX, 2      ; if arraysize is divisible by two, remainder (edx) should be 0
    DIV EBX         ; eax = ARRAYSIZE / 2      
    push edx        ; save remainder to help decide if array size is odd

    ; find median index
    mov ebx, TYPE DWORD ; calculate median index by multiplying TYPE and array size, then adding to esi
    MUL ebx             ; eax *= 4 
    add esi, eax        ; esi is now at middle index
    mov eax, [esi]      ; save middle element

    pop edx
    cmp edx, 0          ; compare remainder (edx) to check if odd-sized array
    jne printMedian     ; if remainder is not equal to 0, then array size is odd

    ;if even, add the sums of middle elements  
    sub esi, ebx        ; move esi back 1 index (ebx contains type dword)
    mov ebx, [esi]      ; save middle element - 1
    add eax, ebx        ; calculate sum of middle elements
    mov ebx, 2          ; calculate average of middle elements
    xor edx, edx
    div ebx    
    cmp edx, 1     ; round up if remainder is 1
    jne printMedian

    inc eax
    
printMedian:
    call WriteDec
    pop ebp
    ret 8
displayMedian   ENDP

; ***************************************************************
; countList lists the number of instances of each value in array 
; receives: array (reference), array size (value), counts (reference), count size (value) 
; returns:  integer counts generated in counts array
; preconditions: counts array should be of size of the greatest number in array
; postconditions: eax, ebx, ecx, edi, esi registers are changed
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
; ***************************************************************
;   Description: display programmer's name, program's title 
;   Receives: none
;   Returns: none
;   Preconditions: none
;   Postconditions: edx registers are changed
; ***************************************************************
intro PROC
    mov     edx, OFFSET author
    call    WriteString
    mov     edx, offset programTitle
    call    WriteString
    call    displayInstructions
    mov     edx, OFFSET programIntro
    call    WriteString
    mov     edx, OFFSET extraCredit
    call    WriteString
    mov     edx, OFFSET extraCredit1
    call    WriteString
    mov     edx, OFFSET extraCredit2
    call    WriteString
    mov     edx, OFFSET extraCredit3
    call    WriteString
    ret
intro ENDP

; ***************************************************************
; Description: display program's instructions 
;  Receives: none
;  Returns: none
;  Preconditions: none
;  Postconditions: edx registers are changed
; ***************************************************************
displayInstructions PROC
    mov     edx, OFFSET instructions0
    call    WriteString
    mov     edx, OFFSET instructions1
    call    WriteString
    ret
displayInstructions ENDP

; ***************************************************************
;  Description: displays a farwell message user
;   Receives: none
;   Returns: none
;   Preconditions: none
;   Postconditions: edx registers are changed
; ***************************************************************
displayFarewell PROC
    call    CrLF
    mov     edx, offset terminatingMsg
    call    WriteString
    ret
displayFarewell ENDP
END main