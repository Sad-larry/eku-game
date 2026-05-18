# ==============================================================================
#   dialog_choice.gd
#   功能：对话选项数据。定义一个可选择的对话分支。
# ==============================================================================
class_name DialogChoice extends Resource

enum ChoiceType { TRADE, QUEST, INFO, GIFT, LEAVE }

@export var text: String = ""
@export var choice_type: ChoiceType = ChoiceType.LEAVE
@export var cost: int = 0               # 金币消耗（TRADE 类型）
@export var reward_coin: int = 0        # 奖励金币
@export var reward_heal_pct: float = 0.0  # 奖励回血百分比
