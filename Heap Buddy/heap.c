/*
 * This is a C implementation of malloc( ) and free( ), based on the buddy
 * memory allocation algorithm.
 */
#include <assert.h>
#include <stdio.h> // printf
/*
 * The following global variables are used to simulate memory allocation
 * Cortex-M's SRAM space.
 */
// Heap
char array[0x8000];          // simulate SRAM: 0x2000.0000 - 0x2000.7FFF
int heap_top = 0x20001000;   // the top of heap space
int heap_bot = 0x20004FE0;   // the address of the last 32B in heap
short max_size = 0x00004000; // maximum allocation: 16KB = 2^14
short min_size = 0x00000020; // minimum allocation: 32B = 2^5

// Memory Control Block: 2^10B = 1KB space
int mcb_top = 0x20006800;    // the top of MCB
int mcb_bot = 0x20006BFE;    // the address of the last MCB entry
int mcb_ent_sz = 0x00000002; // 2B per MCB entry
int mcb_total = 512;         // # MCB entries: 2^9 = 512 entries

/*
 * Convert a Cortex SRAM address to the corresponding array index.
 * @param  sram_addr address of Cortex-M's SRAM space starting at 0x20000000.
 * @return array index.
 */
int m2a(int sram_addr) {
  // TODO(student): add comment to each of the following line of code
  // determine the index of memory control block (MCB) entry by subtracting
  // base of SRAM space (0x20000000) from the given SRAM address
  int index = sram_addr - 0x20000000;
  // once the index is calculated, return the index to user 
  return index;
}

/*
 * Reverse an array index back to the corresponding Cortex SRAM address.
 * @param  array index.
 * @return the corresponding Cortex-M's SRAM address in an integer.
 */
int a2m(int array_index) {
  //  TODO(student): add comment to each of the following line of code
  // determine the address of memory control block (MCB) entry by adding
  // base of SRAM space (0x20000000) to the given array index
  return array_index + 0x20000000;
}

/*
 * In case if you want to print out, all array elements that correspond
 * to MCB: 0x2006800 - 0x20006C00.
 */
void printArray() {
  printf("memory ............................\n");
  // TODO(student): add comment to each of the following line of code
  // This loop iterates through entire array 4 bytes at a time. 
  // Array is a char array that represents the entire SRAM space.
  for (int i = 0; i < 0x8000; i += 4) {
    // This checks if the loop reached MCB address space and prints out
    // the address of Cortex-M's SRAM space and the value of the MCB entry in 
    // both decimal and hexadecimal format.
    if (a2m(i) >= 0x20006800) {
      // print the Cortex-M's SRAM address in hexadecimal format and value 
      // of the MCB entry in both decimal and hexadecimal format.
      printf("%x = %x(%d)\n", a2m(i), *(short *)&array[i], *(short *)&array[i]);
    }
    // checks if the 3rd byte of the array is in MCB address space
    if (a2m(i + 2) >= 0x20006800) {
      // print the Cortex-M's SRAM address in hexadecimal format and value 
      // of the MCB entry in both decimal and hexadecimal format.
      printf("%x = %x(%d)\n", a2m(i + 2), *(short *)&array[i + 2],
             *(short *)&array[i + 2]);
    }
  }
}

/*
 * _ralloc is _kalloc's helper function that is recursively called to
 * allocate a requested space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  size  the size of a requested memory space
 * @param  left_mcb_addr  the address of the left boundary of MCB entries to
 examine
 * @param  right_mcb_addr the address of the right boundary of MCB entries to
 examine
 * @return the address of Cortex-M's SRAM space. While the computation is
 *         made in integers, cast it to (void *). The gcc compiler gives
 *         a warning sign:
                cast to 'void *' from smaller integer type 'int'
 *         Simply ignore it.
 */
