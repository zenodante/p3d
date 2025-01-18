--[[pod_format="raw",created="2025-01-15 06:15:47",modified="2025-01-17 23:41:37",revision=12]]
--include("palman.lua")

include("3d.lua")

--local camera = Camera:new(1,vec(3,4,5))
render = Render:new()
local sph = userdata("f64",3,4)
local sphTable = userdata("f64",2,4)
local sortTable = userdata("f64",3,4)
function _init()
	--c,m = fetch("/test.pod")
	--palette = m.palette
	--palette = split(palette,"\n",false)
	--for i = 1, #palette do
	--		local hexstr = "0x00"..palette[i]
	--		local nmbr = tonum(hexstr)
			--print(palette[i])
	--		poke4(0x5000 + 4 * (i-1),nmbr)
	--end
    --set_spr(0, c)

    sphTable:set(0,0,
                 0,1,
                 1,2,
                 2,3,
                 3,4)

    sph:set(0,0, 10,10,15,
                 12,5,20,
                 0,0,10,
                 -20,-4,5)
    render.camera:position(vec(0,0,-20))
    
end

function _draw()
    cls(0)
    --print(pod(render.camera:position()))
    print(pod({sphTable:get(0,0,6)}))
    --print(pod(ve))
    local w2c = render.camera.W2ClipMat
    local vc,z =VecList2Screen(sph,w2c)
    --local sphInC = sph:matmul3d(w2c)
    sphTable:blit(sortTable,0,0,0,0,2,4)
    z:blit(sortTable,0,0,2,0,1,4)
    sortTable:sort(2)
    
    for i =0,3 do
        local idx,color = sortTable:get(0,i,2)
        local x,y,inv_z=vc:row(idx):get()
        local r = 100*inv_z
        circfill(x,y,r,color)
    end
    --v0=vec(70,70,1)
    --v1=vec(10,130,1/2)
    --v2=vec(70,190,1/2)
    --uv0=vec(63,128)
    --uv1=vec(48,128)
    --uv2=vec(48,143)
    --RasterizeTri(0,v0,v1,v2,uv0,uv1,uv2)
end

function _update()
    local cp = render.camera:position()
    if btn(0) then
        render.camera:position(cp:add(-0.1,true,0,0,1))
    end
    if btn(1) then
        render.camera:position(cp:add(0.1,true,0,0,1))
    end
    if btn(2) then
        render.camera:position(cp:add(0.1,true,0,2,1))
    end
    if btn(3) then
        render.camera:position(cp:add(-0.1,true,0,2,1))
    end

end

