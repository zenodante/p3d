--[[pod_format="raw",created="2025-01-16 06:08:33",modified="2025-01-18 05:32:36",revision=26]]

--Left hand coordination, row vector, right mult matrix
--config area
local FOCUS_LENGTH = 1
local DRAW_WINDOW_WIDTH =480
local DRAW_WINDOW_HEIGHT = 270
local HALF_X = DRAW_WINDOW_WIDTH//2
local HALF_Y = DRAW_WINDOW_HEIGHT//2
local NEAR_PLANE = 0.1
local MAX_TRI = 1000
local MAX_VEC = 1000
--end of config
local currentBufferedVec = 0
local currentBufferedTri = 0

local vecBuff = userdata("f64",3,MAX_VEC)
local triBuff = userdata("f64",12,MAX_TRI)
local ud = userdata("f64",12,270)

include("mathFunc.lua")

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

function Render:new()
    local instance = setmetatable({},Render)
    instance:Init()
    return instance
end

function Render:Init()
    self.camera = Camera:new(FOCUS_LENGTH,vec(0,0,0),Quat(0,0,0,1))
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


function VecList2Screen(v,o2clipMat)
    local len = v:height()
    local vt = userdata("f64",4,len)   
    vt:add(1,true,0,3,1,0,4,len)
    
    v:blit(vt,0,0,0,0,3,len)
    
    local vc=vt:matmul(o2clipMat)
    --print(pod(vt:row(1)))
    local z = vc:column(2)
    local inv_z = 1/z--get 1/z
    vc:mul(inv_z,true,0,0,1,1,3,len)
	vc:mul(inv_z,true,0,1,1,1,3,len)
    vc:add(vec(1.0,-1.0),true,0,0,2,0,3,len)
    vc:mul(vec(HALF_X,-HALF_Y),true,0,0,2,0,3,len)
    inv_z:blit(vc,0,0,2,0,1,len)
    return vc,z
end

function ResetTriBuff()
    --reset the z value
    --reset the indx
    currentBufferedVec = 0
    currentBufferedTri = 0
    triBuff:mul(0,true,0,0,1,0,12,MAX_TRI)
end

function AddMeshObjToDraw(mObj,position,scale,quat,w2clipMat)
    local veclen = mObj.vector:height()
    local sprite_idx = mObj.uvmapIdx
    if veclen + currentBufferedVec > MAX_VEC then
        print("out of vec buff!")
        return
    end
    local o2wMat = UpdateO2WMat(position,scale,quat)
    local o2clipMat = o2wMat:matmul3d(w2clipMat)
    local vc,zTable = VecList2Screen(mObj.vector,o2clipMat)
    --copy vc to the global vector buffer
    vc:blit(vecBuff,0,0,0,currentBufferedVec,3,veclen)
    local trilen  = mObj.tri:height()
    local x0,y0,x1,y1,x2,y2
    local idx0,idx1,idx2,u0,v0,u1,v1,u2,v2
    local winding
    local z,z0,z1,z2
    for i = 0,trilen-1 do
        idx0,idx1,idx2=mObj.tri:get(0,i,3)
        
        x0,y0=vc:get(0,idx0,2)
        x1,y1=vc:get(0,idx1,2)
        x2,y2=vc:get(0,idx2,2)
        winding = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
        z0=zTable[idx0]
        z1=zTable[idx1]
        z2=zTable[idx2]
        z = z0+z1+z2
        if (winding<=0.0) or z0 < NEAR_PLANE or z1 < NEAR_PLANE or z2 < NEAR_PLANE then
            --do nothing
        else
            u0,v0,u1,v1,u2,v2 = mObj.tex:get(0,i,6)
            idx0 +=currentBufferedVec 
            idx1 +=currentBufferedVec 
            idx2 +=currentBufferedVec 
            triBuff:set(0,currentBufferedTri,z,sprite_idx,idx0,idx1,idx2,u0,v0,u1,v1,u2,v2,0)
            currentBufferedTri +=1
        end
    end
    currentBufferedVec += veclen
end

