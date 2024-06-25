package cards

import rl "vendor:raylib"
import s "core:strings"
import "core:sort"
import "core:slice"
import "core:fmt"
import "core:math/rand"
import la "core:math/linalg"
v3 :: [3]f32
v2 :: [2]f32



CARD_WIDTH :: 500
CARD_HEIGHT :: 700

CARD_BASE_TEXTURES_INITIALIZED := false
CARD_BASE_TEXTURES : map[CardValue]CardImage

CARD_SET_1 : rl.Texture2D

SpacialInfo :: struct {
	pos: v2,
	pos_target: v2, 
	dim: v2,
	scale: f32,
	rotation: f32,
	rotation_target: f32,
}

spacial_info_new :: proc(
	pos: v2,
	dim: v2,
	scale: f32,
	rotation: f32,
)-> SpacialInfo {
	return {
	pos,
	pos, 
	dim,
	scale,
	rotation,
	rotation,
	}
}

spacial_info_point_inside :: proc(using self: SpacialInfo, in_point: v2)-> bool {
	offset := spacial_info_get_offset_to_center(self)
	corner := pos_target - offset
	mat := la.matrix2_rotate(-self.rotation)
	point_local := mat * (in_point - corner)
	a := point_local
	b := (dim* scale) - point_local

	if a.x > 0 && a.y > 0 && b.x > 0 && b.y > 0 {
		return true
	}else{
		return false
	}
}



spacial_info_draw :: proc(using si: SpacialInfo,col := rl.RED){
	offset := spacial_info_get_offset_to_center(si)
	posa := pos - offset
	//rl.DrawRectangleLines(i32(posa.x),i32(posa.y),i32(dim.x*scale), i32(dim.y*scale), col)

	cola := col
	cola[3] = 50
	rl.DrawRectangleRounded({posa.x,posa.y,dim.x*scale,dim.y*scale},0.2,8, cola)
	// rl.DrawRectanglePro(
	// 	rl.Rectangle{
	// 	posa.x,posa.y,dim.x*scale, dim.y*scale
	// 	},
	// 	{0,0}, 
	// 	la.to_degrees(rotation),
	// 	col,
	// )
}

CARD_HOVER_FOUND := false
CardId :: distinct u32
CARD_ID := CardId(0)
Card :: struct {
	id : CardId, 
	value : CardValue,
	suit : CardSuit,
	spacial_info : SpacialInfo,
	is_selected : LerpedBool,

	is_selected_offset : SpacialInfo,
	hover_info : HoverInfo,

	container : ^Container,
	container_color : rl.Color,
}
card_get_new_id :: proc()->CardId {
	id := CARD_ID
	CARD_ID += 1
	return id
}

card_new :: proc(
	value : CardValue,
	suit : CardSuit,
	spacial_info : SpacialInfo,
	is_selected : LerpedBool,

	is_selected_offset : SpacialInfo,
	hover_info : HoverInfo,

	container :^Container = nil,
	container_color : rl.Color,
)->Card{
	return Card{
		card_get_new_id(),
		value,
		suit,
		spacial_info,
		is_selected,
		is_selected_offset,
		hover_info,
		nil,
		container_color,
	}
}

CardValue :: enum {
	seven,eight,nine,ten,jack,queen,king,ace
}
CardSuit :: enum{
	hearts,clubs,diamonds,spades
}

card_get_spacial_info :: proc(self: ^Card)->SpacialInfo {
	interp := self.is_selected.current
	a := self.spacial_info
	b := self.is_selected_offset
	return SpacialInfo{
		pos= a.pos+ b.pos* interp,
		pos_target= a.pos_target + b.pos_target* interp, 
		dim= a.dim,
		scale= a.scale+ b.scale*interp,
		rotation= a.rotation + b.rotation * interp,
	}
}
card_new_default :: proc(pos:v2,v: CardValue, suit_in: CardSuit)-> Card{
	if !CARD_BASE_TEXTURES_INITIALIZED {
		card_load_textures()
		CARD_BASE_TEXTURES_INITIALIZED = true
		path :string= "card_set.png"
		CARD_SET_1 = rl.LoadTexture(s.clone_to_cstring(path))
	}

	return Card{
		id = card_get_new_id(), 
		spacial_info={
			pos = pos,
			pos_target = pos,
			scale = 0.31,
			dim = {
				CARD_WIDTH,
				CARD_HEIGHT,
			}
		},
		is_selected_offset = {
			pos = {0,-40},
			pos_target = {0,-40},
			scale = 0.005,
			rotation = la.PI/22
		},
		value = v,
		suit = suit_in,  

	}
}

card_update_lerped_bools :: proc(using card: ^Card, dt: f32){
	lerped_bool_update(&card.is_selected,dt,10)
	lerped_bool_update(&hover_info.b_hovered,dt)
}

