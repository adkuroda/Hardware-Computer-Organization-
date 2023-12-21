		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit

;void _kinit() {
;  for (int i = 0x20001000; i < 0x20005000; i++) {
;   array[m2a(i)] = 0;
;  }

;  *(short *)&array[m2a(mcb_top)] = max_size;

; for (int i = 0x20006802; i < 0x20006C00; i += 2) {
;    array[m2a(i)] = 0;
;    array[m2a(i + 1)] = 0;
; }
; }
; *********************** MY CODE GOES HERE ************************
		; you must correctly set the value of each MCB block
		; complete your code
        PUSH 	{r1 -r12, lr}
;  for (int i = 0x20001000; i < 0x20005000; i++) 
;   array[m2a(i)] = 0;

		LDR 	r1, =HEAP_TOP  ; r1 = 0x20001000
		LDR 	r2, =HEAP_BOT  ; r2  = 0x20004FE0
		LDR 	r3, =MIN_SIZE  ;r3 = 0x00000020
		ADD 	r2, r2, r3  ; r2 = 0x20005000
loop_heap
		;MOV r4, #0x1  ; COMMENT OUT TESTING PURPOSE 
		MOV 	R4, #0x0
		CMP 	r1, r2 ;check the loop if readed to end
		BEQ next ;if equal then move to next part 
		STRB 	r4, [r1], #1 ;store 0 to locaation where r1 is and advance the r1 by one byte
		B loop_heap ; go back to loop 
; *(short *)&array[m2a(mcb_top)] = max_size;
next
		LDR 	r1, =MCB_TOP ;r1 = 0x20006800 ;get MCB top to r1 
		LDR 	r2, =MAX_SIZE ;r2 = 0x00004000; get the max size r2
		STR 	r2, [r1], #0x2 ;strore 0x00004000 to first 2 bit of 0x20006800 and advance by 2 

		
; for (int i = 0x20006802; i < 0x20006C00; i += 2) {
;    array[m2a(i)] = 0;
;    array[m2a(i + 1)] = 0;
; }
loop_BCM 
		LDR 	r2, =MCB_BOT ;r2 = 0x20006BFE
		LDR		r3, =MCB_ENT_SZ ;r3 = 0x00000002
		ADD 	r2, r2, r3  ;r2 = 0x20006C00
		CMP 	r1, r2  
		BEQ end_BCM
		STRB 	r4, [r1], #0x1
		STRB 	r4, [r1], #0x1
		B loop_BCM		

end_BCM 
		POP 	{r1 - r12, lr}	
		
; ********************** END ******************************************
		BX		lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )

