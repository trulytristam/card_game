package cam 

import rl "vendor:raylib"
import la "core:math/linalg"

cam2D :: struct{
	cam : rl.Camera2D
}
cam3D :: struct{
	cam : rl.Camera3D
}


cam2D_new_default :: proc()->cam2D {
	return cam2D{
		cam = rl.Camera2D{
			offset = {0,0},
			target = {0,0},
			rotation = 0,
			zoom = 1,
		}
	}
}
cam3D_new_default :: proc()->cam3D {
	return cam3D{
		cam = rl.Camera3D{
			position = {0,0,10},
			target = {0,0,0},
			up = {0,-1,0},
			fovy = 45,
			projection = rl.CameraProjection.PERSPECTIVE,
		}
	}
}
