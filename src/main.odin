package main

import "core:fmt"
import "cards"
import "cam"
import "core:time"
import "core:math/rand"
import rl "vendor:raylib"
import gl "vendor:OpenGL"
import "sounds"

import "vendor:glfw"

v2 :: [2]f32

CAM := cam.cam2D_new_default()
SELECTED_CARD :^cards.Card =  nil
SELECTION_OFFSET : v2
SELECTION_TIME : time.Time
SELECTION_CLICK_TIME :f64 = 0.14

CARDS : [dynamic]cards.Card
CONTAINERS : [dynamic]cards.Container
UI_ELEM : [dynamic]cards.Ui

TIME_START : time.Time

main :: proc(){
	//rl.SetConfigFlags({rl.ConfigFlag.FULLSCREEN_MODE})
	rl.SetConfigFlags({rl.ConfigFlag.MSAA_4X_HINT})
	rl.InitWindow(1920,1080,"cardgame")
	rl.InitAudioDevice()

	glfw.Init()

	rl.SetMouseCursor(rl.MouseCursor.CROSSHAIR)
	TIME_START = time.now()

	sounds.load_sounds()

	vignette := rl.LoadTexture("vignette.png")

	reserve(&CARDS,500)
	add_containers()
	add_uielements()
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

		rl.ClearBackground(rl.ColorFromNormalized({0.1,0.15,0.7,1}))
		rl.BeginDrawing()
		rl.BeginMode2D(CAM.cam)

		rl.DrawTexture(vignette, 0,0,rl.WHITE)


		time_start := f32(time.duration_seconds(time.since(TIME_START)))
		cards.ui_update_many(&UI_ELEM, dt,mouse)
		cards.card_update_many(&CARDS,mouse,dt,time_start)
		cards.container_update_many(&CONTAINERS,&CARDS,mouse,dt,time_start)
		cards.container_draw_many(&CONTAINERS,time_start)

		cards.card_draw_many(&CARDS,time_start)
		if SELECTED_CARD != nil && time.duration_seconds(time.since(SELECTION_TIME)) > SELECTION_CLICK_TIME{
			cards.card_draw(SELECTED_CARD,time_start)
		}

		cards.ui_draw_many(&UI_ELEM, dt, time_start)

		rl.EndDrawing()
		rl.EndMode2D()
	}

}

select_card :: proc(mouse: v2){
	for &card in CARDS {
		if cards.spacial_info_point_inside(card.spacial_info, mouse) {
			sounds.play_sound(sounds.SoundType.card_select)
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

	if SELECTED_CARD != nil {
		sounds.play_sound(.card_drop)
	}
	SELECTED_CARD = nil
}

move_selected_card :: proc(point: v2){
	if SELECTED_CARD != nil {
		SELECTED_CARD.spacial_info.pos_target = point + SELECTION_OFFSET
	}
}
add_uielements :: proc(){
	spacial_info := cards.spacial_info_new({400,800},{240,54},1,0)
	ui_text_info := cards.ui_text_info_new("Play",50,{-0.4,-1})
	append(&UI_ELEM, cards.ui_new(spacial_info,ui_text_info,cards.HoverInfo{},
		rl.ColorFromNormalized({0.5,1,0.1,1}), rl.ColorFromNormalized({0,0,1,1}), rl.BLACK)
	)

	spacial_info = cards.spacial_info_new({450,900},{240,54},1,0)
	ui_text_info = cards.ui_text_info_new("Discard",50,{-0.8,-1})
	append(&UI_ELEM, cards.ui_new(spacial_info,ui_text_info,cards.HoverInfo{},
		rl.ColorFromNormalized({1,1,0.5,1}), rl.ColorFromNormalized({0,0,1,1}), rl.BLACK)
	)
}

add_containers :: proc(){
	for i in 0..<3{
	}
	//append(&CARDS, cards.card_new_default(.ace))
	//append(&CARDS, cards.card_new_default(.ace))

	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({f32(rl.GetScreenWidth())/2- 200,200}, {1300,300}, 1, 0),7

	))
	CONTAINERS[0].container_type = cards.containertype_grid_new({0.10,0.5},7,2,170,200)


	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({f32(rl.GetScreenWidth())/2,537}, {1200,300}, 1, 0),7
	))
	CONTAINERS[1].container_type = cards.containertype_grid_new({0.20,0.5},8,2,170,200)
	 
	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({f32(rl.GetScreenWidth())/2,850}, {700,250}, 1, 0),10
	))
	CONTAINERS[2].container_type = cards.containertype_fan_new(800,{0.5,0.44},40,40)

	append(&CONTAINERS, cards.container_new_default(
			cards.spacial_info_new({f32(rl.GetScreenWidth())-457,870}, {200,300}, 1, 0),52
	))
	CONTAINERS[3].container_type = cards.containertype_fan_new(800,{0.5,0.5},1)
	 
	//append(&CONTAINERS[0].cards, &CARDS[0])
	//append(&CONTAINERS[0].cards, &CARDS[1])
	// append(&CONTAINERS[0].cards, &CARDS[2])
	// append(&CONTAINERS[0].cards, &CARDS[3])
	// append(&CONTAINERS[0].cards, &CARDS[4])
	//append(&CONTAINERS[0].cards, &CARDS[5])
	//append(&CONTAINERS[0].cards, &CARDS[6])
}

handle_input :: proc(mouse: v2){
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		select_card(mouse)
	}
	if rl.IsMouseButtonReleased(rl.MouseButton.LEFT) {
		unselect_card()
	}

	if rl.IsKeyPressed(rl.KeyboardKey.SPACE){
		rand_val := rand.choice_enum(cards.CardValue) 
		rand_suit := rand.choice_enum(cards.CardSuit) 
		append(&CARDS, cards.card_new_default(mouse, rand_val,rand_suit))
		fmt.println("card added")
	}
}
