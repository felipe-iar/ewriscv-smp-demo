#include "smp_demo.h"

void core3_foo() {
  static cpu_t core3;

  core3.id = CORE;
  core3.reload = BASE_DELAY * (core3.id + 1);

  while (1) {
    DELAY(core3);
    core3.counter++;
  }
}