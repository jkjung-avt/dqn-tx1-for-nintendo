--------------------------------------------------------------------------------
--
-- "imshow" module
--
-- This module implements image/video display function through FFI
-- interface, by calling the underlying C code which in turn calls the
-- corresponding OpenCV functions.
--
--------------------------------------------------------------------------------
-- jkjung, 2017-03-11
--------------------------------------------------------------------------------

require 'torch'

local ffi = require 'ffi'
local imshow = {}
local lib = ffi.load(paths.cwd() .. '/imshow/libimshow.so')

-- Function prototype definition
ffi.cdef [[
    int  imshow_init(const char *name, int len);
    void imshow_display(unsigned char *buf, int w, int h);
    void imshow_cleanup();
]]

function imshow.init(name)
    name = name or 'imshow'  -- name of the display window
    return lib.imshow_init(name, #name)
end

function imshow.display(img)
    -- expect 'img' to be a (1, H, W) ByteTensor
    assert(img:type() == 'torch.ByteTensor')
    assert(img:dim() == 3)
    lib.imshow_display(img:data(), img:size(3), img:size(2))
end

function imshow.cleanup()
    lib.imshow_cleanup()
end

return imshow
