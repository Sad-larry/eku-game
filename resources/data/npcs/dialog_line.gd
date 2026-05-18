# ==============================================================================
#   dialog_line.gd
#   功能：对话行数据。定义单条对话的文本和说话者信息。
# ==============================================================================
class_name DialogLine extends Resource

@export var speaker_name: String = ""
@export var text: String = ""
@export var portrait: Texture2D
