		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		PUSH {r1-r12,lr}	
;************* START CODE **************		
		; you need to add some code here for part 1 implmentation
		    MOV R2, #0 ; This is value used to zero out the string 
for 
		CMP R1, #0 ; check if it reached to end of the string 
		BEQ end_for  ;jump to end if reached to end 
		STRB R2, [R0], #1  ;replace the str[i] with zero 
		SUB R1, R1, #1    ; move to next index
		B for       ; start the loop again 
end_for
;************** END *********************
		POP {r1-r12,lr}	
		BX		lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncat( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the destination array
;	src		- pointer to string to be appended
;	size	- Maximum number of characters to be appended
; Return value
;   dest
		EXPORT _strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		PUSH {r1-r12,lr}
;************* START CODE **************		
loop
		CMP R2, #0 ;check is stringA reached to end where n==0 
		BEQ end_loop   ;finish the loop 
		LDRB		R3, [R1], #1  ;get the value of stringA[i] and save to R3 and advance the index 
		STRB		R3, [R0], #1  ;store the R3 to stringB[i] and advance the index 
		SUB         R2, R2, #1 ;subtract 1 from n
		B loop ;start the loop again
end_loop
;**************** END ******************
		POP {r1-r12,lr}	
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; r0 = size
		PUSH {r1-r12,lr}
		
;*********** START CODE **********************
		MOV R7, #0x1  ; Set R7 with 1 
		SVC #0x0  ;invoke handleer 
		; you need to add two lines of code here for part 2 implmentation
; ************** END *************************
		POP {r1-r12,lr}	
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		; r0 = addr
		PUSH {r1-r12,lr}		
;*********** Start Code **********************
		MOV R7, #0x2  ;set R7 with 2   
		SVC #0x0 ;Invoke handler 
		; you need to add two lines of code here for part 2 implmentation
; ************** End **********************************	
		POP {r1-r12,lr}	
		BX		lr
		
		END