card_reset_globals :: proc(){
	CARD_HOVER_FOUND = false
}
card_update_lerped_values :: proc(using card: ^Card, dt: f32){
	using card.spacial_info
	pos += (pos_target- pos) * dt * 9 
	rotation += (rotation_target- rotation) * dt * 9 
}
card_update :: proc(using card: ^Card, mouse: v2, dt: f32){
	//fmt.printfln("card {} info: {}",card.id, card.spacial_info)
	card_update_lerped_bools(card,dt)
	card_update_lerped_values(card,dt)

	si_card := card_get_spacial_info(card)
	rot_off := card_get_rotation_offset(card) 
	si_card.pos_target -= rot_off
	si_card.pos -= rot_off
	on_card :=spacial_info_point_inside(si_card,mouse)

	if on_card && !CARD_HOVER_FOUND {
		hover_info.b_hovered.state = true 
		CARD_HOVER_FOUND = true
	}
	if !on_card {
		hover_info.b_hovered.state = false 
	}
	
}

spacial_info_get_offset_to_center :: proc(using card: SpacialInfo)->v2{
	adim := dim * scale/2
	return adim
}

card_update_many :: proc(cards: ^[dynamic]Card,mouse: v2, dt:f32){
	card_reset_globals()

	for i := len(cards)-1 ; i>= 0 ; i-=1 {
		c := &cards[i]
		if c.container== nil {
			card_update(c,mouse,dt)
		}
	}
}

card_draw :: proc(using card: ^Card){
	adjust_spacial_info := card_get_spacial_info(card)
	using adjust_spacial_info

	hover_v := card.hover_info.b_hovered.current
	sel_v := card.is_selected.current
	rotation += -0.0 * hover_v
	scale += 0.02 * hover_v
	offset := spacial_info_get_offset_to_center(adjust_spacial_info)
	rotation_offset := card_get_rotation_offset(card)

	
	//rl.DrawTextureEx(CARD_BASE_TEXTURES[card.value].tex, {pos.x,pos.y+height_anim}-offset-rotation_offset, rot_amount , scale_amount , rl.WHITE)
	col := interp_color({1,0,0},{0,1,0}, hover_v)

	adjust_spacial_info_offset := adjust_spacial_info
	adjust_spacial_info_offset.pos -= rotation_offset
	adjust_spacial_info_offset.pos_target -= rotation_offset
	//spacial_info_draw( adjust_spacial_info_offset ,card.container_color)

	//DRAWCARD NORMAL
	//rl.DrawTextureEx(CARD_BASE_TEXTURES[card.value].tex, {pos.x,pos.y}-offset-rotation_offset, la.to_degrees(rotation) , scale , rl.WHITE)

	
	//DRAWCARD FROM CARD SET
	vx := u32(card.value)
	sy := u32(card.suit)
	//fmt.printfln("vx: {} , sy: {}", vx,sy)
	source_rect := rl.Rectangle{f32(vx*500),f32(sy*700),500,700}
	dima := card.spacial_info.dim* card.spacial_info.scale
	posa := pos- offset - rotation_offset
	dest_rect := rl.Rectangle{posa.x,posa.y,dima.x,dima.y} 
	rl.DrawTexturePro(CARD_SET_1, source_rect, dest_rect, {0,0}, la.to_degrees(rotation), rl.WHITE)

	if card.container != nil{
		rl.DrawCircle(i32(pos.x),i32(pos.y),5,card.container_color)
	}
}



card_get_rotation_offset:: proc(using self: ^Card)-> v2 {
	adjust_spacial_info := card_get_spacial_info(self)
	using adjust_spacial_info
	offset := spacial_info_get_offset_to_center(adjust_spacial_info)
	corner :=(pos_target-offset)
	mat := la.matrix2_rotate(rotation)
	rotated_center := corner + mat * (offset)
	rotation_offset := rotated_center - pos_target
	return rotation_offset
}

card_draw_many :: proc(cards : ^[dynamic]Card){
	for &card in cards{
		if card.container == nil {
			card_draw(&card)
		}
	}
}

card_get_width :: proc(using card: ^Card)->i32{
	w := f32(CARD_BASE_TEXTURES[card.value].tex.width) * card.spacial_info.scale
	return i32(w) 
}
card_get_height :: proc(using card: ^Card)->i32{
	h := f32(CARD_BASE_TEXTURES[card.value].tex.height) * card.spacial_info.scale
	return i32(h) 
}

card_load_textures :: proc(){
	CARD_BASE_TEXTURES[.ace] = card_image_new_default()
	CARD_BASE_TEXTURES[.king] = card_image_new_from_path("king.png")
	CARD_BASE_TEXTURES[.queen] = card_image_new_from_path("queen.png")
	CARD_BASE_TEXTURES[.jack] = card_image_new_from_path("jack.png")
}

