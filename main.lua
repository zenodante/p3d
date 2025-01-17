--[[pod_format="raw",created="2025-01-15 06:15:47",modified="2025-01-17 06:21:47",revision=6]]
--include("palman.lua")

include("3d.lua")

--local camera = Camera:new(1,vec(3,4,5))
render = Render:new()
function _init()
	c,m = fetch("/test.pod")
	palette = m.palette
	palette = split(palette,"\n",false)
	for i = 1, #palette do
			local hexstr = "0x00"..palette[i]
			local nmbr = tonum(hexstr)
			--print(palette[i])
			poke4(0x5000 + 4 * (i-1),nmbr)
	end
    set_spr(0, c)

    
end

function _draw()
    cls(0)
    t=O2WMat(vec(3,4,5),vec(1,2,3),Quat(0,0,0,1))
    render.camera:focusLength(5)
    print(pod(render.camera.W2ScreenMatrix))
    quat0 = Quat(0,0,0,1)
    quat1 = Quat.XRotate(0.125)
    quat2 = quat0*quat1
    render.camera:position(vec(3,4,5))
    print(pod(render.camera:position()))
    render.camera:position(7,8,9)
    print(pod(render.camera:position()))
    render.camera:LookAt(vec(5,5,3),vec(0,1,0))
    print(tostr(render.camera:quaternion()))
    v0=vec(70,70,1)
    v1=vec(10,130,1/2)
    v2=vec(70,190,1/2)
    uv0=vec(63,128)
    uv1=vec(48,128)
    uv2=vec(48,143)
    RasterizeTri(0,v0,v1,v2,uv0,uv1,uv2)
end

function _update()

end

