--[[pod_format="raw",created="2025-01-15 06:15:47",modified="2025-01-17 23:41:37",revision=12]]
--include("palman.lua")

include("3d.lua")

--local camera = Camera:new(1,vec(3,4,5))
render = Render:new()
local sph = userdata("f64",3,4)
local sphTable = userdata("f64",2,4)
local sortTable = userdata("f64",3,4)
local mesh = fetch("testObj.pod")
function _init()
	local c,m = fetch("test.pod")
	palette = m.palette
	palette = split(palette,"\n",false)
	for i = 1, #palette do
			local hexstr = "0x00"..palette[i]
			local nmbr = tonum(hexstr)
			--print(palette[i])
			poke4(0x5000 + 4 * (i-1),nmbr)
	end
    set_spr(0, c)

    sphTable:set(0,0,
                 0,1,
                 1,2,
                 2,3,
                 3,4)

    sph:set(0,0, 10,10,15,
                 12,5,20,
                 0,0,0,
                 -20,-4,5)
    render.camera:position(vec(0,5,-20))
    
end

function _draw()
    cls(0)
    --print(pod(mesh.vector:height()))
    --print(pod(render.camera:position()))
    --print(pod({sphTable:get(0,0,6)}))
    --print(pod(ve))
    render.camera:LookAt(vec(0,0,0),vec(0,1,0))
    ResetTriBuff()
    --print(pod(mesh.tex))
    --cal o2wMat = UpdateO2WMat(vec(0,0,0),vec(1,1,1),Quat(0,0,0,1))
    --cal o2clipMat = o2wMat:matmul3d(render.camera.W2ClipMat)
    --print(pod(o2clipMat))
    --VecList2Screen(mesh.vector,o2clipMat)
    local q=Quat.YRotate(0.35)
    AddMeshObjToDraw(mesh,vec(0,0,0),vec(1,1,1),q,render.camera.W2ClipMat)

    DrawTriList()
    print(string.format("cpu: %3.3f (%dfps)", stat(1), stat(7)), 10, 10, 1)


    --local w2c = render.camera.W2ClipMat
    --local vc,z =VecList2Screen(sph,w2c)
    --local sphInC = sph:matmul3d(w2c)
    --sphTable:blit(sortTable,0,0,0,0,2,4)
    --z:blit(sortTable,0,0,2,0,1,4)
    --sortTable:sort(2)
    
    --for i =0,3 do
    --    local idx,color = sortTable:get(0,i,2)
    --    local x,y,inv_z=vc:row(idx):get()
    --    local r = 100*inv_z
    --    circfill(x,y,r,color)
    --end
    --local vec0=vec(70,70,1)
    --local vec1=vec(10,130,1/2)
    --local vec2=vec(70,190,1/2)
    --local u0,v0=63,128
    --local u1,v1=48,128
    --local u2,v2=48,143
    --RasterizeTri(0,vec0,vec1,vec2,u0,v0,u1,v1,u2,v2)
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

