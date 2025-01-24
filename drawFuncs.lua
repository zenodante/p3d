include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
--local DRAW_WINDOW_WIDTH = 480
--local DRAW_WINDOW_HEIGHT = 270

local ud = userdata("f64",12,270)

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
    local lm1=len
    lt=l+lm1*ldx
    rt=r+lm1*rdx
    lut=lu+lm1*ldu
    lvt=lv+lm1*ldv
    rut=ru+lm1*rdu
    rvt=rv+lm1*rdv
    ltinvW=linvW+lm1*ldinvW
    rtinvW=rinvW+lm1*rdinvW
    ud:set(0,0  ,sprite_idx,l ,cy0,r ,cy0,lu ,lv ,ru ,rv ,linvW ,rinvW ,0x300)  
    ud:set(0,len,sprite_idx,lt,cy1,rt,cy1,lut,lvt,rut,rvt,ltinvW,rtinvW,0x300)  
    --ud:set(0,0  ,2,l ,cy0,r ,cy0,1 ,1 ,2,1 ,linvW ,rinvW ,0x300)  
    --ud:set(0,len,2,lt,cy1,rt,cy1,1,2,2,2,ltinvW,rtinvW,0x300)  
    tline3d(ud:lerp(0,len,12,12,1),0,len,12,12)

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

function DrawSprite(row,vecBuff)
    local _,_,_,sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh,_ = row:get()
    --print(pod(row))
    sspr(sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh)
end




drawFuncs={
    [1] = DrawTexTri,
    [2] = DrawSprite
}