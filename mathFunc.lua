--[[pod_format="raw",created="2025-01-17 05:38:05",modified="2025-01-22 01:14:26",revision=10]]
--note
--A:add(B, true, 0, 0, 4,  0, 16, 10000)
-- B, source
-- true: to self, nail, to other, or name of other
--0,B source shift
--0 A result shift
--4 length
--0 source shift after each time op
--16 target op shift
--10000 times



include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
local HALF_X = DRAW_WINDOW_WIDTH//2
local HALF_Y = DRAW_WINDOW_HEIGHT//2

function sin_n(n)
   return -sin(n) 
end

function atan2_n(a,b)
    return atan2(a,-b)
end

function asin_n(s)
    local x =sqrt(1-s*s)
    return atan2_n(x,s)
end

function acos_n(c)
    local y = sqrt(1-c*c)
    return atan2_n(c,y)
end


--************************Quaternion class*****************************************************
Quat ={}
Quat.__index = Quat

function Quat:new(...)
    local instance = setmetatable({},self)
    instance:Init(...)
    return instance
end

setmetatable(Quat, {
    __call = function(_, ...)
        return Quat:new(...)
    end,
})

function Quat:Init(...)
    local args = {...}
    if #args == 1 then
        if type(args[1])=="userdata" then
            self.x = args[1][0]
            self.y = args[1][1]
            self.z = args[1][2]
            self.w = args[1][3]
            self:Normalize()
        
        elseif  getmetatable(args[1])==Euler then
            self:EulerAngle(args[1])
        end
    elseif #args == 4 then
        self.x = args[1]
        self.y = args[2]
        self.z = args[3]
        self.w = args[4]
        self:Normalize()
    else
        self.x = 0
        self.y = 0
        self.z = 0
        self.w = 1
    end
end

function Quat.__mul(a,b)
    assert(getmetatable(a) == Quat and getmetatable(b) == Quat, "Operands must be of type Quat")
    local xl,yl,zl,wl = a.x,a.y,a.z,a.w
    local xr,yr,zr,wr = b.x,b.y,b.z,b.w
    local x = wl*xr + xl*wr + yl*zr - zl*yr
    local y = wl*yr + yl*wr + zl*xr - xl*zr
    local z = wl*zr + zl*wr + xl*yr - yl*xr
    local w = wl*wr - xl*xr - yl*yr - zl*zr
    local q = Quat:new(x,y,z,w)
    return q
end

function Quat:__tostring()
    return string.format("Quat(x=%.2f, y=%.2f, z=%.2f, w=%.2f)", self.x, self.y, self.z, self.w)
end

function Quat:Normalize()
    local inv_length = 1.0/sqrt(self.x^2 + self.y^2 + self.z^2 + self.w^2)

    self.x = self.x * inv_length
    self.y = self.y * inv_length
    self.z = self.z * inv_length
    self.w = self.w * inv_length
end

function Quat:Copy()
    return Quat(self.x,self.y,self.z,self.w)
end

function Quat.FromAxisAngle(axis,angle)
    local halfAngle = 0.5 * angle
    local sinh = sin_n(halfAngle)
    local cosh = cos(halfAngle)
    local x,y,z = axis[0],axis[1],axis[2]
    local rx = x * sinh
    local ry = y * sinh
    local rz = z * sinh
    local rw = cosh
    return Quat(rx,ry,rz,rw)
end

function Quat.Identity()
    return Quat(0, 0, 0, 1)
end

function Quat.LookRotation(from, to, up)
    local inv_fact = 1/from:magnitude()
    local aN = from*inv_fact
    inv_fact = 1/to:magnitude()
    local bN = to*inv_fact
    inv_fact = 1/up:magnitude()
    local uN = up*inv_fact

    local dot = aN:dot(bN)

    if dot < -0.9999 then
        return Quat.FromAxisAngle(uN, 0.5)
    elseif dot > 0.9999 then
        return Quat.Identity()
    end

    local rotAngle = 0.25 - asin_n(dot)

    local ortAxis = aN:cross(bN)
    inv_fact = 1/ortAxis:magnitude()


    return Quat.FromAxisAngle(ortAxis*inv_fact, rotAngle)
end

function Quat.LookAt(from,at,up)
    local toObj = at - from
    local zaxis = vec(0,0,1)
    return Quat.LookRotation(zaxis,toObj,up)
end