;void *_ralloc(int size, int left_mcb_addr, int right_mcb_addr) {
;int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz;
;int half_mcb_addr_space = entire_mcb_addr_space / 2;
;int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space;
;int heap_addr = 0;
;int act_entire_heap_size = entire_mcb_addr_space * 16;
;int act_half_heap_size = half_mcb_addr_space * 16;

;if (size <= act_half_heap_size) {
;void *heap_addr =_ralloc(size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz);
;if (heap_addr == 0) {
;return _ralloc(size, midpoint_mcb_addr, right_mcb_addr);
;}
;if ((array[m2a(midpoint_mcb_addr)] & 0x01) == 0) {
;*(short *)&array[m2a(midpoint_mcb_addr)] = act_half_heap_size;
;}
;return heap_addr;
;}

;if ((array[m2a(left_mcb_addr)] & 0x01) != 0) {
;return 0;
;}

;if (*(short *)&array[m2a(left_mcb_addr)] < act_entire_heap_size) {
;return 0;
;}

;*(short *)&array[m2a(left_mcb_addr)] = act_entire_heap_size | 0x01;
;return (void *)(heap_top + (left_mcb_addr - mcb_top) * 16);
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


_ralloc
    PUSH 	{r4-r11, lr}
	LDR 	r10, =MCB_ENT_SZ
	
    ; int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz;
    SUB 		r4, r3, r2
    ADD 		r4, r4, r10 ;r4 = entire_mcb_addr_space
    
    ; int half_mcb_addr_space = entire_mcb_addr_space / 2;
    MOV r5, r4
    LSR r5, #0x1  ; r5 = half_mcb_addr_space

    ; int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space;
    ADD r6, r2, r5 ;r6 = midpoint_mcb_addr

    ; int act_entire_heap_size = entire_mcb_addr_space * 16;
	LSL		r7, r4, #0x4	;r7 = act_entire_heap_size

    ; int act_half_heap_size = half_mcb_addr_space * 16;
    LSL 	r8, r5, #4 ; r8 = act_half_heap_size 
    
    ; if (size <= act_half_heap_size)
    CMP 	r1, r8
    BGT else
		
	;void *heap_addr =_ralloc(size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz);
	PUSH 	{r3}
    SUB 	r3, r6, r10
	;PUSH 	{r4-r11, lr}
    BL _ralloc   ;call _ralloc on left side
	POP {r3}
	;POP 	{r4-r11, lr}
    MOV 	r9, r0 ; assign to herturn value to head_add
    
	;if (heap_addr == 0) 
    CMP 	r9, #0x0
    BNE success
	
	
	;return _ralloc(size, midpoint_mcb_addr, right_mcb_addr);    
    MOV 	r2, r6
	;PUSH 	{r4-r11, lr}
    BL _ralloc  ; call _ralloc right side 
	;POP 	{r4-r11, lr}
    B end  


;if ((array[m2a(midpoint_mcb_addr)] & 0x01) == 0) {
;*(short *)&array[m2a(midpoint_mcb_addr)] = act_half_heap_size;
;return heap_addr;
success
    LDRB 	r11, [r6] ; r11 = array[m2a(midpoint_mcb_addr)]
	AND 	r11, #0x01 ; array[m2a(midpoint_mcb_addr)] & 0x01)
	CMP 	r11, #0
	BNE 	end_1 ; raturn heap_addr
	STRH 	r8, [r6]
	B end_1   	; ;return heap_addr

else
	
	;if ((array[m2a(left_mcb_addr)] & 0x01) != 0) {
	;return 0;
    LDRB 	r11, [r2] ;r11 = (array[m2a(left_mcb_addr)
    AND 	r11, #0x01 ; array[m2a(left_mcb_addr)] & 0x01
    CMP 	r11, #0     ; check if it is used. 
    BNE failure ; this will jump to failure and return 0 
	
	
	;if (*(short *)&array[m2a(left_mcb_addr)] < act_entire_heap_size) {
	;return 0;
    ; if MCB size < heap size, return 0
    LDRH 	r11, [r2]  ;r11 =  *(short *)&array[m2a(left_mcb_addr)
    CMP 	r11, r7 ; compare with actual entire heap size 
    BLT failure ; if less than return 0

	;*(short *)&array[m2a(left_mcb_addr)] = act_entire_heap_size | 0x01;
	
    MOV 	r11, r7 ;r11 = act_entire_heap_size
    ORR 	r11, #0x01 ; act_entire_heap_size | 0x01
    STRH	r11, [r2] ; assing the value to *(short *)&array[m2a(left_mcb_addr)
    
	;return (void *)(heap_top + (left_mcb_addr - mcb_top) * 16);
	LDR 	r11, =HEAP_TOP 
	LDR 	r12, =MCB_TOP
	SUB 	r12, r2, r12
    ADD 	r0, r11, r12, LSL #4
    B 		end ; this will return

failure
    MOV 	r0, #0	; load 0 as return value 
	B 		end      ;return 

end_1 
	MOV r0, r9
	B end 
    
end
	POP 	{r4-r11, lr}
	BX 		lr
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;int _rfree(int mcb_addr) {
;  short mcb_contents = *(short *)&array[m2a(mcb_addr)];
;  int mcb_index = mcb_addr - mcb_top;
;  short mcb_disp = (mcb_contents /= 16);
;  short my_size = (mcb_contents *= 16);
;  *(short *)&array[m2a(mcb_addr)] = mcb_contents;
;  if ((mcb_index / mcb_disp) % 2 == 0) {
;    if (mcb_addr + mcb_disp >= mcb_bot) {
;      return 0; // my buddy is beyond mcb_bot!
;    }
;    short mcb_buddy = *(short *)&array[m2a(mcb_addr + mcb_disp)];
;    if ((mcb_buddy & 0x0001) == 0) {
;      mcb_buddy = (mcb_buddy / 32) * 32;
;      if (mcb_buddy == my_size) {
;        *(short *)&array[m2a(mcb_addr + mcb_disp)] = 0;
;        my_size *= 2;
;        *(short *)&array[m2a(mcb_addr)] = my_size;
;        return _rfree(mcb_addr);
;      }
;    }
;  } else {
;    if (mcb_addr - mcb_disp < mcb_top) {
;      return 0; // my buddy is below mcb_top!
;    }
;    short mcb_buddy = *(short *)&array[m2a(mcb_addr - mcb_disp)];
;    if ((mcb_buddy & 0x0001) == 0) {
;      mcb_buddy = (mcb_buddy / 32) * 32;
;      if (mcb_buddy == my_size) {
;        *(short *)&array[m2a(mcb_addr)] = 0;
;        my_size *= 2;
;        *(short *)&array[m2a(mcb_addr - mcb_disp)] = my_size;
;        return _rfree(mcb_addr - mcb_disp);
;      }
;    }
;  }
;  return mcb_addr;
;}


_rfree
	PUSH {lr}
	LDR 	r10, =MCB_TOP
	LDR		r11, =MCB_BOT 
	;  short mcb_contents = *(short *)&array[m2a(mcb_addr)];
	LDRH 	r2, [r1]
		;  int mcb_index = mcb_addr - mcb_top;
	SUB 	r3, r1, r10
	;  short mcb_disp = (mcb_contents /= 16);
	LSR 	r2, r2, #0x4
	MOV 	r4, r2 
	;  short my_size = (mcb_contents *= 16);
	LSL  	r2, #0x4
	MOV 	r5, r2
	;  *(short *)&array[m2a(mcb_addr)] = mcb_contents;
	STRH 	r2, [r1]
	;  if ((mcb_index / mcb_disp) % 2 == 0) {
	SDIV 	r6, r3, r4
	MOV 	r7, #0x2
	SDIV 	r8, r6, r7
	MLS 	r9, r7, r8, r6 
	CMP		r9, #0x0
	BNE 	right  
	
	;if (mcb_addr + mcb_disp >= mcb_bot)
	ADD 	r6, r1, r4
	CMP r6, r11
	BGE beyond_mcb  ;      return 0; // my buddy is beyond mcb_bot!
	
	;    short mcb_buddy = *(short *)&array[m2a(mcb_addr + mcb_disp)];
	ADD 	r6, r1, r4 
	LDRH 	r7, [r6]
	
	;    if ((mcb_buddy & 0x0001) == 0)
	AND 	r8, r7, #0x0001
	CMP 	r8, #0x0
	;if ((mcb_buddy & 0x0001) == 0) 
	BNE 	occupied 
	;  mcb_buddy = (mcb_buddy / 32) * 32;
	LSR 	r7, r7, #0x5
	LSL 	r7, r7, #0x5
	;if (mcb_buddy == my_size)
	CMP 	r7, r5
	BNE 	occupied 
	; *(short *)&array[m2a(mcb_addr + mcb_disp)] = 0;
	ADD 	r6, r1, r4
	MOV 	r7, #0x0
	STRH 	r7, [r6]
	;my_size *= 2;
	LSL 	r5, r5, #0x1
	;*(short *)&array[m2a(mcb_addr)] = my_size;
	STRH 	r5, [r1]
	;        return _rfree(mcb_addr);
	PUSH {r2 - r11, lr}
	BL 	_rfree
	POP {r2-r11, lr}
	B end_3


right 
	;    if (mcb_addr - mcb_disp < mcb_top) {
	SUB 	r6, r1, r4
	CMP 	r6, r10
	BLT 	beyond_mcb ;      return 0; // my buddy is below mcb_top!
	;    short mcb_buddy = *(short *)&array[m2a(mcb_addr - mcb_disp)];
	SUB 	r6, r1, r4
	LDRH 	r7, [r6]
	;if ((mcb_buddy & 0x0001) == 0) 
	AND 	r8, r7, #0x0001
	CMP 	r8, #0x0
	BNE		occupied 
	;  mcb_buddy = (mcb_buddy / 32) * 32;
	LSR 	r7, r7, #0x5
	LSL 	r7, r7, #0x5	
	;if (mcb_buddy == my_size) 
	CMP r7, r5 
	BNE 	occupied 
	; *(short *)&array[m2a(mcb_addr)] = 0;
	MOV 	r8, #0x0
	STRH 	r8, [r1]
	;        my_size *= 2;
	LSL 	r5, r5, #0x1
	 ;*(short *)&array[m2a(mcb_addr - mcb_disp)] = my_size;
	SUB 	r6, r1, r4
	STRH 	r5, [r6]
	SUB 	r1, r1, r4
	;        return _rfree(mcb_addr - mcb_disp);
	PUSH {r2 - r11, lr}
	BL 	_rfree
	POP {r2-r11, lr}
	B end_3


beyond_mcb
	MOV 	r0, #0x0
	B		end_3

occupied 
	MOV r0, r1 
	B 	end_3


end_3
	POP {lr}
	BX 		lr 





	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		EXPORT	_kalloc
_kalloc
;***************** START CODE **********************************
; void* _k_alloc( int size)
		PUSH {r1-r12, lr}
		MOV 	r1, r0
		LDR 	r2, =MCB_TOP
		LDR 	r3, =MCB_BOT 
		BL _ralloc






		; complete your code
		; return value should be saved into r0
		POP {r1-r12, lr}
;****************** END ****************************************
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )
		EXPORT	_kfree
_kfree
; *********************** MY CODE GOES HERE ************************
		; complete your code
		; return value should be saved into r0
		PUSH {r1-r12, lr}
		MOV 	r1, r0
		
  ;int addr = (int)ptr;

 ; if (addr < heap_top || addr > heap_bot) {
 ;   return NULL;
  
 ; int mcb_addr = mcb_top + (addr - heap_top) / 16;

  ;if (_rfree(mcb_addr) == 0) {
  ;  return NULL;
 ; return ptr;
		LDR 	r1, =HEAP_TOP
		LDR 	r2, =HEAP_BOT 
		;if (addr < heap_top || addr > heap_bot) 
		CMP 	r0, r2 
		BGE not_in_bound 
		CMP 	r0, r1
		BLT not_in_bound 
		
		LDR 	r3, =MCB_TOP 
		;int mcb_addr = mcb_top + (addr - heap_top) / 16
		SUB 	r4, r0, r1
		LSR 	r4, #0x4
		MOV 	r1, #0x0
		ADD 	r1, r4, r3
		PUSH {r0}
		BL _rfree
		POP  {r1}
		CMP 	r0, #0x0 
		BNE valid 
not_in_bound 
		MOV 	r0, #0x0
valid 	
		MOV 	r0, r1 
		POP {r1-r12, lr}
;********************** END ************************************	
		BX		lr
		
		END
