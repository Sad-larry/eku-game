# ==============================================================================
#   dialog_data.gd
#   功能：对话数据资源。定义 NPC 对话的完整流程。
# ==============================================================================
class_name DialogData extends Resource

@export var lines: Array[DialogLine] = []
@export var choices: Array[DialogChoice] = []
