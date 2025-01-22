--[[pod_format="raw",created="2025-01-16 06:08:33",modified="2025-01-22 06:27:19",revision=38]]

--Left hand coordination, row vector, right mult matrix
--config area
local FOCUS_LENGTH = 1
local DRAW_WINDOW_WIDTH =480
local DRAW_WINDOW_HEIGHT = 270


--end of config
local nextBufferedVec = 0
local nextBufferedTri = 0

local vecBuff = userdata("f64",3,MAX_VEC)
local triBuff = userdata("f64",12,MAX_TRI)


include "mathFunc.lua"
include "drawFuncs.lua"
-- basic functions

function Class(base)
    local cls = base or {}
    cls.__index = cls

    function cls:new(o, ...)
        o = o or {}
        setmetatable(o, self)
        if self.init then
            self:init(...)
        end
        return o
    end

    return cls
end





--************************* Math **************************
--A:add(B, true, 0, 0, 4,  0, 16, 10000)
-- B, source
-- true: to self, nail, to other, or name of other
--0,B source shift
--0 A result shift
--4 length
--0 source shift after each time op
--16 target op shift
--10000 times













--*************************Obj**************************
DrawableObj ={}
DrawableObj.__index = DrawableObj
function DrawableObj:new(position,scale,quat)
    local instance = setmetatable({},DrawableObj)
    instance:init(position,scale,quat)
    return instance
end

function DrawableObj:init(position,scale,quat)

    self._position = position or vec(0,0,0)
    self._scale = scale or vec(1,1,1)
    self._quat = quat or Quat(0,0,0,1)
end

--*************************Render**************************


Render = {}
Render.__index = Render

function Render:new(drawFuncTable,max_drawItemNum,max_vecNum,nearPlane)
    local instance = setmetatable({},Render)
    instance:Init(drawFuncTable,max_drawItemNum,max_vecNum,nearPlane)
    return instance
end

function Render:Init(drawFuncTable,max_drawItemNum,max_vecNum,nearPlane)
    self.nearPlane = nearPlane or 0.1
    self.max_drawItemNum = max_drawItemNum or 1000
    self.max_vecNum = max_vecNum or 1000
    self.camera = Camera:new(FOCUS_LENGTH,vec(0,0,0),Quat(0,0,0,1))
    self.objTab = {}
    self.drawFuncs = drawFuncTable or drawFuncs
    self.nextBufferedDrawItem = 0
    self.nextBufferedVec = 0
    self.drawBuff = userdata("f64",12,self.max_drawItemNum)
    self.vecBuff = userdata("f64",3,self.max_vecNum)
    self.processObjFuncs = {
        [1] = self.TextureMeshObjToDraw
    }
    
end

function Render:ResetDrawBuff()
    self.nextBufferedVec = 0
    self.nextBufferedDrawItem = 0
    self.drawBuff = userdata("f64",12,self.max_drawItemNum)
    
end

