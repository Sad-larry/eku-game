# ==============================================================================
#   PlayerStateMachine.gd
#   功能：玩家状态机类（当前为空实现），继承自通用的 StateMachine 基类，
#        用于管理玩家的各种状态（idle、move、attack、hurt、dead、recovery、skill 等）。
#        具体的状态注册和切换逻辑在 Player.init_state_machine() 中完成。
# ==============================================================================
extends StateMachine
class_name PlayerStateMachine

# 注意：当前文件仅为类型声明占位，实际状态机的核心逻辑（状态注册、切换、更新）
# 由通用的 StateMachine 基类提供。玩家状态机的具体使用方式：
#
# 1. 在 Player._init_state_machine() 中创建各状态实例并通过 add_state() 注册
# 2. 调用 change_to() 切换初始状态
# 3. 通过 send_event() 向当前状态发送事件
#
# 若后续需要扩展玩家特有的状态机逻辑（如跳跃状态管理、连招队列等），
# 可在此类中添加相应方法。
