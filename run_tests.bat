@echo off
set LUA_PATH=.\?.lua;.\tests\?.lua;.\tests\suites\?.lua
set LUA_CPATH=
"C:\Program Files (x86)\Lua\5.1\lua.exe" "%~dp0tests\init.lua"
pause 