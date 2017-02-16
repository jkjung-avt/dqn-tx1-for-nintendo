--------------------------------------------------------------------------------
--
-- Test code of "vidcap" module
--
-- This should be run from the top directory: (hit Ctrl-C to end it)
-- 
--   $ qlua test/test_vidcap.lua [options]
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-06
--------------------------------------------------------------------------------

require 'torch'
require 'image'

cmd = torch.CmdLine()
cmd:text()
cmd:text('options:')
cmd:option('-save', false, 'whether to save images in the image folder')
cmd:option('-index', 0, 'starting index for the 1st saved image')
cmd:option('-interval', 5, 'frame count between saved images')
cmd:text()
opt = cmd:parse(arg or {})

vidcap = require 'vidcap/vidcap'

img = torch.ByteTensor(360,640,1)
img = img:permute(3,1,2);
cnt = 0          -- frame count
idx = opt.index  -- saved image index

ret = vidcap.init()
assert(ret == 0, 'vidcap.init() failed!')

os.execute('mkdir -p image')
vidcap.flush()
while true do
    --vidcap.vidcap_get(torch.data(img))
    vidcap.get(img)
    win = image.display({image = img, win = win})
    if (opt.save) then
        cnt = cnt + 1
        if cnt >= opt.interval then
            cnt = 0
            image.savePNG(string.format('image/image%04d.png',idx), img)
            idx = (idx+1) % 10000
        end
    end
end

vidcap.cleanup()
