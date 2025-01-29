include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
local HALF_X = DRAW_WINDOW_WIDTH//2
local HALF_Y = DRAW_WINDOW_HEIGHT//2

function TextureMeshObjToDraw(rnd,o)
    local np = rnd.nearPlane
    local fp = rnd.farPlane
    local mesh = o.mesh
    local veclen = mesh.vector:height()
    local sprite_idx = o.sprite_idx
    local vecBuff = rnd.vecBuff
    local drawBuff = rnd.drawBuff
    local max_drawItemNum = rnd.max_drawItemNum
    
    local o2wMat = UpdateO2WMat(o.position,o.scale,o.quat)
    local o2clipMat = o2wMat:matmul3d(rnd.camera.W2ClipMat)
    if mesh.aabb != nil then
        local xMax,yMax,zMax,xMin,yMin,zMin = mesh.aabb:get()
        if  not AABBTest(xMax,xMin,yMax,yMin,zMax,zMin,o2clipMat,fp,np) then
            return false
        end
    end
    if veclen + rnd.nextBufferedVec > rnd.max_vecNum then
        --print("out of vec buff!")
        return false
    end

    local vc,zTable = VecList2Screen(mesh.vector,o2clipMat)
    --copy vc to the global vector buffer
    vc:blit(vecBuff,0,0,0,rnd.nextBufferedVec,3,veclen)
    local trilen  = mesh.tri:height()
    local x0,y0,x1,y1,x2,y2
    local idx0,idx1,idx2,u0,v0,u1,v1,u2,v2
    local winding
    local z,z0,z1,z2

    for i = 0,trilen-1 do
        if rnd.nextBufferedDrawItem >= max_drawItemNum then
            return false
        end
        idx0,idx1,idx2=mesh.tri:get(0,i,3)
        
        x0,y0=vc:get(0,idx0,2)
        x1,y1=vc:get(0,idx1,2)
        x2,y2=vc:get(0,idx2,2)
        winding = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
        z0=zTable[idx0]
        z1=zTable[idx1]
        z2=zTable[idx2]
        z = z0+z1+z2
        --print(z)
        if (winding<=0.0) or z0 < np or z1 < np or z2 < np then
            --do nothing
        else
            u0,v0,u1,v1,u2,v2 = mesh.tex:get(0,i,6)
            idx0 +=rnd.nextBufferedVec 
            idx1 +=rnd.nextBufferedVec 
            idx2 +=rnd.nextBufferedVec
            drawBuff:set(0,rnd.nextBufferedDrawItem,z,1,4,sprite_idx,idx0,idx1,idx2,u0,v0,u1,v1,u2,v2)
            rnd.nextBufferedDrawItem +=1
            --print("added")
        end
    end
    rnd.nextBufferedVec += veclen
    return true
end

function SpriteObjToDraw(rnd,o)
    --local zInClip = o.position:matmul3d(W2ClipMat) --it has been checked
    if rnd.nextBufferedDrawItem >= rnd.max_drawItemNum then
        return false
    end
    local p = o.positionInClipSpace
    if p[2] < rnd.nearPlane or p[2] > rnd.farPlane then
        return false
    end
    local inv_z = 1.0/p[2]
    local x = (p[0]*inv_z +1.0)*HALF_X
    local y = (1.0-p[1]*inv_z)*HALF_Y
    local cw = o.sw*inv_z*o.scale*HALF_X
    local ch = o.sh*inv_z*o.scale*HALF_X

    
        --calculate the params
    local cx = x  - 0.5*cw
    local cy = y  - 0.5*ch
    if cx> DRAW_WINDOW_WIDTH or cy > DRAW_WINDOW_HEIGHT or cx + cw < 0 or cy + ch < 0 then
        --out of the screen
        return false
    end
    local sprite_idx = o.sprite_idx
    local sx = o.sx
    local sy = o.sy
    local sw = o.sw
    local sh = o.sh 
    rnd.drawBuff:set(0,rnd.nextBufferedDrawItem,p[2]*3,2,4,sprite_idx,sx,sy,sw,sh,cx,cy,cw,ch)
    rnd.nextBufferedDrawItem +=1
    return true
    
end

processObjFuncs = {
    [1] = TextureMeshObjToDraw,
    [2] = SpriteObjToDraw
}