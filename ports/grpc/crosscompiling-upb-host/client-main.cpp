// Copyright 2021 atframework

#include <iostream>

#include "upb/def.hpp"
#include "upb/json_decode.h"
#include "upb/json_encode.h"
#include "upb/upb.hpp"

#include "helloworld.upb.h"
#include "helloworld.upbdefs.h"

int main() {
  upb::Arena arena;
  helloworld_HelloRequest* test_msg = helloworld_HelloRequest_new(arena.ptr());
  helloworld_HelloRequest_set_name(test_msg, upb_StringView_FromString ("hello world!"));
  size_t size;
  helloworld_HelloRequest_serialize(test_msg, arena.ptr(), &size);
  std::cout << size << std::endl;
  return 0;
}