function DrawTriList()
    triBuff:sort()
    for i = 0,currentBufferedTri do
        local sprite_idx,idx0,idx1,idx2,u0,v0,u1,v1,u2,v2 = triBuff:get(1,i,10)

        RasterizeTri(sprite_idx,vecBuff:row(idx0),vecBuff:row(idx1),vecBuff:row(idx2),u0,v0,u1,v1,u2,v2) 
    end
end
--*************************Draw**************************

function RastHalf(sprite_idx,l,r,lt,rt,lu,lv,ru,rv,lut,lvt,rut,rvt,y0,y1,linvW,rinvW,ltinvW,rtinvW)
    local dy=y1-y0
    local ldx,rdx=(lt-l)/dy,(rt-r)/dy
    local ldu,ldv=(lut-lu)/dy,(lvt-lv)/dy
    local rdu,rdv=(rut-ru)/dy,(rvt-rv)/dy
    local ldinvW,rdinvW = (ltinvW-linvW)/dy, (rtinvW-rinvW)/dy
    local s
    if (y0<0) then
        s=-y0
        y0=0
    else
        s=ceil(y0)-y0
    end
    l,r,lu,lv,ru,rv,linvW,rinvW=l+s*ldx,r+s*rdx,lu+s*ldu,lv+s*ldv,ru+s*rdu,rv+s*rdv,linvW+s*ldinvW,rinvW+s*rdinvW
    y1=min(y1,DRAW_WINDOW_HEIGHT)
    local len=ceil(y1)-ceil(y0)
    if(len<=0) then return end    
    local lm1=len-1
    lt=l+lm1*ldx
    rt=r+lm1*rdx
    lut=lu+lm1*ldu
    lvt=lv+lm1*ldv
    rut=ru+lm1*rdu
    rvt=rv+lm1*rdv
    ltinvW=linvW+lm1*ldinvW
    rtinvW=rinvW+lm1*rdinvW
    --local ud=userdata("f64",12,len)
    ud:set(0,0    ,sprite_idx,l ,ceil(y0)  ,r ,ceil(y0)  ,lu ,lv ,ru ,rv ,linvW,rinvW,0x300)  
    ud:set(0,len-1,sprite_idx,lt,ceil(y1)-1,rt,ceil(y1)-1,lut,lvt,rut,rvt,ltinvW,rtinvW,0x300)  
    tline3d(ud:lerp(0,len-1,12,12,1),0,len,12,12)
end

 

function RasterizeTri(sprite_idx,vec0,vec1,vec2,u0,v0,u1,v1,u2,v2)  
    if(vec0.y > vec1.y) then vec0,vec1=vec1,vec0 u0,v0,u1,v1 = u1,v1,u0,v0 end
    if(vec0.y > vec2.y) then vec0,vec2=vec2,vec0 u0,v0,u2,v2 = u2,v2,u0,v0 end
    if(vec1.y > vec2.y) then vec1,vec2=vec2,vec1 u1,v1,u2,v2 = u2,v2,u1,v1 end  
    local x0,x1,x2=vec0.x,vec1.x,vec2.x
    local y0,y1,y2=vec0.y,vec1.y,vec2.y
    if (y0 >=  DRAW_WINDOW_HEIGHT) or (y2 <0) then return end
    local inv_w0,inv_w1,inv_w2=vec0[2],vec1[2],vec2[2]
    u0,u1,u2=u0*inv_w0,u1*inv_w1,u2*inv_w2
    v0,v1,v2=v0*inv_w0,v1*inv_w1,v2*inv_w2
    local fact = (y1-y0)/(y2-y0)
    local x3 = x0+(x2-x0)*fact
    local u3 = u0+(u2-u0)*fact
    local v3 = v0+(v2-v0)*fact
    local inv_w3 = inv_w0+(inv_w2-inv_w0)*fact 
    RastHalf(sprite_idx,
            x0,x0,x1,x3,
            u0,v0,u0,v0,
            u1,v1,u3,v3,y0,y1,
            inv_w0,inv_w0,inv_w1,inv_w3)
    RastHalf(sprite_idx,
            x1,x3,x2,x2,
            u1,v1,u3,v3,
            u2,v2,u2,v2,y1,y2,
            inv_w1,inv_w3,inv_w2,inv_w2)
end

