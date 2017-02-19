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
local vidcap = {}
local lib = ffi.load(paths.cwd() .. '/vidcap/libvidcap.so')

-- Function prototype definition
ffi.cdef [[
    int  vidcap_init();
    void vidcap_get(unsigned char *ptrFromLua);
    void vidcap_flush();
    void vidcap_cleanup();
]]

function vidcap.init()    return lib.vidcap_init()        end
function vidcap.get(img)  lib.vidcap_get(torch.data(img)) end
function vidcap.flush()   lib.vidcap_flush()              end
function vidcap.cleanup() lib.vidcap_cleanup()            end

-- create and return a ByteTensor which is suitable for subsequent get() calls
function vidcap.create_image()
    local img
    img = torch.ByteTensor(360, 640, 1)
    img = img:permute(3, 1, 2);
    return img
end

return vidcap
