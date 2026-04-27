extends Resource
class_name INPUTACTIONS

# TODO 快捷键需要修改，技能1为Q，技能2为2，技能3为3，技能4为E，UI确认为Z，UI取消为X
# region 输入映射配置
# 输入映射配置
# 字段说明：
# - type: 输入类型（action/axis）
# - bufferable: 是否支持输入缓冲（战斗核心操作开启）
# - keyboard: 键鼠按键（主/备选）
# - priority: 输入优先级（1-5，5最高，用于冲突处理）
# - description: 功能描述（多语言适配预留）
# - category: 分类（movement/combat/ui/debug）
const INPUT_ACTIONS_DICTIONARY: Dictionary[String, Dictionary] = {
	# 移动类（Movement）
	"move_left": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["A", "Left Arrow"],
		"priority": 5,
		"description": "向左移动",
		"category": "movement"
	},
	"move_right": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["D", "Right Arrow"],
		"priority": 5,
		"description": "向右移动",
		"category": "movement"
	},
	"move_up": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["W", "Up Arrow"],
		"priority": 5,
		"description": "向上移动",
		"category": "movement"
	},
	"move_down": {
		"type": "axis",
		"bufferable": false,
		"keyboard": ["S", "Down Arrow"],
		"priority": 5,
		"description": "向下移动",
		"category": "movement"
	},
	"dash": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["Left Shift", "Right Mouse"],
		"priority": 4,
		"description": "瞬移冲刺（连招核心）",
		"category": "movement"
	},

	# 战斗核心类（Combat）
	"attack": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["Left Mouse", "C"],
		"priority": 3,
		"description": "普通攻击（连招起手）",
		"category": "combat"
	},
	"skill_1": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["1"],
		"priority": 3,
		"description": "技能1（起手型）",
		"category": "combat"
	},
	"skill_2": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["2"],
		"priority": 3,
		"description": "技能2（终结型）",
		"category": "combat"
	},
	"skill_3": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["3"],
		"priority": 3,
		"description": "技能3（控制型）",
		"category": "combat"
	},
	"skill_4": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["4"],
		"priority": 3,
		"description": "技能4（生存型）",
		"category": "combat"
	},
	"interact": {
		"type": "action",
		"bufferable": true,
		"keyboard": ["F", "Space"],
		"priority": 2,
		"description": "交互（拾取/对话/开门）",
		"category": "combat"
	},

	# UI/系统类（UI/System）
	"pause": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["Escape", "P"],
		"priority": 1,
		"description": "暂停游戏/打开菜单",
		"category": "ui"
	},
	"ui_confirm_q": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["Q", "Enter"],
		"priority": 1,
		"description": "UI确认",
		"category": "ui"
	},
	"ui_cancel_e": {
		"type": "action",
		"bufferable": false,
		"keyboard": ["E", "Backspace"],
		"priority": 1,
		"description": "UI取消/返回",
		"category": "ui"
	}
}
# endregion
