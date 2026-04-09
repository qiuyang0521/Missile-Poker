extends Control

const SPLIT_SPEED: float = 1.0  # 裂开动画速度
const SPLIT_DISTANCE: float = 80.8  # 上下各自移动距离
const ZOOM_START: float = 5.0  # 镜头初始缩放值
const ZOOM_END: float = 2.0    # 镜头最终缩放值
const FADE_IN_SPEED: float = 2.0  # 淡入动画速度
const ZOOM_CARD_START: float = 2.0  # 卡牌唤醒时镜头起始缩放值
const ZOOM_CARD_END: float = 1.0   # 卡牌唤醒时镜头最终缩放值
const ZOOM_CARD_SPEED: float = 1.5  # 卡牌唤醒镜头缩放速度

@onready var label: Label = $Label
@onready var front_top: Control = $FrontTop
@onready var front_bottom: Control = $FrontBottom
@onready var front_top_panel: Control = $FrontTop/Panel
@onready var front_bottom_panel: Control = $FrontBottom/Panel
@onready var button: Button = $Button

@onready var camera_2d: Camera2D = $"../../Camera2D"
@onready var main_card: Control = $"../Card"  # 主场景中的 Card 节点

var is_splitting: bool = false  # 是否正在裂开
var split_progress: float = 0.0  # 裂开进度 (0.0 ~ 1.0)
var is_fading_in: bool = false  # 是否正在淡入
var fade_progress: float = 0.0  # 淡入进度 (0.0 ~ 1.0)
var is_zooming_out: bool = false  # 是否正在缩放镜头（卡牌唤醒后）
var zoom_out_progress: float = 0.0  # 镜头缩放进度 (0.0 ~ 1.0)

func _ready() -> void:
	# 连接按钮信号
	button.pressed.connect(_on_button_pressed)
	# 连接 player_card 的唤醒信号
	main_card.woke_up.connect(_on_card_woke_up)

func _on_button_pressed() -> void:
	# 隐藏 Label
	label.visible = false
	button.visible = false
	# 开始裂开动画
	is_splitting = true

func _process(delta: float) -> void:
	if is_splitting:
		_update_split_animation(delta)
	elif is_fading_in:
		_update_fade_in_animation(delta)
	elif is_zooming_out:
		_update_zoom_out_animation(delta)

func _update_split_animation(delta: float) -> void:
	# 增加裂开进度
	split_progress = move_toward(split_progress, 1.0, SPLIT_SPEED * delta)
	
	# 计算当前移动距离 (0 ~ SPLIT_DISTANCE)
	var current_offset: float = split_progress * SPLIT_DISTANCE
	
	# 上半部分的 Panel 向上移动，被 FrontTop 裁剪
	front_top_panel.position.y = -current_offset
	
	# 下半部分的 Panel 向下移动，被 FrontBottom 裁剪
	front_bottom_panel.position.y = current_offset
	
	# 镜头缩放从 ZOOM_START 渐变到 ZOOM_END
	var current_zoom: float = lerp(ZOOM_START, ZOOM_END, split_progress)
	camera_2d.zoom = Vector2(current_zoom, current_zoom)
	
	# 动画完成
	if split_progress >= 1.0:
		is_splitting = false
		_start_fade_in()

# 开始淡入动画
func _start_fade_in() -> void:
	# 显示主 Card 并初始化透明度
	main_card.visible = true
	main_card.modulate.a = 0.0
	is_fading_in = true
	fade_progress = 0.0

# 更新淡入动画
func _update_fade_in_animation(delta: float) -> void:
	fade_progress = move_toward(fade_progress, 1.0, FADE_IN_SPEED * delta)
	main_card.modulate.a = fade_progress
	
	if fade_progress >= 1.0:
		is_fading_in = false

# 卡牌唤醒信号回调
func _on_card_woke_up() -> void:
	is_zooming_out = true
	zoom_out_progress = 0.0

# 更新镜头缩放动画（从 3 到 1）
func _update_zoom_out_animation(delta: float) -> void:
	zoom_out_progress = move_toward(zoom_out_progress, 1.0, ZOOM_CARD_SPEED * delta)
	var current_zoom: float = lerp(ZOOM_CARD_START, ZOOM_CARD_END, zoom_out_progress)
	camera_2d.zoom = Vector2(current_zoom, current_zoom)
	
	if zoom_out_progress >= 1.0:
		is_zooming_out = false
