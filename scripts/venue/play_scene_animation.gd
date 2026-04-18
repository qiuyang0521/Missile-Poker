extends Node2D

const SPLIT_SPEED: float = 1.0       # 裂开动画速度
const SPLIT_DISTANCE: float = 120.8  # 上下各自移动距离
const ZOOM_START: float = 4.5        # 开始动画镜头初始缩放
const ZOOM_END: float = 2.0          # 开始动画镜头最终缩放
const FADE_IN_SPEED: float = 2.0     # 淡入动画速度
const ZOOM_CARD_START: float = 2.0   # 卡牌唤醒时镜头起始缩放
const ZOOM_CARD_END: float = 1.0     # 卡牌唤醒时镜头最终缩放
const ZOOM_CARD_SPEED: float = 1.5   # 卡牌唤醒镜头缩放速度
const COVER_FADE_SPEED: float = 2.0  # Cover 淡入速度

const CARD_B_SCENE = preload("res://scenes/cards/card.tscn")  # 底部生成卡牌的场景

@onready var camera_2d: Camera2D = $Camera2D
@onready var start_card = $cards/StartCard
@onready var main_card: Control = $cards/Card
@onready var player_card: Control = $cards/PlayerCard
@onready var front_top_panel: Control = $cards/StartCard/FrontTop/Panel
@onready var front_bottom_panel: Control = $cards/StartCard/FrontBottom/Panel
@onready var cover_panel: Panel = $cards/StartCard/Cover

var is_splitting: bool = false      # 是否正在播放裂开动画
var split_progress: float = 0.0     # 裂开进度 (0.0 ~ 1.0)
var is_fading_in: bool = false      # 是否正在播放淡入动画
var fade_progress: float = 0.0      # 淡入进度 (0.0 ~ 1.0)
var is_zooming_out: bool = false    # 是否正在播放镜头缩放动画（卡牌唤醒后）
var zoom_out_progress: float = 0.0  # 镜头缩放进度 (0.0 ~ 1.0)
var is_cover_fading: bool = false   # 是否正在播放 Cover 淡入动画
var cover_fade_progress: float = 0.0  # Cover 淡入进度 (0.0 ~ 1.0)

func _ready() -> void:
	# 连接 start_card 的开始信号
	start_card.started.connect(_on_start_card_started)
	# 连接 main_card 的唤醒信号（触发镜头缩放）
	main_card.woke_up.connect(_on_card_woke_up)
	# 连接 player_card 的唤醒信号（点击3次后底部生成 B 卡）
	player_card.woke_up.connect(_on_player_card_woke_up)
	# Cover 初始完全透明
	cover_panel.modulate.a = 0.0

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
	# Cover 淡入与其他动画独立并行运行
	if is_cover_fading:
		_update_cover_fade_animation(delta)

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
		_start_cover_fade()
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

# 开始 Cover 淡入动画（裂开动画结束后触发）
func _start_cover_fade() -> void:
	cover_panel.visible = true
	cover_panel.modulate.a = 0.0
	is_cover_fading = true
	cover_fade_progress = 0.0

# 更新 Cover 淡入动画（alpha 0 → 1）
func _update_cover_fade_animation(delta: float) -> void:
	cover_fade_progress = move_toward(cover_fade_progress, 1.0, COVER_FADE_SPEED * delta)
	cover_panel.modulate.a = cover_fade_progress
	
	if cover_fade_progress >= 1.0:
		is_cover_fading = false

# player_card 被点击3次唤醒后在底部生成大写 B 卡牌
func _on_player_card_woke_up() -> void:
	_spawn_b_card()

# 实例化 card.tscn，赋予大写 B 图像，放置在场景底部居中
func _spawn_b_card() -> void:
	var new_card: Control = CARD_B_SCENE.instantiate()
	# 在 add_child 前设置位置，确保 _ready() 中 anchor_position 初始化正确
	# 底部居中：卡牌 160px 宽，x=-80 使其水平居中于 x=0
	# zoom=1 时可见范围底边为 y=540，y=260 使卡牌底部在 y=500 附近
	new_card.position = Vector2(-80.0, 260.0)
	$cards.add_child(new_card)
	# 设置大写 B 图像
	var texture_rect: TextureRect = new_card.get_node("CardBody/TextureRect")
	texture_rect.texture = load("res://assets/ui/letter_card/大写/B.png")
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
