#include "smp_demo.h"

shared_t resource;

void main() {

  resource.data = 10;

  switch(CORE) {
  case 0:
    core0_foo();
    break;
  case 1:
    core1_foo();
    break;
  case 2:
    core2_foo();
    break;
  case 3:
    core3_foo();
    break;
  default:
    break;
  }
}

