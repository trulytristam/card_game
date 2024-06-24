package card

import rl "vendor:raylib"
import s "core:strings"
v3 :: [3]f32

CardSpacialInfo :: struct {
	pos: v3,
}

Card :: struct {
	spacial_info : CardSpacialInfo,
	card_image : CardImage
}

card_new_default :: proc()-> Card{
	return Card{
		spacial_info={
			pos = {200,200,0}
		},
		card_image = card_image_new_default(),
	}
}

card_draw :: proc(using card: ^Card){
	using spacial_info
	rl.DrawTexture(card_image.tex, i32(pos.x), i32(pos.y), rl.WHITE)
}

CardImage :: struct{
	tex: rl.Texture2D,
}

card_image_new_from_path :: proc(path: string)->(out: CardImage){
	out.tex = rl.LoadTexture(s.clone_to_cstring(path))
	return
}
card_image_new_default :: proc()->CardImage{
	return card_image_new_from_path("ace.png")
}



