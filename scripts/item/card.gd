extends "res://scripts/item/cards.gd"

func _ready() -> void:
	super._ready()
	# 生成后直接进入可拖拽的 IDLE 状态（跳过 LYING 唤醒流程）
	card_current_state = CardState.IDLE


# 重写：松开时自动吸附到场景中最近的 Anchor 节点
func _on_button_button_up() -> void:
	if card_current_state == CardState.LYING:
		return
	anchor_position = _find_nearest_anchor()
	_change_state(CardState.RETURNING)


# 重写：拖拽时将卡牌置于最前图层
func _on_drag_frame(_delta: float) -> void:
	z_index = 128


# 重写：idle 时恢复图层
func _process_idle(delta: float) -> void:
	z_index = 0
	super._process_idle(delta)


# 寻找场景中距离最近的 Anchor 节点，返回其全局坐标
func _find_nearest_anchor() -> Vector2:
	var nearest_pos: Vector2 = anchor_position
	var min_distance: float = INF
	var anchors: Array = _find_all_anchors(get_tree().root)
	for anchor in anchors:
		if is_instance_valid(anchor):
			var dist: float = global_position.distance_to(anchor.global_position)
			if dist < min_distance:
				min_distance = dist
				nearest_pos = anchor.global_position
	return nearest_pos


# 递归查找所有以 "Anchor" 命名的节点
func _find_all_anchors(node: Node) -> Array:
	var result: Array = []
	if node.name == "Anchor" or node.name.begins_with("Anchor_"):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_anchors(child))
	return result
