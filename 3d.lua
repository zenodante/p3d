--[[pod_format="raw",created="2025-01-16 06:08:33",modified="2025-01-17 06:44:33",revision=10]]
--config area
local FOCUS_LENGTH = 1
local draw_window_width =480
local draw_window_height = 270
local half_x = draw_window_width//2
local half_y = draw_window_height//2
local MAX_TRI = 1000
--end of config
local currentFreeTriIndx = 0
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
    instance:init()
    return instance
end

function Render:init()
    self.camera = Camera:new(FOCUS_LENGTH,vec(0,0,0),Quat(0,0,0,1))
end


--*************************Camera**************************
Camera = {}
Camera.__index = Camera

function Camera:new(focusLength,position,quat)
    local instance = setmetatable({},Camera)
    instance:init(focusLength,position,quat)
    return instance

end

function Camera:__tostring()
    local x,y,z = self._pos[0], self._pos[1], self._pos[2]
    local eu = self._quat:EulerAngle()
    local ex,ey,ez = eu.x, eu.y, eu.z
    return string.format("[Camposition x=%.2f, y=%.2f, z=%.2f]\n[Eulerangle x=%.2f, y=%.2f, z=%.2f]\n[FocusLength %.2f AspectRatio %.2f]", x, y, z,ex,ey,ez,self._focusLength,self._aspectRatio)
end

function Camera:init(focusLength,position,quat)
    self._pos = position or vec(1,1,1)
    self._quat = quat or Quat(0,0,0,1)
    self._focusLength = focusLength or 1 
    self._aspectRatio = draw_window_width/draw_window_height
    self.W2Cmatrix = nil
    self.W2ScreenMatrix = nil
    self.projectionMatrix = nil
    self:UpdataMatrix()
end

function Camera:UpdataMatrix()
    self.W2Cmatrix= self:ResetW2CameraMat()
    self.projectionMAtrix= self:ResetClipMat()
    self.W2ScreenMatrix = self.W2Cmatrix:matmul3d(self.projectionMAtrix)
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
    else
        s=ceil(y0)-y0
    end
    l,r,lu,lv,ru,rv,linvW,rinvW=l+s*ldx,r+s*rdx,lu+s*ldu,lv+s*ldv,ru+s*rdu,rv+s*rdv,linvW+s*ldinvW,rinvW+s*rdinvW
    y1=min(y1,draw_window_height)
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

 

function RasterizeTri(sprite_idx,vec0,vec1,vec2,uv0,uv1,uv2)  
    if(vec0.y > vec1.y) then vec0,vec1=vec1,vec0 uv0,uv1 = uv1,uv0 end
    if(vec0.y > vec2.y) then vec0,vec2=vec2,vec0 uv0,uv2 = uv2,uv0 end
    if(vec1.y > vec2.y) then vec1,vec2=vec2,vec1 uv1,uv2 = uv2,uv1 end  
    local x0,x1,x2=vec0.x,vec1.x,vec2.x
    local y0,y1,y2=vec0.y,vec1.y,vec2.y
    if (y0 >=  draw_window_height) or (y2 <0) then return end
    local inv_w0,inv_w1,inv_w2=vec0[2],vec1[2],vec2[2]
    local u0,u1,u2=uv0[0]*inv_w0,uv1[0]*inv_w1,uv2[0]*inv_w2
    local v0,v1,v2=uv0[1]*inv_w0,uv1[1]*inv_w1,uv2[1]*inv_w2
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

