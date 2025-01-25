include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
--local DRAW_WINDOW_WIDTH = 480
--local DRAW_WINDOW_HEIGHT = 270

local ud = userdata("f64",12,270)
--[[
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
    local cy0=ceil(y0)
    local cy1=ceil(y1)
    local len=cy1-cy0
    if(len<=0) then return end 
    --local ud=userdata("f64",12,len)
    if len == 1 then
        ud:set(0,0  ,sprite_idx,l ,cy0,r ,cy0,lu ,lv ,ru ,rv ,linvW ,rinvW ,0x300)  
        tline3d(ud:row(0))
        return
    end
    local lm1=len-1
    lt=l+lm1*ldx
    rt=r+lm1*rdx
    lut=lu+lm1*ldu
    lvt=lv+lm1*ldv
    rut=ru+lm1*rdu
    rvt=rv+lm1*rdv
    ltinvW=linvW+lm1*ldinvW
    rtinvW=rinvW+lm1*rdinvW
    
    ud:set(0,0  ,sprite_idx,l ,cy0,r ,cy0,lu ,lv ,ru ,rv ,linvW ,rinvW ,0x300)  
    ud:set(0,len-1,sprite_idx,lt,cy1-1,rt,cy1-1,lut,lvt,rut,rvt,ltinvW,rtinvW,0x300)  
    --ud:set(0,0  ,3,l ,cy0,r ,cy0,1 ,1 ,2,1 ,linvW ,rinvW ,0x300)  
    --ud:set(0,len-1,3,lt,cy1-1,rt,cy1-1,1,2,2,2,ltinvW,rtinvW,0x300)  
    tline3d(ud:lerp(0,len-1,12,12,1),0,len,12,12)
    --tline3d(ud:lerp(0,len-1,12,12,1))

end

function DrawTexTri(row,vecBuff)
    local _,_,_,sprite_idx,vec0Idx,vec1Idx,vec2Idx,u0,v0,u1,v1,u2,v2 = row:get()
    local vec0,vec1,vec2 = vecBuff:row(vec0Idx),vecBuff:row(vec1Idx),vecBuff:row(vec2Idx)
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
]]
function DrawSprite(row,vecBuff)
    local _,_,_,sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh,_ = row:get()
    --print(pod(row))
    sspr(sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh)
end

