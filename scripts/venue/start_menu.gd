extends Control

# MISSILE 对应的7个字母
const LETTERS: Array[String] = ["M", "I", "S", "S", "I", "L", "E"]

# 字母卡尺寸（与 control_card.tscn 中 FrontTextureRect 保持一致）
const CARD_WIDTH: float = 120.0
const CARD_HEIGHT: float = 180.0

# X 轴两侧各保留的边距
const MARGIN: float = 30.0

var _control_card_scene := preload("res://scenes/cards/control_card.tscn")


func _ready() -> void:
	_generate_missile_cards()


# 程序生成 MISSILE 7张字母卡，Y 轴居中，X 轴两侧留30px 均分
func _generate_missile_cards() -> void:
	# 固定使用 1920×1080 基准分辨率计算布局
	var viewport_size: Vector2 = Vector2(1920.0, 1080.0)
	var n: int = LETTERS.size()

	# 可用宽度去除两侧边距后，在卡牌间均匀分配间距
	var available_width: float = viewport_size.x - MARGIN * 2.0
	var spacing: float = (available_width - CARD_WIDTH * n) / float(n - 1)

	# Y 轴居中
	var card_y: float = (viewport_size.y - CARD_HEIGHT) / 2.0

	for i in range(n):
		var card: Control = _control_card_scene.instantiate()
		add_child(card)

		# 设置位置：X 从左边距起，每张卡间隔 (卡宽 + 间距)
		var card_x: float = MARGIN + i * (CARD_WIDTH + spacing)
		card.position = Vector2(card_x, card_y)

		# 为正面 TextureRect 设置大写字母图像，背面设置对应小写字母图像
		var letter: String = LETTERS[i]
		var front_texture: Texture2D = load("res://assets/ui/letter_card/大写/" + letter + ".png")
		var back_texture: Texture2D = load("res://assets/ui/letter_card/小写/" + letter.to_lower() + ".png")
		card.get_node("FrontTextureRect").texture = front_texture
		card.get_node("BackTextureRect").texture = back_texture

		# 第一个 S 字母卡（索引 2）被点击时跳转至 card_play_scene
		if i == 2:
			card.get_node("Button").pressed.connect(
				func(): get_tree().change_scene_to_file("res://scenes/venue/card_play_scene.tscn")
			)
