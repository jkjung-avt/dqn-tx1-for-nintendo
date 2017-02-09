--------------------------------------------------------------------------------
--
-- Test code of vidcap FFI library
--
-- To be run from the top directory:
-- 
-- $ qlua test/test_vidcap.lua
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-06
--------------------------------------------------------------------------------

require 'torch'
require 'image'

-- FFI stuff -------------------------------------------------------------------

local ffi = require 'ffi'
local vidcap = ffi.load(paths.cwd() .. '/vidcap/libvidcap.so')

-- Function prototype definition
ffi.cdef [[
    int  vidcap_init();
    void vidcap_get(unsigned char *ptrFromLua);
    void vidcap_flush();
    void vidcap_cleanup();
]]

-- Main program ----------------------------------------------------------------

img = torch.ByteTensor(360,640,1)
img = img:permute(3,1,2);
cnt = 0  -- frame count
idx = 0  -- saved image index

ret = vidcap.vidcap_init()
if ret < 0 then
    print('vidcap_init() failed!')
    os.exit()
end

--os.execute('mkdir -p image')
vidcap.vidcap_flush()
while true do
    vidcap.vidcap_get(torch.data(img))
    win = image.display({image=img, win=win})
    --cnt = cnt + 1
    --if cnt >= 30 then
    --        cnt = 0
    --        image.save(string.format('image/image%03d.png',idx), img)
    --        idx = (idx+1) % 1000
    --end
end

vidcap.vidcap_cleanup()

