pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()

end

function _update60()
	input:update()
	p:update()
end

function _draw()
	cls()
	p:draw()
end
-->8
-- globals
states={
	normal="normal",
	attack="attack"
}

input={
	h=0,
	v=0,
	shoot=false,
	
	update = function(s)
		if btn(⬅️) then 
			s.h=-1
		elseif btn(➡️) then 
			s.h=1
		else
			s.h=0
		end
		
		if btn(⬆️) then 
			s.v=-1
		elseif btn(⬇️) then
			s.v=1
		else
			s.v=0
		end
	end
}

function create_anim(fs,fr_dr)
	local animation={
		frames=fs,
		fr_duration=fr_dr,
		curr_fr=1,
		fr_timer=0,
	
		animate=function(s)
			s.fr_timer+=1
			if s.fr_timer>s.fr_duration then
				s.fr_timer=0
				s.curr_fr+=1
				if s.curr_fr>count(s.frames) then
					s.curr_fr=1
				end
			end
		end
	}
	return animation
end

function animate(s)
	s.curr_anim:animate()
	spr(
		s.curr_anim.
			frames[s.curr_anim.curr_fr],
			s.x-s.w/2,
			s.y-s.h/2,
			1,
			1,
			false,
			false)
end

p={
	state=states.normal,
	speed=1,
	x=64,
	y=64,
	dx=0,
	dy=0,
	w=8,
	h=8,
	anims={
		create_anim({1,2,3},10)
	},
	curr_anim=nil,
	move=function(s)
		s.dy=input.v*s.speed
		s.dx=input.h*s.speed
		s.x+=s.dx
		s.y+=s.dy
	end,
	draw=function(s)
		s.curr_anim=s.anims[1]
		animate(s)
	end,
	update=function(s)
		s:move()
	end
}
__gfx__
00000000000330000003300000033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003333000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700001f1f00001f1f00001f1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000ffff0003ffff3003ffff30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333300f3333f00f3333f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000f3333f00055550000333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005555000050050000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005005000050050000500500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
