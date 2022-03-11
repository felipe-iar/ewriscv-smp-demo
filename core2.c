#include "smp_demo.h"

void core2_foo() {
  static cpu_t core2;

  core2.id = CORE;
  core2.reload = BASE_DELAY * (core2.id + 1);

  while (1) {
    DELAY(core2);
    core2.counter++;
  }
}