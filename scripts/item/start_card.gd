extends Control

@onready var label: Label = $Label
@onready var button: Button = $Button

signal started  # 按钮按下时发射，通知外部开始动画

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	label.visible = false
	button.visible = false
	started.emit()