void *_ralloc(int size, int left_mcb_addr, int right_mcb_addr) {
  // printf("Test \n");
  // initial parameter computation
  //  TODO(student): add comment to each of the following line of code
  // calculates the entire memory control block (MCB) length. 
  // This will change depending on the stage of the recursion
  int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz;
  // based on the entire MCB address space, it calculates the midpoint of the
  // MCB index in given. 
  int half_mcb_addr_space = entire_mcb_addr_space / 2;
  // Once he midpoint is obtained, calculate the midpoint MCB address by adding
  // the given midpoint MCB index to the left MCB address.
  int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space;
  // initialize the heap address to 0
  int heap_addr = 0;
  // based length of the MCB address space, it calculates the actual heap size
  // by multiplying the length by 16 since each MCB represents 16 bytes.
  int act_entire_heap_size = entire_mcb_addr_space * 16;
  // same with the actual half heap size
  int act_half_heap_size = half_mcb_addr_space * 16;

  // base case
  //  TODO(student): add comment to each of the following line of code
  // check condition checks if it fits on half of the heap space.Since the 
  // recursion goes top down, half heap size decreases by half each time.
  if (size <= act_half_heap_size) {
    // this tries to allocate memory on the left side of the heap space
    void *heap_addr =
        _ralloc(size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz);
    // This condition checks if the allocation was successful or not
    if (heap_addr == 0) {
      // in case it was unsuccessful, it tries to allocate memory on the right
      return _ralloc(size, midpoint_mcb_addr, right_mcb_addr);
    }
    //this check if the current MCB entry is used or not which is determined by
    // lsb of the given MCB entry.
    if ((array[m2a(midpoint_mcb_addr)] & 0x01) == 0) {
      //printf("Not used %x test \n", m2a(midpoint_mcb_addr));
      // This sets the current MCB entry to to the actual half heap size since
      // it fits the size of the requested memory space.
      *(short *)&array[m2a(midpoint_mcb_addr)] = act_half_heap_size;
    }
    // returns the heap address for the given allocation
    // printf("heap_addr %x \n", heap_addr);
    // printf("value of the MCB entry %x \n", *(short *)&array[m2a(midpoint_mcb_addr)]);
    return heap_addr;
  }
  // (size > act_half_heap_size)
  //check if the current MCB is used or not
  if ((array[m2a(left_mcb_addr)] & 0x01) != 0) {
    // if it is used, return 0 to show that the allocation failed
    return 0;
  }
  // check if the current MCB entry is smaller than the actual heap size
  if (*(short *)&array[m2a(left_mcb_addr)] < act_entire_heap_size) {
    // it is it, return 0 to show that the allocation failed 
    return 0;
  }
  // Assign the current MCB entry to the actual heap size and set the lsb to 1
  // which signifies that the current MCB entry is used.
  *(short *)&array[m2a(left_mcb_addr)] = act_entire_heap_size | 0x01;
  // calculates the heap address and cast it to void pointer to return it to user
  return (void *)(heap_top + (left_mcb_addr - mcb_top) * 16);
}

/*
 * _rfree is _kfree's helper function that is recursively called to
 * deallocate a space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  mcb_addr that corresponds to a SRAM space to deallocate
 * @return the same as the mcb_addr argument in success, otherwise 0.
 */
int _rfree(int mcb_addr) {
  //  TODO(student): add comment to each of the following line of code
  // objects the value of the given MCB entry based on the given MCB address
  short mcb_contents = *(short *)&array[m2a(mcb_addr)];
  // calculates the index of the given MCB entry
  int mcb_index = mcb_addr - mcb_top;
  // calculates the displacement of the given MCB entry which used to determine
  // the buddy of the given MCB entry
  short mcb_disp = (mcb_contents /= 16);
  // calcuates the size of the heap based on the given MCB entry content also, 
  // this and obove line of code clears the lsb of MCB content to show that current 
  // MCB entry is not used.
  short my_size = (mcb_contents *= 16);

  // mcb_addr's used bit was cleared
  *(short *)&array[m2a(mcb_addr)] = mcb_contents;

  //  TODO(student): add comment to each of the following line of code
  // check if it is on left or right side of the heap space
  if ((mcb_index / mcb_disp) % 2 == 0) {
    // bounds check if the buddy of the given MCB entry is within the 
    // MCB address space. 
    if (mcb_addr + mcb_disp >= mcb_bot) {
      return 0; // my buddy is beyond mcb_bot!
    }
    // Get the content of the buddy of the given MCB entry
    short mcb_buddy = *(short *)&array[m2a(mcb_addr + mcb_disp)];
    // check if the buddy is used or not
    if ((mcb_buddy & 0x0001) == 0) {
      // if it is not used, clear the lsb 
      // This code kinda does not make sense why would clear again 
      mcb_buddy = (mcb_buddy / 32) * 32;
      // check if the buddy is the same size as the given MCB entry
      if (mcb_buddy == my_size) {
        // if the buddy has the same size, clear the value of of the 
        // buddy. 
        *(short *)&array[m2a(mcb_addr + mcb_disp)] = 0;
        // since the size of the buddy is the same as the given MCB entry,
        // we double the size 
        my_size *= 2;
        // set the value of the given MCB entry to the new size showing 
        // that the given MCB entry is not used
        *(short *)&array[m2a(mcb_addr)] = my_size;
        // recursively call _rfree to merge and go up on the heap space
        return _rfree(mcb_addr);
      }
    }
   // if it is on the right side 
  } else {
    // check if the left side of the buddy is within the MCB address space
    if (mcb_addr - mcb_disp < mcb_top) {
      // if it is not in MCB address space, return 0 to show that the 
      // or it is not within the bound 
      return 0; // my buddy is below mcb_top!
    }
    // get the content of the buddy of the given MCB entry left side
    short mcb_buddy = *(short *)&array[m2a(mcb_addr - mcb_disp)];
    // check if the buddy is used or not
    if ((mcb_buddy & 0x0001) == 0) {
      // if it is not used, clear the lsb
      mcb_buddy = (mcb_buddy / 32) * 32;
      // check if the buddy is the same size as the given MCB entry
      if (mcb_buddy == my_size) {
        // clear the buddy's value 
        *(short *)&array[m2a(mcb_addr)] = 0;
        // double the size of the given MCB entry
        my_size *= 2;
        // set the value of the buddy to the new size
        *(short *)&array[m2a(mcb_addr - mcb_disp)] = my_size;
        // recursively call _rfree to merge and go up on the heap space
        return _rfree(mcb_addr - mcb_disp);
      }
    }
  }
  return mcb_addr;
}

