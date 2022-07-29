// Copyright 2022 atframework

#include <iostream>

#include "upb/def.hpp"
#include "upb/json_decode.h"
#include "upb/json_encode.h"
#include "upb/upb.hpp"

#include "test_pb.upb.h"
#include "test_pb.upbdefs.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#include "upb/bindings/lua/upb.h"
#ifdef __cplusplus
}
#endif

int main() {
  upb::Arena arena;
  cmake_toolset_test_message* test_msg = cmake_toolset_test_message_new(arena.ptr());
  cmake_toolset_test_message_set_str(test_msg, upb_StringView_FromString("hello world!"));
  cmake_toolset_test_message_set_i64(test_msg, 123321);
  size_t size;
  cmake_toolset_test_message_serialize(test_msg, arena.ptr(), &size);
  std::cout << size << std::endl;

  // Lua binding
  {
    lua_State* L = luaL_newstate();
    luaL_openlibs(L);

    // luaopen_lupb(L);
    std::cout << "Load lupb" << std::endl;
    const char* init = "package.preload['lupb'] = ... ";
    lua_pushcfunction(L, luaopen_lupb);
    luaL_loadstring(L, init);
    lua_pushcfunction(L, luaopen_lupb);
    if (lua_pcall(L, 1, LUA_MULTRET, 0)) {
      std::cout << "Load lupb failed" << std::endl;
    }

    std::cout << "Run lua code" << std::endl;
    luaL_dostring(L,
                  "print(pcall(function() print('Message Count:' .. require('test_pb_pb')._filedef:msgcount()) end))");
    luaL_dostring(L, "print(pcall(function() print('File Name:' .. require('test_pb_pb')._filedef:name()) end))");

    lua_close(L);
  }

  std::cout << "End" << std::endl;
  return 0;
}
