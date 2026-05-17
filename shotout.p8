pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	c_enemy(64,64,1)
end

function _update60()
	input:update()
	p:update()
	for bullet in all(bullets) do
		bullet:update()
	end
	for enemy in all(enemies) do
		enemy:update()
	end
end

function _draw()
	cls()
	p:draw()
	for bullet in all(bullets) do
		bullet:draw()
	end
	for enemy in all(enemies) do
		enemy:draw()
	end
end
-->8
-- entities
states={
	running="running",
	normal="idle",
	attack="attack"
}

e_states={
	follow="follow",
	attack="attack"
}

-- animation helper
function c_anim(fs,fr_dr)
	return {
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
end

function anim_play(s,fl_x)
	s.curr_anim:animate()
	spr(
		s.curr_anim.
			frames[s.curr_anim.curr_fr],
			s.x-s.w/2,
			s.y-s.h/2,
			1,
			1,
			fl_x,
			false)
end

function anim_reset(a)
	a.curr_fr=1
	a.fr_timer=0
end

-- player obj
p={
	state=states.normal,
	speed=1,
	health=100,
	x=64,
	y=64,
	dx=0,
	dy=0,
	lx=1,
	ly=1,
	w=8,
	h=8,
	dead=false,
	anims={
		--idle
		c_anim({1,2,3},10),
		--run
		c_anim({4,5},20)
	},
	curr_anim=nil,
	move=function(s)
		if input.h != 0 and
					input.v != 0 then
			input.h,input.v=u_normalize(input.h,input.v)	
		end
		if input.h != 0 or
					input.v != 0 then
			s.lx,s.ly=input.h,input.v
		end
		s.dy=input.v*s.speed
		s.dx=input.h*s.speed
		s.x+=s.dx
		s.y+=s.dy
	end,
	shoot=function(s)
		if input.shoot then
			c_bullet(
				s.x,s.y,s.lx,s.ly,3,10,
				c_anim({16,17},3),
				60,8,8
			)
		end
	end,
	take_damage=function(s,b)
		s.health-=b.damage
		if s.health<=0 then
			s.dead=true
		end
		del(bullets,b)
	end,
	get_state=function(s)
		if s.dx != 0 or
					s.dy != 0 then
			s.state=states.running
		else
			s.state=states.idle
		end
	end,
	draw=function(s)
		if s.dead then return end
		if s.state==states.idle then
			s.curr_anim=s.anims[1]
		elseif s.state==states.running then
			s.curr_anim=s.anims[2]
		end
		anim_play(s,s.lx>0)
	end,
	update=function(s)
		if s.dead then return end
		s:shoot()
		s:move()
		s:get_state()
	end
}

bullets={}
function c_bullet(
	x,y,dx,dy,speed,damage,anim,range,w,h,player
) 
	add(bullets,{
		damage=damage,
		x=x,
		y=y,
		dx=dx,
		dy=dy,
		speed=speed,
		curr_anim=anim,
		range=range,
		w=w,
		h=h,
		player=player,
		ch_coll=function(s,o)
			if p_box_collision(s,o) then
				o:take_damage(s)
				return true
			end
			return false
		end,
		update=function(s)
			s.range-=1
			s.x+=s.dx*s.speed
			s.y+=s.dy*s.speed
			if player!=nil then
				s:ch_coll(player)
			else
				for enemy in all(enemies) do
					s:ch_coll(enemy)
				end
			end
			if s.range<=0 then
				del(bullets,s)
			end
		end,
		draw=function(s)
			anim_play(s)
		end
	})
end

enemies={}
function c_enemy(
	x,y,t
)
	if t==1 then
		add(enemies,{
			health=20,
			x=x,
			y=y,
			w=8,
			h=8,
			atk_d=40,
			state=e_states.follow,
			dx=0,
			dy=0,
			speed=0.5,
			sh_timer=20,
			c_sh_timer=0,
			curr_anim=c_anim({18},2),
			take_damage=function(s,b)
				s.health-=b.damage
				if s.health<=0 then
					del(enemies,s)
				end
				del(bullets,b)
			end,
			get_state=function(s)
				local dist_x = p.x-s.x
				local dist_y = p.y-s.y
				if abs(dist_x)<s.atk_d and 
							abs(dist_y)<s.atk_d then
					s.state=e_states.attack
				else
					s.state=e_states.follow
				end
			end,
			follow=function(s)
				s.dx,s.dy=u_manhattan(
					p.x-s.x,
					p.y-s.y
				)
				s.x+=s.dx*s.speed
				s.y+=s.dy*s.speed
			end,
			attack=function(s)
				if s.c_sh_timer<=s.sh_timer then
					s.c_sh_timer+=1
					return
				end
				s.dx,s.dy=u_manhattan(
					p.x-s.x,
					p.y-s.y
				)
				s.c_sh_timer=0
				c_bullet(
					s.x,s.y,s.dx,s.dy,2,10,
					c_anim({16,17},3),
					60,8,8,p
				)
			end,
			update=function(s)
				s:get_state()
				if s.state==e_states.attack then
					s:attack()
				elseif s.state==e_states.follow then
					s:follow()
				end
			end,
			draw=function(s)
				anim_play(s)
			end
		})
	end
end

-->8
--utils
function u_normalize(x,y)
	local magn=x^2+y^2
	return x/sqrt(magn),y/sqrt(magn)
end

function u_manhattan(x,y)
	local d = abs(x)+abs(y)
	local dx, dy
	if d>0 then
		return x/d,y/d
	else
		return x,y
	end
end

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
		
		s.shoot=btnp(❎)
	end
}
-->8
-- physics
function p_box_collision(
	o1,o2
)
	local x1,y1,w1,h1=o1.x,o1.y,o1.w,o1.h
	local x2,y2,w2,h2=o2.x,o2.y,o2.w,o2.h
	return
	(x1-w1/2>=x2-w2/2 and 
	x1-w1/2<=x2+w2/2 or
	x1+w1/2>=x2-w2/2 and
	x1+w1/2<=x2+w2/2) 
	and
	(y1-h1/2>=y2-h2/2 and
	y1-h1/2<=y2+h2/2 or
	y1+h1/2>=y2-h2/2 and
	y1+h1/2<=y2+h2/2)
end
__gfx__
00000000000330000003300000033000000330000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003333000033330000333300003333000033330000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700001f1f00001f1f00001f1f00001f1f00001f1f0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000ffff0003ffff3003ffff3000ffff0000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000033333300f3333f00f3333f0033333300333333000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000f3333f00055550000333300003333f00f33330000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005555000050050000555500005555000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000005005000050050000500500005000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa00009999000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa0099999900214412000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa999999990214412000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa999999990214412000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa999999990024420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa999999990002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa0099999900020020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa00009999000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