function Quat.slerp(from, to, t)
    local w0, x0, y0, z0 = from.w, from.x, from.y, from.z
    local w1, x1, y1, z1 = to.w, to.x, to.y, to.z

    local cosOmega = w0 * w1 + x0 * x1 + y0 * y1 + z0 * z1

    if cosOmega < 0.0 then
        w1, x1, y1, z1 = -w1, -x1, -y1, -z1
        cosOmega = -cosOmega
    end

    local k0, k1
    if cosOmega > 0.9999 then
        k0 = 1.0 - t
        k1 = t
    else
        local sinOmega = sqrt(1.0 - cosOmega * cosOmega)
        local omega = atan2_n(sinOmega, cosOmega)
        local oneOverSinOmega = 1.0 / sinOmega
        k0 = sin_n((1.0 - t) * omega) * oneOverSinOmega
        k1 = sin_n(t * omega) * oneOverSinOmega
    end

    local w = w0 * k0 + w1 * k1
    local x = x0 * k0 + x1 * k1
    local y = y0 * k0 + y1 * k1
    local z = z0 * k0 + z1 * k1

    return Quat(x, y, z, w)
end

function Quat.XRotate(angle)
    local halfAngle = 0.5*angle
    local cosh = cos(halfAngle) 
    local sinh = sin_n(halfAngle)
    return Quat(sinh,0,0,cosh)
end

function Quat.YRotate(angle)
    local halfAngle = 0.5*angle
    local cosh = cos(halfAngle) 
    local sinh = sin_n(halfAngle)
    return Quat(0,sinh,0,cosh)
end

function Quat.ZRotate(angle)
    local halfAngle = 0.5*angle
    local cosh = cos(halfAngle) 
    local sinh = sin_n(halfAngle)
    return Quat(0,0,sinh,cosh)
end
--YXZ order
function Quat:EulerAngle(eulerAngle)
    if eulerAngle != nil then -- quat to euler
        
        local x,y,z = eulerAngle.x,eulerAngle.y,eulerAngle.z
        local cp = cos(x * 0.5); 
        local ch = cos(y * 0.5);
        local cb = cos(z * 0.5); 
        local sp = sin_n(x * 0.5);
        local sh = sin_n(y * 0.5); 
        local sb = sin_n(z * 0.5);
        self.w = ch * cp * cb + sh * sp * sb
        self.x = ch * sp * cb + sh * cp * sb
        self.y = sh * cp * cb - ch * sp * sb
        self.z = ch * cp * sb - sh * sp * cb
    else
        local returne = Euler:new(self)
        return returne
    end
end

function Quat:Matrix(rowNum)
    rowNum = rowNum or 3
    local mat = userdata("f64",3,rowNum)
    local x,y,z,w = self.x,self.y,self.z,self.w
    --m 0 0 column row
    local xx = x * x
    local yy = y * y
    local zz = z * z
    local xy = x * y
    local xz = x * z
    local yz = y * z
    local wx = w * x
    local wy = w * y
    local wz = w * z
    local m00 = 1.0 - 2.0 * (yy + zz)
    local m01 = 2.0 * (xy - wz)
    local m02 = 2.0 * (xz + wy)
    local m10 = 2.0 * (xy + wz)
    local m11 = 1.0 - 2.0 * (xx + zz)
    local m12 = 2.0 * (yz - wx)
    local m20 = 2.0 * (xz - wy)
    local m21 = 2.0 * (yz + wx)
    local m22 = 1.0 - 2.0 * (xx + yy)
    mat:set(0,0,m00,m10,m20,m01,m11,m21,m02,m12,m22)
    return mat
end
--************************Euler class*****************************************************
Euler = {}
Euler.__index = Euler

function Euler:new(...)
    local instance = setmetatable({},self)
    instance:Init(...)
    return instance
end
setmetatable(Euler, {
    __call = function(_, ...)
        return Euler:new(...)
    end,
})

function Euler:Init(...)
    local args = {...}
    if #args == 1 then
        if type(args[1])=="userdata" then
            self.x = args[1][0]
            self.y = args[1][1]
            self.z = args[1][2]       
        elseif  getmetatable(args[1])==Quat then
            self:Quaternion(args[1])
        end
    elseif #args == 3 then
        self.x = args[1]
        self.y = args[2]
        self.z = args[3]
    else
        self.x = 0
        self.y = 0
        self.z = 0
    end
end
function Euler:__tostring()
    return string.format("Euler(x=%.2f, y=%.2f, z=%.2f)", self.x, self.y, self.z)
end

function Euler:Quaternion(quat)
    if quat != nil then
        local x, y, z, w = quat.x, quat.y, quat.z, quat.w

        local sp = -2.0 * (y * z - w * x)
        if (abs(sp) > 0.9999) then
            self.x = 0.25 * sp
            self.y = atan2_n(-x * z + w * y, 0.5 - y * y - z * z)
            self.z = 0.0
        else 
            self.x = asin_n(sp)
            self.y = atan2_n(x * z + w * y, 0.5 - x * x - y * y)
            self.z = atan2_n(x * y + w * z, 0.5 - x * x - z * z)
        end
    else
        local returnq = Quat:new(self)
        return returnq
    end
