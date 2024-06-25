package main

import "core:fmt"
import "cards"
import "cam"
import "core:time"
import rl "vendor:raylib"
import gl "vendor:OpenGL"

import "vendor:glfw"


v2 :: [2]f32


CAM := cam.cam2D_new_default()
SELECTED_CARD :^cards.Card =  nil
SELECTION_OFFSET : v2
SELECTION_TIME : time.Time
SELECTION_CLICK_TIME :f64 = 0.3

CARDS : [dynamic]cards.Card
CONTAINERS : [dynamic]cards.Container

main :: proc(){
	rl.InitWindow(800,800,"cardgame")
	rl.SetConfigFlags({rl.ConfigFlag.MSAA_4X_HINT})
	glfw.Init()

	add_containers()
	last_time := time.now()
	dt :f32= 0

	for !rl.WindowShouldClose() {
		dt = f32(time.since(last_time))
		dt = rl.GetFrameTime()
		last_time = time.now()

		mouse :v2= {
			f32(rl.GetMouseX()),
			f32(rl.GetMouseY()),
		}

		handle_input(mouse)
		move_selected_card(mouse)

		rl.ClearBackground(rl.ColorFromNormalized({0.1,0.15,0.6,1}))
		rl.BeginDrawing()
		rl.BeginMode2D(CAM.cam)


		cards.card_update_many(&CARDS,mouse,dt)
		cards.container_update_many(&CONTAINERS,&CARDS,mouse,dt)
		cards.container_draw_many(&CONTAINERS)

		if SELECTED_CARD != nil && time.duration_seconds(time.since(SELECTION_TIME)) > SELECTION_CLICK_TIME{
			cards.card_draw(SELECTED_CARD)
		}

		rl.EndDrawing()
		rl.EndMode2D()
	}

}

select_card :: proc(mouse: v2){
	for &card in CARDS {
		if cards.spacial_info_point_inside(card.spacial_info, mouse) {
			SELECTED_CARD = &card
			SELECTION_OFFSET = card.spacial_info.pos_target - mouse 
			SELECTION_TIME = time.now()
		}
	}
}
unselect_card :: proc(){
	if time.duration_seconds(time.since(SELECTION_TIME)) < SELECTION_CLICK_TIME {
		SELECTED_CARD.is_selected.state = !SELECTED_CARD.is_selected.state
	}
	SELECTED_CARD = nil
}

move_selected_card :: proc(point: v2){
	if SELECTED_CARD != nil {
		SELECTED_CARD.spacial_info.pos_target = point + SELECTION_OFFSET
	}
}

add_containers :: proc(){
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))
	append(&CARDS, cards.card_new_default(.ace))

	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({400,200}, {700,300}, 1, 0)
	))
	 
	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({400,600}, {700,300}, 1, 0)
	))
	 
	append(&CONTAINERS[0].cards, &CARDS[0])
	append(&CONTAINERS[0].cards, &CARDS[1])
	append(&CONTAINERS[0].cards, &CARDS[2])
	append(&CONTAINERS[0].cards, &CARDS[3])
	append(&CONTAINERS[0].cards, &CARDS[4])
	append(&CONTAINERS[0].cards, &CARDS[5])
	append(&CONTAINERS[0].cards, &CARDS[6])
}

handle_input :: proc(mouse: v2){
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		select_card(mouse)
	}
	if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
		unselect_card()
	}
}