function DrawTexTri2(row,vecBuff)
    --print("tri")
    local _,_,_,sprite_idx,vec0Idx,vec1Idx,vec2Idx,u0,v0,u1,v1,u2,v2 = row:get()
    local vec0,vec1,vec2 = vecBuff:row(vec0Idx),vecBuff:row(vec1Idx),vecBuff:row(vec2Idx)
    if(vec0.y > vec1.y) then vec0,vec1=vec1,vec0 u0,v0,u1,v1 = u1,v1,u0,v0 end
    if(vec0.y > vec2.y) then vec0,vec2=vec2,vec0 u0,v0,u2,v2 = u2,v2,u0,v0 end
    if(vec1.y > vec2.y) then vec1,vec2=vec2,vec1 u1,v1,u2,v2 = u2,v2,u1,v1 end  
    local x0,x1,x2=vec0.x,vec1.x,vec2.x
    local y0,y1,y2=vec0.y,vec1.y,vec2.y
    
    if (y0 >=  DRAW_WINDOW_HEIGHT) or (y2 <=0) then return end
    if (ceil(y2)-ceil(y0))<=1 then return end
    local inv_w0,inv_w1,inv_w2=vec0[2],vec1[2],vec2[2]
    u0,u1,u2=u0*inv_w0,u1*inv_w1,u2*inv_w2
    v0,v1,v2=v0*inv_w0,v1*inv_w1,v2*inv_w2
    local dy02 = y2-y0
    local inv_dy02 = 1/dy02
    local dy01 = y1-y0
    local inv_dy01 = 1/dy01
    local s_up,s_down
    local dy12 = y2-y1
    local inv_dy12 = 1/dy12
    if (y0<0) then
        s_up=-y0
        y0=0
    else
        s_up=ceil(y0)-y0
    end
    if (y1<0) then
        s_down = -y1
        y1=0
    else
        s_down=ceil(y1)-y1
    end
    if y1 > DRAW_WINDOW_HEIGHT then
            y1=DRAW_WINDOW_HEIGHT
    end
    if y2 > DRAW_WINDOW_HEIGHT then
        y2=DRAW_WINDOW_HEIGHT
    end
    local cy0,cy1,cy2=ceil(y0),ceil(y1),ceil(y2)
    
    local len_up = cy1 - cy0 
    local len_down = cy2 - cy1

    local dx02 = (x2-x0)*inv_dy02
    local du02 = (u2-u0)*inv_dy02
    local dv02 = (v2-v0)*inv_dy02
    local dinvW02 = (inv_w2-inv_w0)*inv_dy02

    local x02 = x0+s_up*dx02
    local u02 = u0+s_up*du02
    local v02 = v0+s_up*dv02
    local inv_w02 = inv_w0+s_up*dinvW02
    if len_up >0 then
        local dx01 = (x1-x0)*inv_dy01
        local du01 = (u1-u0)*inv_dy01
        local dv01 = (v1-v0)*inv_dy01
        local dinvW01 = (inv_w1-inv_w0)*inv_dy01
        local x01 = x0+s_up*dx01   
        local u01 = u0+s_up*du01
        local v01 = v0+s_up*dv01
        local inv_w01 = inv_w0+s_up*dinvW01
        ud:set(0,0,sprite_idx,x02,cy0,x01,cy0,u02,v02,u01,v01,inv_w02,inv_w01,0x300) 
        if len_up>1 then
            local lm = len_up-1
            x02 += lm*dx02
            x01 += lm*dx01
            u02 += lm*du02
            v02 += lm*dv02
            u01 += lm*du01
            v01 += lm*dv01
            inv_w02 += lm*dinvW02
            inv_w01 += lm*dinvW01
            ud:set(0,lm,sprite_idx,x02,cy1-1,x01,cy1-1,u02,v02,u01,v01,inv_w02,inv_w01,0x300)
            ud:lerp(0,lm,12,12,1)  
        end
    end
    tline3d(ud,0,len_up,12,12)    --first half
    if len_down >0 then
        local dx12 = (x2-x1)*inv_dy12
        local du12 = (u2-u1)*inv_dy12
        local dv12 = (v2-v1)*inv_dy12
        local dinvW12 = (inv_w2-inv_w1)*inv_dy12
        local x12 = x1+s_down*dx12
        local u12 = u1+s_down*du12
        local v12 = v1+s_down*dv12
        local inv_w12 = inv_w1+s_down*dinvW12

        --local fact = (cy1-y0)/(y2-y0)
        --x02 = x0+(x2-x0)*fact
        --u02= u0+(u2-u0)*fact
        --v02 = v0+(v2-v0)*fact
        --inv_w02 = inv_w0+(inv_w2-inv_w0)*fact 

        x02 += dx02
        u02 += du02
        v02 += dv02
        inv_w02 += dinvW02
        ud:set(0,0,sprite_idx,x02,cy1,x12,cy1,u02,v02,u12,v12,inv_w02,inv_w12,0x300)
        local lm = len_down-1
        if len_down>1 then
            x12 += lm*dx12
            u12 += lm*du12
            v12 += lm*dv12
            inv_w12 += lm*dinvW12
            x02 += lm*dx02
            u02 += lm*du02
            v02 += lm*dv02
            inv_w02 += lm*dinvW02
            ud:set(0,lm,sprite_idx,x02,cy2-1,x12,cy2-1,u02,v02,u12,v12,inv_w02,inv_w12,0x300)
            ud:lerp(0,lm,12,12,1)
            
        end
        tline3d(ud,0,len_down,12,12)   
    end
end

drawFuncs={
    [1] = DrawTexTri2,
    [2] = DrawSprite
}