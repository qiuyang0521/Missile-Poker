extends "res://scripts/item/cards.gd"

const SCALE_SPEED: float = 5.0  # 缩放平滑速度

signal dragged
signal returned
signal woke_up  # LYING 切换到 IDLE 时发射一次

# 重写：按下按钮时额外发射 dragged 信号
func _on_button_button_down() -> void:
	if card_current_state == CardState.LYING:
		_handle_lying_click()
	else:
		drag_offset = get_global_mouse_position() - global_position
		_change_state(CardState.DRAGGING)
		dragged.emit()

# 重写：松开按钮时发射 returned 信号并吸附到最近的 anchor
func _on_button_button_up() -> void:
	if card_current_state == CardState.LYING:
		return
	returned.emit()
	anchor_position = _find_nearest_anchor()
	_change_state(CardState.RETURNING)

# 重写：唤醒卡牌时额外发射 woke_up 信号
func _wake_up_card() -> void:
	print("Card waking up...")
	card_current_state = CardState.IDLE
	woke_up.emit()

# 重写拖拽帧接口：将卡牌提升至最前方图层
func _on_drag_frame(_delta: float) -> void:
	z_index = 128

# 重写 idle 状态：恢复图层 + 平滑缩放到 1
func _process_idle(delta: float) -> void:
	z_index = 0
	if card_body:
		card_body.position = card_body.position.lerp(DEFAULT_OFFSET, LIFT_SPEED * delta)
	velocity = Vector2.ZERO
	scale = scale.lerp(Vector2(1, 1), SCALE_SPEED * delta)

# 寻找最近的 anchor 位置（基于卡牌左上角）
func _find_nearest_anchor() -> Vector2:
	var card_top_left = global_position
	var nearest_pos = anchor_position
	var min_distance = INF
	var anchors = _find_all_anchors(get_tree().root)
	for anchor in anchors:
		if is_instance_valid(anchor):
			var distance = card_top_left.distance_to(anchor.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_pos = anchor.global_position
	return nearest_pos

# 递归查找所有 anchor 节点
func _find_all_anchors(node: Node) -> Array:
	var result = []
	if node.name == "Anchor" or node.name.begins_with("Anchor_"):
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_all_anchors(child))
	return result
