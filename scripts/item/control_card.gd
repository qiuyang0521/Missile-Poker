extends Control

@onready var front_texture_rect: TextureRect = $FrontTextureRect
@onready var back_texture_rect: TextureRect = $BackTextureRect
@onready var button: Button = $Button

var tween: Tween
# 翻转进度：0.0 = 正面完全展示，1.0 = 背面完全展示
var _flip_progress: float = 0.0


func _ready() -> void:
	# 为每个实例复制独立的 ShaderMaterial，防止共享资源导致所有卡牌同步变化
	front_texture_rect.material = front_texture_rect.material.duplicate()
	back_texture_rect.material = back_texture_rect.material.duplicate()
	# 初始状态：背面隐藏
	back_texture_rect.visible = false
	_apply_flip(0.0)
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)


# 根据翻转进度统一更新两张 TextureRect 的显示状态
# 前半段 [0.0, 0.5]：正面从 y_rot=0 旋转到 90°（消失于侧面）
# 后半段 [0.5, 1.0]：背面从 y_rot=-90° 旋转到 0°（从侧面出现）
func _apply_flip(p: float) -> void:
	_flip_progress = p
	if p <= 0.5:
		# 正面旋转阶段：背面保持隐藏
		var t := p / 0.5
		front_texture_rect.visible = true
		back_texture_rect.visible = false
		front_texture_rect.material.set_shader_parameter("y_rot", t * 90.0)
		back_texture_rect.material.set_shader_parameter("y_rot", -90.0)
	else:
		# 背面旋转阶段：正面已超过90°，隐藏；背面开始显现
		var t := (p - 0.5) / 0.5
		front_texture_rect.visible = false
		back_texture_rect.visible = true
		front_texture_rect.material.set_shader_parameter("y_rot", 90.0)
		back_texture_rect.material.set_shader_parameter("y_rot", -90.0 + t * 90.0)


# 鼠标悬浮：将翻转进度推进到 1.0（背面完全展示）
# 动画时长根据当前进度等比缩短，中途打断也流畅
func _on_mouse_entered() -> void:
	if tween:
		tween.kill()
	var duration := (1.0 - _flip_progress) * 0.3
	tween = create_tween()
	tween.tween_method(_apply_flip, _flip_progress, 1.0, duration)


# 鼠标离开：将翻转进度退回到 0.0（正面完全展示）
func _on_mouse_exited() -> void:
	if tween:
		tween.kill()
	var duration := _flip_progress * 0.3
	tween = create_tween()
	tween.tween_method(_apply_flip, _flip_progress, 0.0, duration)
