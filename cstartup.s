/**************************************************
 *
 * System initialization.
 *
 * Copyright 2019-2022 IAR Systems AB.
 *
 **************************************************/

#include "iarMacros.m"
#include "iarCfi.m"

        MODULE  ?cstartup

        PUBWEAK  __iar_program_start
        PUBLIC   __iar_program_start_metal

        SECTION CSTACK:DATA:NOROOT(4)
        SECTION CSTACK1:DATA:NOROOT(4)
        SECTION CSTACK2:DATA:NOROOT(4)
        SECTION CSTACK3:DATA:NOROOT(4)
        SECTION CSTACK4:DATA:NOROOT(4)

        // --------------------------------------------------

        SECTION `.cstartup`:CODE:NOROOT(2)
        CfiCom  ra,1,0
        CfiCom  ra,1,1
        CfiCom  ra,1,2
        CfiCom  ra,1,3
        CfiCom  ra,1,4
        CfiCom  ra,1,6

        CfiBlk 0,__iar_program_start
        CALL_GRAPH_ROOT __iar_program_start, "Reset"
        CODE

__iar_program_start:
        REQUIRE ?cstart_init_sp
        cfi ?RET Undefined
        nop                    // Avoid an empty section
        CfiEnd  0

// ----------
//Init gp (required in by the linker config file, if applicable)
        SECTION `.cstartup`:CODE:NOROOT(1)
        CfiBlk 1,__iar_program_start
        CODE
        PUBLIC __iar_cstart_init_gp
__iar_cstart_init_gp:
        cfi ?RET Undefined
        EXTERN  __iar_static_base$$GPREL
        .option push
        .option norelax
        ;; lui  gp, %hi(__iar_static_base$$GPREL)
        ;; addi gp, gp, %lo(__iar_static_base$$GPREL)
        la      gp, __iar_static_base$$GPREL
        .option pop
        REQUIRE ?cstart_init_sp

        CfiEnd  1

// ----------
// Init sp, note that this MAY be gp relaxed! (since if gp relaxations are
// allowed, __iar_cstart_init_gp is already done
        SECTION `.cstartup`:CODE:NOROOT(1)
#ifdef __riscv_flen
        REQUIRE __iar_program_start_metal
#endif
        REQUIRE call_low_level_init
        CfiBlk 2,__iar_program_start
        CODE
?cstart_init_sp:
        cfi ?RET Undefined

        // One stack for each hart
        csrr    a0, mhartid
        bne     a0, zero, ?not_hart_0
        la      a0, SFE(CSTACK)
        andi    sp, a0, -16
        j       ?sp_setup_done
?not_hart_0:
        li12    a1, 1
        bne     a0, a1, ?not_hart_1
        la      a0, SFE(CSTACK1)
        andi    sp, a0, -16
        j       ?sp_setup_done
?not_hart_1:
        li12    a1, 2
        bne     a0, a1, ?not_hart_2
        la      a0, SFE(CSTACK2)
        andi    sp, a0, -16
        j       ?sp_setup_done
?not_hart_2:
        li12    a1, 3
        bne     a0, a1, ?not_hart_3
        la      a0, SFE(CSTACK3)
        andi    sp, a0, -16
        j       ?sp_setup_done
?not_hart_3:
        la      a0, SFE(CSTACK4)
        andi    sp, a0, -16
?sp_setup_done:


        // Setup up a default interrupt handler to handle any exceptions that
        // might occur during startup
        EXTERN __iar_default_minterrupt_handler
        ;; lui     a0, %hi(__iar_default_minterrupt_handler)
        ;; addi    a0, a0, %lo(__iar_default_minterrupt_handler)
        la      a0, __iar_default_minterrupt_handler
        csrrci  x0, mtvec, 0x3
        csrs    mtvec, a0


        EXTWEAK __machine_interrupt_vector_setup
        CfiCall __machine_interrupt_vector_setup
        call    __machine_interrupt_vector_setup

        CfiEnd  2

        SECTION `.cstartup`:CODE:NOROOT(1)
        CfiBlk 6,__iar_program_start
        CODE
__iar_program_start_metal:
#ifdef __riscv_flen
        // Enable the floating-point unit by setting the "fs" field in
        // the "mstatus" register.

        lui     a0, %hi(1 << 13)
        csrs    mstatus, a0

        // Set rounding mode to "round to nearest" and clear
        // the floating-point exception flags.
        csrwi   fcsr, 0
#else
        nop      // avoid empty sections
#endif
        CfiEnd  6

        SECTION `.cstartup`:CODE:NOROOT(1)
        PUBLIC __init_itim_sifive
        CfiBlk 3,__iar_program_start
        CODE
__init_itim_sifive:
        cfi ?RET Undefined
        // For SiFive devices, we may want to clear the ITIM memory area
        // before we continue with the start up.
        EXTERN  __zero_itim_sifive
        CfiCall __zero_itim_sifive
        call    __zero_itim_sifive
        CfiEnd  3

        SECTION `.cstartup`:CODE:NOROOT(1)
        CfiBlk 4,__iar_program_start
        CODE
        EXTERN  __low_level_init
        EXTERN  __iar_data_init2
call_low_level_init:
        cfi ?RET Undefined
        CfiCall __low_level_init
        call    __low_level_init
        beq     a0, zero, ?cstart_call_main

        csrr    a0, mhartid
        li12    a1, 1
        bne     a0, a1, ?cstart_call_main
        CfiCall __iar_data_init2
        call    __iar_data_init2

?cstart_call_main:

        EXTERN  main
        li12    a0, 0                   ; argc
        CfiCall main
        call    main
        EXTERN  exit

        CfiCall exit
        call    exit
?cstart_end:
        j       ?cstart_end
        CfiEnd  4


        /* This section is required by some devices to handle HW reset */
        SECTION `.alias.hwreset`:CODE:NOROOT(2)
        PUBLIC __alias_hw_reset
__alias_hw_reset:
        csrci        mstatus, 0x08
        ;; lui     a0, %hi(__iar_program_start)
        ;; addi    a0, a0, %lo(__iar_program_start)
        la       a0, __iar_program_start
        jr       a0

        END
