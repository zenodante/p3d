--[[pod_format="raw",created="2025-01-27 20:59:18",modified="2025-01-27 21:05:58",revision=8]]
include "config.lua"
local DRAW_WINDOW_WIDTH = settings["DRAW_WINDOW_WIDTH"]
local DRAW_WINDOW_HEIGHT = settings["DRAW_WINDOW_HEIGHT"]
--local DRAW_WINDOW_WIDTH = 480
--local DRAW_WINDOW_HEIGHT = 270

local ud = userdata("f64",12,270)

function DrawSprite(row,vecBuff)
    local _,_,_,sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh,_ = row:get()
    --print(pod(row))
    sspr(sprite_idx,sx,sy,sw,sh,dx,dy,dw,dh)
end

function DrawTexTri(row,vecBuff)
    local _,_,_,sprite_idx,vec0Idx,vec1Idx,vec2Idx,u0,v0,u1,v1,u2,v2 = row:get()
    local vec0,vec1,vec2 = vecBuff:row(vec0Idx),vecBuff:row(vec1Idx),vecBuff:row(vec2Idx)
    if(vec0.y > vec1.y) then 
        vec0,vec1=vec1,vec0 
        u0,v0,u1,v1 = u1,v1,u0,v0 
    end
    if(vec0.y > vec2.y) then 
        vec0,vec2=vec2,vec0 
        u0,v0,u2,v2 = u2,v2,u0,v0 
    end
    if(vec1.y > vec2.y) then 
        vec1,vec2=vec2,vec1 
        u1,v1,u2,v2 = u2,v2,u1,v1 
    end  
    local x0,x1,x2=vec0.x,vec1.x,vec2.x
    local y0,y1,y2=vec0.y,vec1.y,vec2.y
    if (y0 >=  DRAW_WINDOW_HEIGHT) or (y2 <=0) then return end
    if (ceil(y2)-ceil(y0))<=1 then return end
    local fact = (y1-y0)/(y2-y0)
    local inv_w0,inv_w1,inv_w2=vec0[2],vec1[2],vec2[2]
    u0,u1,u2=u0*inv_w0,u1*inv_w1,u2*inv_w2
    v0,v1,v2=v0*inv_w0,v1*inv_w1,v2*inv_w2
    local dy02 = y2-y0
    local inv_dy02 = 1/dy02
    local dy01 = y1-y0
    local inv_dy01 = 1/dy01
    local s_up,s_down
    local dy12 = y2-y1
    
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
    local x2x0 = x2-x0
    local u2u0 = u2-u0
    local v2v0 = v2-v0
    local inv_w2w0 = inv_w2-inv_w0
    local dx02 = x2x0*inv_dy02
    local du02 = u2u0*inv_dy02
    local dv02 = v2v0*inv_dy02
    local dinvW02 = inv_w2w0 *inv_dy02

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
        local inv_dy12 = 1/dy12
        local dx12 = (x2-x1)*inv_dy12
        local du12 = (u2-u1)*inv_dy12
        local dv12 = (v2-v1)*inv_dy12
        local dinvW12 = (inv_w2-inv_w1)*inv_dy12
        local x12 = x1+s_down*dx12
        local u12 = u1+s_down*du12
        local v12 = v1+s_down*dv12
        local inv_w12 = inv_w1+s_down*dinvW12
        x02 = x0+x2x0*fact + s_down*dx02
        u02= u0+u2u0*fact + s_down*du02
        v02 = v0+v2v0*fact + s_down*dv02
        inv_w02 = inv_w0+inv_w2w0*fact + s_down*dinvW02
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
        tline3d(ud,0,len_down,12,12)   --second half
    end
end

function DrawTexTri2(row,vecBuff)
    --print("tri")
    local _,_,_,sprite_idx,vec0Idx,vec1Idx,vec2Idx,u0,v0,u1,v1,u2,v2 = row:get()
    local vec0,vec1,vec2 = vecBuff:row(vec0Idx),vecBuff:row(vec1Idx),vecBuff:row(vec2Idx)
    if(vec0.y > vec1.y) then 
        vec0,vec1=vec1,vec0 
        u0,v0,u1,v1 = u1,v1,u0,v0 
    end
    if(vec0.y > vec2.y) then 
        vec0,vec2=vec2,vec0 
        u0,v0,u2,v2 = u2,v2,u0,v0 
    end
    if(vec1.y > vec2.y) then 
        vec1,vec2=vec2,vec1 
        u1,v1,u2,v2 = u2,v2,u1,v1 
    end  
    local x0,x1,x2=vec0.x,vec1.x,vec2.x
    local y0,y1,y2=vec0.y,vec1.y,vec2.y
    if (y0 >=  DRAW_WINDOW_HEIGHT) or (y2 <=0) then return end
    if (ceil(y2)-ceil(y0))<=1 then return end

    local inv_w0,inv_w1,inv_w2=vec0[2],vec1[2],vec2[2]
    u0,u1,u2=u0*inv_w0,u1*inv_w1,u2*inv_w2
    v0,v1,v2=v0*inv_w0,v1*inv_w1,v2*inv_w2

    
    

    local t = (y1-y0)/(y2-y0)
	local u_d = (u2-u0)*t+u0
    local v_d = (v2-v0)*t+v0

    
	local v0,v1 = 
		vec(sprite_idx,x0,y0,x0,y0,u0,v0,u0,v0,inv_w0,inv_w0,0x300),
		vec(
			sprite_idx,
			x1,y1,
			(x2-x0)*t+x0, y1,
			u1,v1, -- uv2
			u_d,v_d,
			inv_w1,(inv_w2-inv_w0)*t+inv_w0,0x300
		)
	
	local start_y = y0 < -1 and -1 or y0\1
	local mid_y = y1 < -1 and -1 or y1 > DRAW_WINDOW_HEIGHT-1 and DRAW_WINDOW_HEIGHT-1 or y1\1
	local stop_y = (y2 <= DRAW_WINDOW_HEIGHT-1 and y2\1 or DRAW_WINDOW_HEIGHT-1)
	
	-- Top half
	local dy = mid_y-start_y
	if dy > 0 then
		local slope = (v1-v0):div((y1-y0))
        --print(pod(slope*(start_y+1-y0)+v0))
		ud:copy(slope*(start_y+1-y0)+v0,true,0,0,12):copy(slope,true,0,12,12,0,12,dy-1)
		
		tline3d(ud:add(ud,true,0,12,12,12,12,dy-1),0,dy)
	end
	
	-- Bottom half
	dy = stop_y-mid_y
	if dy > 0 then
		-- This is, otherwise, the only place where v3 would be used,
		-- so we just inline it.
		local slope = (vec(sprite_idx,x2,y2,x2,y2,u2,v2,u2,v2,inv_w2,inv_w2,0x300)-v1)/(y2-y1)
		
		ud:copy(slope*(mid_y+1-y1)+v1,true,0,0,12):copy(slope,true,0,12,12,0,12,dy-1)
			
		tline3d(ud:add(ud,true,0,12,12,12,12,dy-1),0,dy)
	end
end




drawFuncs={
    [1] = DrawTexTri,
    [2] = DrawSprite
}