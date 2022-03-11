#include "smp_demo.h"

void core1_foo() {
  static cpu_t core1;

  core1.id = CORE;
  core1.reload = BASE_DELAY * (core1.id + 1);

  while (1) {
    DELAY(core1);
    core1.counter++;
    spinlock(&resource.mutex);
    printf("%lu\n", resource.data);
    spinunlock(&resource.mutex);
  }
}