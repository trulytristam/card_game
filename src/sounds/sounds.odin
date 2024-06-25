package sounds

import rl "vendor:raylib"
import "core:fmt"

SOUNDS : map[SoundType]rl.Sound

SoundType :: enum {
	card_hover,
	card_select,
	card_drop,
}

load_sounds :: proc(){
	SOUNDS[.card_hover] = rl.LoadSound("card_hover.mp3")
	SOUNDS[.card_select] = rl.LoadSound("card_select.mp3")
	SOUNDS[.card_drop] = rl.LoadSound("card_drop.mp3")
}


play_sound :: proc(type : SoundType){
	if rl.IsSoundReady(SOUNDS[type]){
		rl.PlaySound(SOUNDS[type])
	}else{
		fmt.println("sounds not ready")
	}
}