/*
 * Initializes MCB entries. In step 2's assembly coding, this routine must
 * be called from Reset_Handler in startup_TM4C129.s before you invoke
 * driver.c's main( ).
 */
void _kinit() {
  //  TODO(student): add comment to each of the following line of code
  // This loop iterates throught the heap space 
  for (int i = 0x20001000; i < 0x20005000; i++) {
    // below sets the each byte in the heap space to 0
    array[m2a(i)] = 0;
  }
  // this sets the first MCB entry to 0x4000 (16KB) 
  *(short *)&array[m2a(mcb_top)] = max_size;
  // Per discord discussion this it should start from 0x20006802. This loop 
  // iterates through the MCB space and sets each byte to 0 by incrementing
  // two bytes at a time since MCB is short (2 bytes)
  for (int i = 0x20006802; i < 0x20006C00; i += 2) {
    // sets the first byte to 0
    array[m2a(i)] = 0;
    // sets the second byte to 0
    array[m2a(i + 1)] = 0;
  }
}

/*
 * Step 2 should call _kalloc from SVC_Handler.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_kalloc(int size) { return _ralloc(size, mcb_top, mcb_bot); }

/*
 * Step 2 should call _kfree from SVC_Handler.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_kfree(void *ptr) {
  //  TODO(student): add comment to each of the following line of code
  // by converting the given pointer to an integer, it determines if the address 
  // of the pointer. 
  int addr = (int)ptr;
  // checks if the address is whithin the heap space (bound check)
  if (addr < heap_top || addr > heap_bot) {
    // if the address is not in heap space, return NULL to show that 
    // the pointer is invalid and failed. 
    return NULL;
  }
  // if the address is in heap space, it calculates the address of the
  // memory control block (MCB) entry that corresponds to the given pointer.
  // Since each MCB represents 16 bytes, it initally calculates the offset
  // by subtracting heap_top from from given address and dividing it by 16
  // which will give the offset of the MCB entry. Then it adds the offset
  // to the mcb top to get the actual address of the MCB entry.
  int mcb_addr = mcb_top + (addr - heap_top) / 16;
  // Once the address of the MCB entry is determined, it calls _rfree, which 
  // is helper to deallocate the space and checkks if the r_free is succeeded or not
  if (_rfree(mcb_addr) == 0) {
    // if it fails to free or deallocate the space, it returns NULL to show that
    // it was unable to free the space.
    return NULL;
  }
  // the situation the r_free succeeded, it orginal pointer parameter to the user. 
  return ptr;
}

/*
 * _malloc should be implemented in stdlib.s in step 2.
 * _kalloc must be invoked through SVC in step 2.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_malloc(int size) {
  assert(size >= min_size);
  static int init = 0; // global variable
  // check if _kinit is called or not before 
  if (init == 0) {
    init = 1;
    // initialize the memory control block (MCB) entries and 
    // heap sapce. 
    _kinit();
  }
  // call _kalloc to allocate the space
  return _kalloc(size);
}

/*
 * _free should be implemented in stdlib.s in step 2.
 * _kfree must be invoked through SVC in step 2.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_free(void *ptr) { return _kfree(ptr); }
