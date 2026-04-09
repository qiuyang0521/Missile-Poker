extends Control

const GRID_SIZE: int = 80  # 每个网格单元的大小（与Panel尺寸匹配）

# 标记是否为原始节点（只有原始节点才生成网格）
var is_original: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 只有原始节点才执行初始化和生成网格
	if is_original:
		visible = false
		# 生成铺满屏幕的网格地图
		_generate_grid_map()
		# 连接玩家卡牌的信号
		_connect_card_signals()
	# 注意：克隆体不执行任何操作，保持创建时的状态

# 连接所有玩家卡牌的信号
func _connect_card_signals() -> void:
	# 获取场景中的所有 player_card 节点
	var root = get_tree().root
	var player_cards = _find_player_cards(root)
	
	for card in player_cards:
		card.dragged.connect(_on_card_dragged)
		card.returned.connect(_on_card_returned)
		print("Connected signals for: " + card.name)

# 递归查找所有 player_card 节点
func _find_player_cards(node: Node) -> Array:
	var result = []
	
	# 检查当前节点是否是 player_card（通过脚本路径判断）
	if node.has_method("get_script") and node.get_script() != null:
		var script_path = node.get_script().resource_path
		if script_path.ends_with("player_card.gd"):
			result.append(node)
	
	# 递归检查子节点
	for child in node.get_children():
		result.append_array(_find_player_cards(child))
	
	return result

# 卡牌被拖拽时显示所有网格
func _on_card_dragged() -> void:
	_set_all_grid_visible(true)

# 卡牌返回时隐藏所有网格
func _on_card_returned() -> void:
	_set_all_grid_visible(false)

# 设置所有网格节点的可见性
func _set_all_grid_visible(visible: bool) -> void:
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			# 匹配原始 Anchor 和克隆的 Anchor_行_列
			if child.name == "Anchor" or child.name.begins_with("Anchor_"):
				# 确保子节点及其 Panel 都可见
				child.visible = visible
				# 递归设置所有子节点的可见性
				for sub_child in child.get_children():
					sub_child.visible = visible

# 生成网格地图
func _generate_grid_map() -> void:
	# 使用标准分辨率 1920x1080 计算网格（不考虑相机缩放）
	const SCREEN_WIDTH: float = 1920.0
	const SCREEN_HEIGHT: float = 1080.0
	
	# 计算需要多少个网格单元才能铺满屏幕
	var cols: int = ceil(SCREEN_WIDTH / GRID_SIZE) + 2  # 多加2格确保覆盖
	var rows: int = ceil(SCREEN_HEIGHT / GRID_SIZE) + 2
	
	# 计算起始位置（居中）
	var start_x: float = -(cols * GRID_SIZE) / 2.0
	var start_y: float = -(rows * GRID_SIZE) / 2.0
	
	# 克隆并放置网格
	for row in range(rows):
		for col in range(cols):
			var grid_cell: Control = duplicate()
			grid_cell.is_original = false  # 标记为克隆体
			
			# 设置位置
			grid_cell.position = Vector2(
				start_x + col * GRID_SIZE,
				start_y + row * GRID_SIZE
			)
			
			# 设置唯一名称（在添加到树之前）
			grid_cell.name = "Anchor_%d_%d" % [row, col]
			
			# 将节点移到最上层（z_index 设置较高值）
			grid_cell.z_index = 100
			
			# 强制设置为隐藏（初始时不显示，只有拖拽时才显示）
			grid_cell.visible = false
			
			# 使用 call_deferred 延迟添加到父节点，避免 _ready() 中的冲突
			get_parent().add_child.call_deferred(grid_cell)
	
	print("Grid map generated: %d x %d (%d cells)" % [cols, rows, cols * rows])
