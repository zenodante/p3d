--[[pod_format="raw",created="2025-01-15 06:15:47",modified="2025-01-22 16:14:31",revision=14]]

include "3d.lua"


local render = Render:new()

local houseMesh = fetch("testObj.pod")
local building =DrawableObj(1,vec(0,0,0),vec(1,1,1),Quat.YRotate(0.35),{["mesh"]=houseMesh})

function _init()
	local c,m = fetch("test.pod")
	local palette = m.palette
	palette = split(palette,"\n",false)
	for i = 1, #palette do
			local hexstr = "0x00"..palette[i]
			local nmbr = tonum(hexstr)
			poke4(0x5000 + 4 * (i-1),nmbr)
	end
    set_spr(0, c)

    
    render.camera:position(vec(0,5,-20))
    render:AddObjToDrawTable(building)
end

function _draw()
    cls(0)
    --print(building.objType)
    render.camera:LookAt(vec(0,0,0),vec(0,1,0))
    render:RenderObjs()
    print(string.format("cpu: %3.3f (%dfps)", stat(1), stat(7)), 10, 10, 1)

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

