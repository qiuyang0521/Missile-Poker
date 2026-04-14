extends Node2D

const SPLIT_SPEED: float = 1.0       # 裂开动画速度
const SPLIT_DISTANCE: float = 120.8  # 上下各自移动距离
const ZOOM_START: float = 4.5        # 开始动画镜头初始缩放
const ZOOM_END: float = 2.0          # 开始动画镜头最终缩放
const FADE_IN_SPEED: float = 2.0     # 淡入动画速度
const ZOOM_CARD_START: float = 2.0   # 卡牌唤醒时镜头起始缩放
const ZOOM_CARD_END: float = 1.0     # 卡牌唤醒时镜头最终缩放
const ZOOM_CARD_SPEED: float = 1.5   # 卡牌唤醒镜头缩放速度

@onready var camera_2d: Camera2D = $Camera2D
@onready var start_card = $cards/StartCard
@onready var main_card: Control = $cards/Card
@onready var front_top_panel: Control = $cards/StartCard/FrontTop/Panel
@onready var front_bottom_panel: Control = $cards/StartCard/FrontBottom/Panel

var is_splitting: bool = false      # 是否正在播放裂开动画
var split_progress: float = 0.0     # 裂开进度 (0.0 ~ 1.0)
var is_fading_in: bool = false      # 是否正在播放淡入动画
var fade_progress: float = 0.0      # 淡入进度 (0.0 ~ 1.0)
var is_zooming_out: bool = false    # 是否正在播放镜头缩放动画（卡牌唤醒后）
var zoom_out_progress: float = 0.0  # 镜头缩放进度 (0.0 ~ 1.0)

func _ready() -> void:
	# 连接 start_card 的开始信号
	start_card.started.connect(_on_start_card_started)
	# 连接 player_card 的唤醒信号
	main_card.woke_up.connect(_on_card_woke_up)

# start_card 按钮按下后触发开始动画
func _on_start_card_started() -> void:
	is_splitting = true

func _process(delta: float) -> void:
	if is_splitting:
		_update_split_animation(delta)
	elif is_fading_in:
		_update_fade_in_animation(delta)
	elif is_zooming_out:
		_update_zoom_out_animation(delta)

# 更新裂开动画（含镜头缩放）
func _update_split_animation(delta: float) -> void:
	split_progress = move_toward(split_progress, 1.0, SPLIT_SPEED * delta)
	
	var current_offset: float = split_progress * SPLIT_DISTANCE
	front_top_panel.position.y = -current_offset
	front_bottom_panel.position.y = current_offset
	
	var current_zoom: float = lerp(ZOOM_START, ZOOM_END, split_progress)
	camera_2d.zoom = Vector2(current_zoom, current_zoom)
	
	if split_progress >= 1.0:
		is_splitting = false
		_start_fade_in()

# 开始淡入动画
func _start_fade_in() -> void:
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

# 卡牌唤醒信号回调，触发镜头缩放
func _on_card_woke_up() -> void:
	is_zooming_out = true
	zoom_out_progress = 0.0

# 更新镜头缩放动画（从 ZOOM_CARD_START 到 ZOOM_CARD_END）
func _update_zoom_out_animation(delta: float) -> void:
	zoom_out_progress = move_toward(zoom_out_progress, 1.0, ZOOM_CARD_SPEED * delta)
	var current_zoom: float = lerp(ZOOM_CARD_START, ZOOM_CARD_END, zoom_out_progress)
	camera_2d.zoom = Vector2(current_zoom, current_zoom)
	
	if zoom_out_progress >= 1.0:
		is_zooming_out = false
