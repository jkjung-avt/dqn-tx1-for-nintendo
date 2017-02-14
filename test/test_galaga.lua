--------------------------------------------------------------------------------
--
-- Test code of "galaga" module
--
-- This should be run from the top directory: (hit Ctrl-C to end it)
-- 
--   $ qlua test/test_galaga.lua [options]
--
--------------------------------------------------------------------------------
-- jkjung, 2017-02-10
--------------------------------------------------------------------------------

require 'torch'
require 'image'

cmd = torch.CmdLine()
cmd:text()
cmd:text('options:')
cmd:option('-frames', 0, 'stops after this many frames (0 means forever)')
cmd:text()
opt = cmd:parse(arg or {})

vidcap = require 'vidcap/vidcap'
galaga = require 'galaga/galaga'

img = torch.ByteTensor(360, 640, 1)
img = img:permute(3, 1, 2);

ret = vidcap.vidcap_init()
assert(ret == 0, 'vidcap_init() failed!')

frame = 0

vidcap.vidcap_flush()
while true do
    vidcap.vidcap_get(torch.data(img))
    win = image.display({image=img, win=win})
    frame = frame + 1

    str = '\rFrame ' .. tostring(frame) .. ' - '
    str = str .. (galaga.has_HIGH(img)   and 'H' or '_')
    str = str .. (galaga.has_Flag(img)   and 'F' or '_')
    str = str .. (galaga.has_RESULT(img) and 'R' or '_')
    str = str .. ', lives=' .. tostring(galaga.get_lives(img))
    str = str .. ', score=' .. tostring(galaga.get_score(img))
    str = str .. '          '
    io.write(str)

    if (opt.frames > 0) then
        if frame >= opt.frames then break end
    end
end

print()  -- print a newline
vidcap.vidcap_cleanup()