CardImage :: struct{
	tex: rl.Texture2D,
}

card_image_new_from_path :: proc(path: string)->(out: CardImage){
	img:= rl.LoadImage(s.clone_to_cstring(path))
	out.tex = rl.LoadTextureFromImage(img)
	return
}
card_image_new_default :: proc()->CardImage{
	return card_image_new_from_path("ace.png")
}

//containers
ContainerType_FreeFloating :: struct {

}
 
ContainerType_Fan :: struct {
	radius : f32,
	coord_norm : v2,
	spacing : f32,
	hover_spacing_add : f32,
}
containertype_fan_new :: proc(
	radius : f32,
	coord_norm : v2,
	spacing : f32,
	hover_spacing_add : f32= 0,
)-> ContainerType_Fan {
	return ContainerType_Fan{
		radius,
		coord_norm,
		spacing,
		hover_spacing_add,
	}
}
containertype_fan_new_default :: proc()-> ContainerType_Fan {
	return ContainerType_Fan{
		radius = 800,
		coord_norm = {0.5,0.45},
		spacing = 40,
	}
}

ContainerType_Grid :: struct {
	coord_norm : v2,
	n_col : u32,
	n_row : u32,
	spacing_x : f32,
	spacing_y : f32,
}

containertype_grid_new :: proc(
	coord_norm : v2,
	n_col : u32,
	n_row : u32,
	spacing_x : f32,
	spacing_y : f32,
) -> ContainerType_Grid {
	return ContainerType_Grid{
		coord_norm,
		n_col,
		n_row,
		spacing_x,
		spacing_y,
	}
}



ContainerType :: union {
	ContainerType_FreeFloating,
	ContainerType_Fan,
	ContainerType_Grid,
}

ContainerId :: distinct u32


CONTAINER_ID := ContainerId(0)

Container :: struct {
	id : ContainerId, 
	spacial_info : SpacialInfo,
	cards : [dynamic]^Card,
	container_type: ContainerType,
	hover_info : HoverInfo,
	color : rl.Color, 
}

container_get_new_id :: proc()->ContainerId{
	id := CONTAINER_ID
	CONTAINER_ID += 1

	return id
}


container_solve_card_positions::proc(self: ^Container){
	switch ct in self.container_type {
	case ContainerType_FreeFloating:
		container_freefloating_solve_card_positions(self, ct)
	case ContainerType_Fan:
		container_fan_solve_card_positions(self, ct)
	case ContainerType_Grid:
		container_grid_solve_card_positions(self, ct)
	}
}
container_solve_card_colors :: proc(self: ^Container){
	for &c in self.cards {
		c.container_color = self.color
	}
}
container_freefloating_solve_card_positions :: proc(self: ^Container, using ct: ContainerType_FreeFloating) {
}
container_sort_cards_by_x_position :: proc(self:^Container){
	cond := proc(a:^Card,b:^Card)->bool{
		if a.spacial_info.pos_target.x < b.spacial_info.pos_target.x {
			return true
		}else{
			return false
		}
	}
	slice.sort_by(self.cards[:], cond)
}

container_fan_solve_card_positions :: proc(using self: ^Container, using ct: ContainerType_Fan) {
	container_sort_cards_by_x_position(self)
	card_count := len(self.cards)
	using spacial_info
	posa := pos_target - spacial_info_get_offset_to_center(self.spacial_info) + dim * coord_norm// + dim * scale * coord_norm
	hover_v := self.hover_info.b_hovered.current
	circle_center := posa + {0,radius}

	div_by_zero_cor := 0
	if card_count <= 1 {
		div_by_zero_cor = 1
	}

	arc_rad := f32((spacing+hover_v*hover_spacing_add)/radius*f32(card_count-1))

	for i in 0..<len(self.cards) {
		rad_amount := arc_rad/f32(card_count-1+div_by_zero_cor) * f32(i)
		rot := -(arc_rad/2) + (rad_amount)
		mat := la.matrix2_rotate(rot)
		v := posa - circle_center
		new_center := circle_center + (mat*v)


		self.cards[i].spacial_info.pos_target = new_center
		self.cards[i].spacial_info.rotation_target = rot* 1.0
	}
}
container_grid_solve_card_positions :: proc(using self: ^Container, using ct: ContainerType_Grid) {
	container_sort_cards_by_x_position(self)
	using spacial_info
	posa := pos_target - spacial_info_get_offset_to_center(self.spacial_info) + dim * coord_norm// + dim * scale * coord_norm

	x,y :u32= 0,0
	for i in 0..<len(self.cards) {
		pos_grid := v2{posa.x + ct.spacing_x* f32(x),posa.y + ct.spacing_y* f32(y)}

		self.cards[i].spacial_info.pos_target = pos_grid
		self.cards[i].spacial_info.rotation_target = 0

		if x >= ct.n_col {
			y += 1
			x = 0
		}else{
			x += 1
		}
		if y >= ct.n_row {
			break
		}
	}
}