function Render:RenderObjs()
    self:ResetDrawBuff()
    --print(#self.objTab)
    for i = 1, #self.objTab do
        local o = self.objTab[i]
        local objType = o.objType 
        self.processObjFuncs[objType](self,o)
        --depends on obj type, call different process and check to add to draw table
    end
    --finished the draw table, then draw it
    self:Draw()
end

function Render:Draw()
    local num = self.nextBufferedDrawItem- 1
    local sortBuff = userdata("f64",12,num)
    self.drawBuff:blit(sortBuff,0,0,0,0,12,num)
    --print(#self.drawFuncs)
    sortBuff:sort(0)
    for i = 0,num-1 do
        local objType = sortBuff:get(11,num-1-i,1)
        local record = sortBuff:row(num-1-i)
        
        self.drawFuncs[objType](record,self.vecBuff) 
    end
end

function Render:AddObjToDrawTable(o)
    table.insert(self.objTab,o)
end

function Render:PopObjFromDrawTable()

end

function Render:CleanDrawTable()

end

function Render:TextureMeshObjToDraw(o)
    local np = self.nearPlane
    local mesh = o.mesh
    local position = o.position
    local scale  = o.scale
    local quat = o.quat
    local W2ClipMat = self.camera.W2ClipMat
    local veclen = mesh.vector:height()
    local sprite_idx = mesh.uvmapIdx
    if veclen + self.nextBufferedVec > self.max_vecNum then
        print("out of vec buff!")
        return
    end
    local o2wMat = UpdateO2WMat(position,scale,quat)
    local o2clipMat = o2wMat:matmul3d(W2ClipMat)
    local vc,zTable = VecList2Screen(mesh.vector,o2clipMat)
    --copy vc to the global vector buffer
    vc:blit(self.vecBuff,0,0,0,self.nextBufferedVec,3,veclen)
    local trilen  = mesh.tri:height()
    local x0,y0,x1,y1,x2,y2
    local idx0,idx1,idx2,u0,v0,u1,v1,u2,v2
    local winding
    local z,z0,z1,z2
    for i = 0,trilen-1 do
        idx0,idx1,idx2=mesh.tri:get(0,i,3)
        
        x0,y0=vc:get(0,idx0,2)
        x1,y1=vc:get(0,idx1,2)
        x2,y2=vc:get(0,idx2,2)
        winding = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
        z0=zTable[idx0]
        z1=zTable[idx1]
        z2=zTable[idx2]
        z = z0+z1+z2
        if (winding<=0.0) or z0 < np or z1 < np or z2 < np then
            --do nothing
        else
            u0,v0,u1,v1,u2,v2 = mesh.tex:get(0,i,6)
            idx0 +=nextBufferedVec 
            idx1 +=nextBufferedVec 
            idx2 +=nextBufferedVec 
            self.drawBuff:set(0,self.nextBufferedDrawItem,z,sprite_idx,idx0,idx1,idx2,u0,v0,u1,v1,u2,v2,1)
            self.nextBufferedDrawItem +=1
        end
    end
    self.nextBufferedVec += veclen
end
--*************************Camera**************************
Camera = {}
Camera.__index = Camera

function Camera:new(focusLength,position,quat)
    local instance = setmetatable({},Camera)
    instance:Init(focusLength,position,quat)
    return instance

end

function Camera:__tostring()
    local x,y,z = self._pos[0], self._pos[1], self._pos[2]
    local eu = self._quat:EulerAngle()
    local ex,ey,ez = eu.x, eu.y, eu.z
    return string.format("[Camposition x=%.2f, y=%.2f, z=%.2f]\n[Eulerangle x=%.2f, y=%.2f, z=%.2f]\n[FocusLength %.2f AspectRatio %.2f]", x, y, z,ex,ey,ez,self._focusLength,self._aspectRatio)
end

function Camera:Init(focusLength,position,quat)
    self._pos = position or vec(1,1,1)
    self._quat = quat or Quat(0,0,0,1)
    self._focusLength = focusLength or 1 
    self._aspectRatio = DRAW_WINDOW_WIDTH/DRAW_WINDOW_HEIGHT
    self.W2CameraMat = nil
    self.W2ClipMat = nil
    self.clipMat = nil
    self:UpdataMatrix()
end

function Camera:UpdataMatrix()
    self.W2CameraMat= self:ResetW2CameraMat()
    self.clipMat= self:ResetClipMat()
    self.W2ClipMat = self.W2CameraMat:matmul3d(self.clipMat)
end

function Camera:ResetClipMat()
    local focusLength =self._focusLength
    local aspectRatio = self._aspectRatio
    local cMat = userdata("f64",3,4)
    cMat:set(0,0,focusLength,        0              ,0,
                    0       ,focusLength*aspectRatio,0,
                    0       ,        0              ,1,
                    0       ,        0              ,0)
    return cMat
end

function Camera:ResetW2CameraMat()
    local quat = self._quat
    local position = self._pos
    local resultm34 = userdata("f64",3,4)
    local tempM33 = quat:Matrix(3):transpose()
    tempM33:blit(resultm34,0,0,0,0,3,3)
    
    local camPosition = -1*position

    camPosition:matmul(tempM33):blit(resultm34,0,0,0,3,3,1)
    return resultm34
end


function Camera:position(...)
    local args = { ... }
    if #args == 0 then
        return self._pos
    elseif #args == 1 then
        self._pos = args[1]:add(0)
    elseif #args == 3 then
        self._pos = vec(args[1],args[2],args[3])       
    end
    self:UpdataMatrix()
end

function Camera:quaternion(...)
    local args = { ... }
    if #args == 0 then
        return self._quat:Copy()
    elseif #args == 1 then
        self._quat = args[1]
    elseif #args == 4 then
        self._quat = Quat(args[1],args[2],args[3],args[4])
    end 
    self:UpdataMatrix()
end

function Camera:focusLength(value)
    if value ==nil then
        return self._focusLength
    else
        self._focusLength = value
        self:UpdataMatrix()
    end 
end

function Camera:aspectRatio(value)
    if value ==nil then
        return self._aspectRatio
    else
        self._aspectRatio = value
        self:UpdataMatrix()
    end 
end

function Camera:LookAt(target_v,up_v)

    self._quat = Quat.LookAt(self._pos,target_v,up_v)
    self:UpdataMatrix()
end
