end

function Euler:Matrix(rowNum)
    rowNum = rowNum or 3
    local mat = userdata("f64",3,rowNum)
    local x,y,z = self.x,self.y,self.z
    
    local sx = sin_n(x)
    local sy = sin_n(y)
    local sz = sin_n(z)
    local cx = cos(x) 
    local cy = cos(y) 
    local cz = cos(z)

    local m00 = (cy * cz) + (sy * sx * sz)
    local m01 = (cz * sy * sx) - (cy * sz)
    local m02 = (cx * sy)
    local m10 = (cx * sz)
    local m11 = (cx * cz)
    local m12 = -1.0 * sx
    local m20 = (cy * sx * sz) - (cz * sy)
    local m21 = (cy * cz * sx) + (sy * sz)
    local m22 = (cy * cx)
    mat:set(0,0,m00,m10,m20,m01,m11,m21,m02,m12,m22)
    return mat
end

--**********************matrix*************************************************



function UpdateO2WMat(position,scale,quat)
    local resultm34 = quat:Matrix(4) --create 3*4 matrix

    local scaleX = scale.x
    local scaleY = scale.y
    local scaleZ = scale.z
    
    resultm34:mul(scaleX,true,0,0,3)--apply the x,y,z scale  
    resultm34:mul(scaleY,true,0,3,3)
    resultm34:mul(scaleZ,true,0,6,3)
    position:blit(resultm34,0,0,0,3,3,1)
    return resultm34
end

function AABBTest(xMax,xMin,yMax,yMin,zMax,zMin,o2clipMat,farPlane,nearPlane)
    --print(string.format("x: %3.3f %3.3f y: %3.3f %3.3f z: %3.3f %3.3f ", xMax,xMin,yMax,yMin,zMax,zMin))
    local aabb = userdata("f64",3,8)
    aabb:set(0,0,xMax,yMax,zMax,
                 xMax,yMax,zMin,
                 xMax,yMin,zMax,
                 xMax,yMin,zMin,
                 xMin,yMax,zMax,
                 xMin,yMax,zMin,
                 xMin,yMin,zMax,
                 xMin,yMin,zMin)
    local o2clipMat33 = userdata("f64",3,3)
    local o2clipxyz = userdata("f64",3,1)
    o2clipMat:blit(o2clipMat33,0,0,0,0,3,3)
    o2clipMat:blit(o2clipxyz,0,3,0,0,3,1)  
    local vc=aabb:matmul(o2clipMat33)
    vc:add(o2clipxyz,true,0,0,3,0,3,8)
    local z = vc:column(2)
    local inv_z = 1/z--get 1/z
    vc:mul(inv_z,true,0,0,1,1,3,8)
	vc:mul(inv_z,true,0,1,1,1,3,8)
    --now aabb in clip space
    local clipMin, clipMax = -1, 1
    vc:sort(0)
    xMax = vc:get(0,7,1)
    xMin = vc:get(0,0,1)
    vc:sort(1)
    yMax = vc:get(1,7,1)
    yMin = vc:get(1,0,1)
    vc:sort(2)
    zMax = vc:get(2,7,1)
    zMin = vc:get(2,0,1)
    --print(string.format("x: %3.3f %3.3f y: %3.3f %3.3f z: %3.3f %3.3f ", xMax,xMin,yMax,yMin,zMax,zMin))
    local xOverlap = not (xMin > clipMax or xMax < clipMin)
    local yOverlap = not (yMin > clipMax or yMax < clipMin)
    local zOverlap = not (zMin > farPlane or zMax < nearPlane)
    return xOverlap and yOverlap and zOverlap  
end

function VecList2Screen(v,o2clipMat)
    local len = v:height()
    local o2clipMat33 = userdata("f64",3,3)
    local o2clipxyz = userdata("f64",3,1)
    o2clipMat:blit(o2clipMat33,0,0,0,0,3,3)
    o2clipMat:blit(o2clipxyz,0,3,0,0,3,1)
    local vc=v:matmul(o2clipMat33)
    vc:add(o2clipxyz,true,0,0,3,0,3,len)
    local z = vc:column(2)
    local inv_z = 1/z--get 1/z
    vc:mul(inv_z,true,0,0,1,1,3,len)
	vc:mul(inv_z,true,0,1,1,1,3,len)
    vc:add(vec(1.0,-1.0),true,0,0,2,0,3,len)
    vc:mul(vec(HALF_X,-HALF_Y),true,0,0,2,0,3,len)
    inv_z:blit(vc,0,0,2,0,1,len)
    return vc,z
end