container_update :: proc(c : ^Container,cards: ^[dynamic]Card, mouse:v2,dt:f32) {
	container_update_cards(c,mouse,dt)
	container_remove_out_of_bound_cards(c)
	container_add_in_bound_cards(c, cards)
	hover_info_update(&c.hover_info, c.spacial_info, mouse,dt, 10)
	container_solve_card_positions(c)
	container_solve_card_colors(c)
}
container_update_cards :: proc(self:^Container,mouse:v2, dt:f32){
	for &c in self.cards {
		card_update(c,mouse,dt)
	}
}

container_remove_out_of_bound_cards :: proc(self : ^Container){
	for c,i in self.cards {
		point_inside := spacial_info_point_inside(self.spacial_info, c.spacial_info.pos)
			// fmt.printfln("info c {} : {}", i , self.spacial_info)
			// fmt.printfln("mouse: {}", card_get_spacial_info(c).pos_target)
			// fmt.println("hover: ", self.hover_info.b_hovered.current)
		if !spacial_info_point_inside(self.spacial_info,c.spacial_info.pos){
			self.cards[i].container = nil
			self.cards[i].spacial_info.rotation_target = 0
			unordered_remove(&self.cards,i)
			fmt.printfln("cid {} card count after remove {}",self.id, len(self.cards))
		}
	}
}

container_contains_card :: proc(self: ^Container, card: ^Card)->bool{
	for c in self.cards{
		// fmt.printfln(" a: {}, b: {}",c.id,card.id)
		if c.id == card.id {
			return true
		}
	}
	return false
}

container_add_in_bound_cards :: proc(self: ^Container, cards: ^[dynamic]Card){
	for &c in cards {
		is_inside := spacial_info_point_inside(self.spacial_info ,c.spacial_info.pos_target)
		if is_inside{
			c.container = self
			is_already_there := container_contains_card(self, &c)
			if !is_already_there {
				append(&self.cards, &c)
				fmt.printfln("cid {} card count after add {}",self.id, len(self.cards))
			}

		}
	}
}
container_add_in_bound_cards_many :: proc(self: ^[dynamic]Container, cards: ^[dynamic]Card){
	for &c in self {
		container_add_in_bound_cards(&c, cards)
	} 
}

container_update_many :: proc(containers : ^[dynamic]Container,cards: ^[dynamic]Card,mouse:v2, dt:f32) {
	for &c in containers {
		container_update(&c,cards,mouse,dt)
	}
}

container_new_default :: proc(spacial_info: SpacialInfo)-> Container {
	r,g,b := f32(rl.GetRandomValue(20,255))/255,f32(rl.GetRandomValue(20,255))/255,f32(rl.GetRandomValue(20,255))/255
	return Container {
		id = container_get_new_id(),
		spacial_info = spacial_info,
		container_type = containertype_fan_new_default(),
		color = rl.ColorFromNormalized({r,g,b,1}) 
	}
}

container_draw :: proc(self : Container){
	col := interp_color({1,0,0},{0,1,0}, self.hover_info.b_hovered.current)
	spacial_info_draw(self.spacial_info, self.color)


	//fmt.println("care n: ", len(self.cards))
	for &card in self.cards {
		//fmt.println("card info: ", card.spacial_info )
		card_draw(card)
	}
}
 
container_draw_many :: proc(containers: ^[dynamic]Container){
	for &container in containers {
		container_draw(container)
	}
}

/////////

LerpedBool :: struct {
	state: bool,
	current: f32,
}
lerped_bool_update :: proc(using lerped_bool: ^LerpedBool, dt: f32, speed:f32= 5){
	target :f32= 1
	if !state {
		target = 0
	}
	current += (target - current) * dt * speed
}

lerp :: proc(v: ^v2, t: v2, dt: f32, speed: f32= 1){
	v^ += (v^-t) * dt * speed 
}

interp_v3 :: proc(a: v3, b: v3, i: f32)->v3{
	return a + (b-a) * i
}
interp_color :: proc(a: v3, b: v3, i: f32)->[4]f32{
	col := a + (b-a) * i
	return {col.x,col.y,col.z,1}
}

////


HoverInfo :: struct{
	b_hovered : LerpedBool,
}

///on is an out parameter to find out if point was inside
hover_info_update :: proc(hover_info: ^HoverInfo, using si: SpacialInfo, mouse: v2,dt: f32,speed:f32=5, on:^bool= nil){
	on1 := spacial_info_point_inside(si,mouse)
	if on != nil {
		on^ = on1
	}
	hover_info.b_hovered.state =on1 
	lerped_bool_update(&hover_info.b_hovered,dt,speed)
}



