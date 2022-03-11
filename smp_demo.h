#pragma once

#include <intrinsics.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <microchip/iopolarfire_u54.h>

#define CORE (__read_csr(_CSR_MHARTID)-1)        // macro used to identify the core

#define DELAY(x) { x.delay = x.reload; \
                   while(x.delay) {    \
                     x.delay--;        \
                   }                   \
                 }

#define BASE_DELAY 100000

typedef struct {
  uint64_t counter;
  uint64_t id;
  uint64_t reload;
  uint64_t delay;
} cpu_t;

typedef struct {
  atomic_flag mutex;
  uint64_t data;
} shared_t;

extern shared_t resource;

/* hart0-3 specific threads */
void core0_foo();
void core1_foo();
void core2_foo();
void core3_foo();

static inline void spinlock(atomic_flag *pLock)
{
  while (atomic_flag_test_and_set_explicit(pLock, 1));
}

static inline void spinunlock(atomic_flag *pLock)
{
    atomic_flag_clear(pLock);
}
