--[[pod_format="raw",created="2025-01-16 06:08:33",modified="2025-01-27 06:01:26",revision=41]]

--Left hand coordination, row vector, right mult matrix
--config area
local DEFAULT_FOCUS_LENGTH = 1



--end of config

include "mathFunc.lua"
include "drawFuncs.lua"
include "objToProcess.lua"
include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
local HALF_X = DRAW_WINDOW_WIDTH//2
local HALF_Y = DRAW_WINDOW_HEIGHT//2




--Obj types:
--[1] Mesh obj with Texture
--[2] Scaled 2d map (no rotation)


--Draw obj types:
--[1] 3d triangle with texture
--[2] Scaled 2d map (no rotation)










--*************************Obj**************************
DrawableObj ={}
DrawableObj.__index = DrawableObj
function DrawableObj:new(objType,position,scale,quat,optionalResourceTable)
    local instance = setmetatable({},DrawableObj)
    instance:Init(objType,position,scale,quat,optionalResourceTable)
    return instance
end

function DrawableObj:Init(objType,position,scale,quat,optionalResourceTable)
    self.objType = objType  or 1
    self.position = position or vec(0,0,0)
    if objType == 1 then
        self.scale = scale or vec(1,1,1)
    else
        self.scale = scale or 1
    end 
    self.quat = quat 
    self.positionInClipSpace = nil
    if type(optionalResourceTable) == "table" then
        for key, value in pairs(optionalResourceTable) do
            self[key] = value
        end
    end
end
setmetatable(DrawableObj, {
    __call = function(_, ...)
        return DrawableObj:new(...)
    end,
})
--*************************Render**************************


Render = {}
Render.__index = Render

function Render:new(drawFuncTable,max_drawItemNum,max_vecNum,nearPlane,farPlane)
    local instance = setmetatable({},Render)
    instance:Init(drawFuncTable,max_drawItemNum,max_vecNum,nearPlane,farPlane)
    return instance
end

function Render:Init(max_drawItemNum,max_vecNum,nearPlane,farPlane,drawFuncTable,processObjFuncsTab)
    self.nearPlane = nearPlane or 0.1
    self.farPlane = farPlane or 100
    self.max_drawItemNum = max_drawItemNum or 1000
    self.max_vecNum = max_vecNum or 1000
    self.camera = Camera:new(DEFAULT_FOCUS_LENGTH,vec(0,0,0),Quat(0,0,0,1))
    self.objTab = {}
    self.drawFuncs = drawFuncTable or drawFuncs
    self.nextBufferedDrawItem = 0
    self.nextBufferedVec = 0
    self.drawBuff = userdata("f64",13,self.max_drawItemNum)
    self.vecBuff = userdata("f64",3,self.max_vecNum)
    self.processObjFuncs = processObjFuncsTab or processObjFuncs
    
end

function Render:ResetDrawBuff()
    self.nextBufferedVec = 0
    self.nextBufferedDrawItem = 0
    self.drawBuff = userdata("f64",13,self.max_drawItemNum)
    
end

function Render:RenderObjs()
    self:ResetDrawBuff()
    if #self.objTab == 0 then
        return
    end
    --print(#self.objTab)
    
    -- sort objs, then add obj to draw list, from near to far
    local sortTable = self:SortObj()
    --print(pod(sortTable))
    for i = 0, #self.objTab -1 do
        
        local index = sortTable:get(1,i,1)
        --print(sortTable:get(0,i,1))
        local o = self.objTab[index]
        local objType = o.objType 
        --print(objType)
        local state = self.processObjFuncs[objType](self,o)
        --if state == false then
            --print("item not added")    
        --end
    end

    --finished the draw table, then draw it
    self:Draw()
end

function Render:SortObj()
    local length = #self.objTab
    for i = 1, length do
        local o = self.objTab[i]
        o.positionInClipSpace = o.position:matmul3d(self.camera.W2ClipMat)
    end
    local sortTable = userdata("f64",2,length)    
    for i = 0, length -1 do
        sortTable:set(0,i,self.objTab[i+1].positionInClipSpace[2],i+1)
    end
    if length > 1 then
        sortTable:sort(0)
    end
    --print(pod(sortTable))
    return sortTable
end

function Render:Draw()
    --print(self.nextBufferedDrawItem)
    local num = self.nextBufferedDrawItem
    if num == 0 then
        return
    elseif num == 1 then
        local sortBuff = self.drawBuff:row(0)
        local objType = sortBuff:get(1,0,1)
        self.drawFuncs[objType](sortBuff,self.vecBuff) 
    else
        local sortBuff = userdata("f64",13,num)
        self.drawBuff:blit(sortBuff,0,0,0,0,13,num)
        --print(#self.drawFuncs)
        sortBuff:sort(0)
        for i = 0,num-1 do
            local objType = sortBuff:get(1,num-1-i,1)
            local record = sortBuff:row(num-1-i)
            self.drawFuncs[objType](record,self.vecBuff) 
        end
    end

end

function Render:AddObjToDrawTable(o)
    table.insert(self.objTab,o)
end

function Render:PopObjFromDrawTable()

end

function Render:CleanDrawTable()

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
















