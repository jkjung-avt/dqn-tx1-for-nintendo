--------------------------------------------------------------------------------
--
-- "vidcap" module
--
-- This module implements video capture (from /dev/video0) through FFI
-- interface. The actual video capture code is written in C, which calls
-- V4L2 API.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-06
--------------------------------------------------------------------------------

require 'torch'

local ffi = require 'ffi'
local vidcap = ffi.load(paths.cwd() .. '/vidcap/libvidcap.so')
--local vidcap = ffi.load('libvidcap.so')

-- Function prototype definition
ffi.cdef [[
    int  vidcap_init();
    void vidcap_get(unsigned char *ptrFromLua);
    void vidcap_flush();
    void vidcap_cleanup();
]]

return vidcap
