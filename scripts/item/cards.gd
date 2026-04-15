extends Control

enum CardState{
	DRAGGING,
	RETURNING,  # 返回吸附点状态
	IDLE,       # 静止状态：停止在当前位置
	LYING,      # 躺下状态：初始状态，无法拖拽
}

const DEFAULT_OFFSET: Vector2 = Vector2(5, 5)  # CardBody 默认位置（阴影在左下）
const LIFT_OFFSET: Vector2 = Vector2(0, 0)      # 按下时抬起位置（向左上移动露出阴影）
const LIFT_SPEED: float = 15.0  # 抬起/放下的平滑速度
const CLICKS_TO_WAKE: int = 3       # 唤醒需要的点击次数

@export var follow_target: Node  # 跟随目标节点
@export var anchor_position: Vector2  # 吸附点位置（屏幕中心）
@export var spring_stiffness: float = 0.1  # 弹簧刚度系数（越大引力越强）
@export var damping: float = 0.65  # 阻尼系数（越小回弹越明显）
@export var drag_smoothness: float = 0.7  # 拖拽时的平滑系数

var velocity: Vector2 = Vector2.ZERO  # 速度向量（用于物理计算）

var card_current_state = CardState.LYING
var click_count: int = 0             # 点击计数
var drag_offset: Vector2 = Vector2(5, 5)

@onready var button: Button = $CardBody/Button
@onready var card_body: MarginContainer = $CardBody


func _ready() -> void:
	# 初始化锚点位置为当前全局位置（避免初始偏移）
	anchor_position = global_position
	if follow_target:
		anchor_position = follow_target.global_position - size / 2
	
	# 初始为躺下状态，设置旋转
	rotation_degrees = 0

func _process(delta: float) -> void:
	# 如果 follow_target 存在且有效，更新锚点位置
	if follow_target and is_instance_valid(follow_target):
		anchor_position = follow_target.global_position - size / 2
	
	match card_current_state:
		CardState.DRAGGING:
			_process_dragging(delta)
		CardState.RETURNING:
			_process_returning(delta)
		CardState.IDLE:
			_process_idle(delta)
		CardState.LYING:
			_process_lying(delta)

# 状态机：处理状态切换
func _change_state(new_state: CardState) -> void:
	if card_current_state != new_state:
		card_current_state = new_state
		print("State changed to: %s" % new_state)

func _on_button_button_down() -> void:
	# 如果是躺下模式，处理点击计数
	if card_current_state == CardState.LYING:
		_handle_lying_click()
	
	else:
		# 记录鼠标点击位置相对于卡牌的偏移量
		drag_offset = get_global_mouse_position() - global_position
		_change_state(CardState.DRAGGING)

func _on_button_button_up() -> void:
	# 躺下或唤醒状态下不处理按钮松开事件
	if card_current_state == CardState.LYING:
		return

	_change_state(CardState.IDLE)  # 松开按钮后进入静止状态，不再吸附

# 处理躺下状态的点击
func _handle_lying_click() -> void:
	click_count += 1
	print("Card clicked: %d / %d" % [click_count, CLICKS_TO_WAKE])
	
	if click_count >= CLICKS_TO_WAKE:
		_wake_up_card()

func _wake_up_card() -> void:
	print("Card waking up...")
	card_current_state = CardState.IDLE

# 处理拖拽状态（基类实现：CardBody 抬起 + 鼠标平滑跟随 + 速度计算）
func _process_dragging(delta: float) -> void:
	# 平滑移动 CardBody 到抬起位置，露出阴影
	if card_body:
		card_body.position = card_body.position.lerp(LIFT_OFFSET, LIFT_SPEED * delta)
	
	var target_position = get_global_mouse_position() - drag_offset
	global_position = global_position.lerp(target_position, drag_smoothness)  # 使用 lerp 实现平滑跟随
	velocity = (target_position - global_position) * drag_smoothness / delta * 0.5  # 计算当前速度（用于松开时的惯性）
	
	_on_drag_frame(delta)  # 调用扩展接口

# 处理返回吸附点状态（基类实现：弹簧物理回弹）
func _process_returning(delta: float) -> void:
	# 先平滑恢复 CardBody 到默认位置
	if card_body:
		card_body.position = card_body.position.lerp(DEFAULT_OFFSET, LIFT_SPEED * delta)
	
	var to_anchor = anchor_position - global_position
	var distance = to_anchor.length()
	
	if distance < 1.0:  # 如果距离非常近，直接设置位置并停止
		global_position = anchor_position
		velocity = Vector2.ZERO
		if card_body:
			card_body.position = DEFAULT_OFFSET
		return
	
	var spring_force = to_anchor * spring_stiffness  # 弹簧力：F = k * x（胡克定律）
	velocity += spring_force
	velocity *= damping  # 应用阻尼（模拟空气阻力）
	global_position += velocity * delta * 60.0  # 更新位置
	
	if abs(to_anchor.y) > 10:  # 添加轻微的重力效果，让运动更自然
		velocity.y += 50 * delta
	
	_on_return_frame(delta)  # 调用扩展接口

# 拖拽状态帧扩展接口（子类重写此方法以添加额外行为）
func _on_drag_frame(delta: float) -> void:
	_show_anchor(true)  # 默认：显示 anchor

# 返回状态帧扩展接口（子类重写此方法以添加额外行为）
func _on_return_frame(delta: float) -> void:
	pass  # 默认：无额外操作

# 处理静止状态（松开按钮后停止在当前位置）
func _process_idle(delta: float) -> void:
	# 平滑恢复 CardBody 到默认位置 (5, 5)，但卡牌位置保持不变
	if card_body:
		card_body.position = card_body.position.lerp(DEFAULT_OFFSET, LIFT_SPEED * delta)
	velocity = Vector2.ZERO  # 清除速度
	
	# 非拖拽状态时隐藏 anchor 节点
	_show_anchor(false)

# 控制 anchor 节点的显示/隐藏
func _show_anchor(visible: bool) -> void:
	if follow_target and is_instance_valid(follow_target):
		# 获取所有 anchor 节点（包括克隆的网格）
		var parent = follow_target.get_parent()
		if parent:
			for child in parent.get_children():
				if child.name.begins_with("Anchor"):
					child.visible = visible


# 处理躺下状态
func _process_lying(delta: float) -> void:
	# 躺下状态下保持旋转角度
	rotation_degrees = 0
	velocity = Vector2.ZERO
