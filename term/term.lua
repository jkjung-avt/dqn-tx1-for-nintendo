--------------------------------------------------------------------------------
--
-- "term" module
--
-- This module implements waitkey function through FFI. The underlying Ci
-- code uses terminal I/O calls to alter the behavior of terminal, and would
-- restore it before exiting
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-17
--------------------------------------------------------------------------------

local ffi = require 'ffi'
local term = {}
local lib = ffi.load(paths.cwd() .. '/term/libterm.so')

-- Function prototype definition
ffi.cdef [[
    void term_init();
    void term_cleanup();
    void term_msleep(int msec);
    int  term_waitkey(int timeout);
]]

function term.init()    lib.term_init()    end
function term.cleanup() lib.term_cleanup() end
function term.msleep(m) lib.term_msleep(m) end

-- waitkey(t) returns nil to caller if timed out
function term.waitkey(t)  -- t is timeout in msec
    local c = lib.term_waitkey(t)
    if c == 0 then return nil end
    return c
end

return term
