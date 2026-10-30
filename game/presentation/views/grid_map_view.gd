class_name GridMapView
extends Node2D
## 5x5 macro map with current-room highlight and build ghost preview.

const CELL_SIZE: float = 56.0
const COLOR_EMPTY := Color("181820")
const COLOR_ROOM := Color("3a3a52")
const COLOR_CURRENT := Color("72d4ff")
const COLOR_GRID := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_GHOST_OK := Color(0.4, 1.0, 0.5, 0.45)
const COLOR_GHOST_BAD := Color(1.0, 0.35, 0.35, 0.45)

var grid: DungeonGrid = null
var current_cell: Vector2i = Vector2i(-1, -1)
var build_controller: BuildController = null
var preview_cell: Vector2i = Vector2i(-1, -1)
var preview_valid: bool = false


func setup(p_grid: DungeonGrid) -> void:
	grid = p_grid
	queue_redraw()


func set_current(cell: Vector2i) -> void:
	current_cell = cell
	queue_redraw()


func set_build_controller(controller: BuildController) -> void:
	build_controller = controller
	queue_redraw()


func set_preview(cell: Vector2i, valid: bool) -> void:
	preview_cell = cell
	preview_valid = valid
	queue_redraw()


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE), Vector2(CELL_SIZE - 4.0, CELL_SIZE - 4.0))


func cell_at(local_position: Vector2) -> Vector2i:
	return Vector2i(int(floor(local_position.x / CELL_SIZE)), int(floor(local_position.y / CELL_SIZE)))


func _draw() -> void:
	if grid == null:
		return
	for y in DungeonGrid.SIZE_Y:
		for x in DungeonGrid.SIZE_X:
			var cell := Vector2i(x, y)
			var color := COLOR_ROOM if grid.get_room(cell) != null else COLOR_EMPTY
			if cell == current_cell:
				color = COLOR_CURRENT
			draw_rect(cell_rect(cell), color, true)
			draw_rect(cell_rect(cell), COLOR_GRID, false, 1.0)
	if build_controller != null and build_controller.active:
		var target := build_controller.target_cell
		if grid.in_bounds(target):
			var ghost_color := COLOR_GHOST_OK if build_controller.preview_valid() else COLOR_GHOST_BAD
			draw_rect(cell_rect(target), ghost_color, true)
	elif preview_cell != Vector2i(-1, -1) and grid != null and grid.in_bounds(preview_cell):
		var ghost_color := COLOR_GHOST_OK if preview_valid else COLOR_GHOST_BAD
		draw_rect(cell_rect(preview_cell), ghost_color, true)
