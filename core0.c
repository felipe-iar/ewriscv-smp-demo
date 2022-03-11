#include "smp_demo.h"

void core0_foo() {
  static cpu_t core0;

  core0.id = CORE;
  core0.reload = BASE_DELAY * (core0.id + 1);

  while (1) {
    DELAY(core0);
    core0.counter++;
    spinlock(&resource.mutex);
    resource.data = core0.counter;
    spinunlock(&resource.mutex);
  }
}