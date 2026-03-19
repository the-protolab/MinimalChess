# Bot policy: intentionally weak random legal move chooser.

def choose_random_legal_move(
  rule_set: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
) -> Maybe(Chess/Types/Move):
  moves = Chess/Engine/legal_moves_for_side(rule_set, state)
  count = Chess/Engine/list_length(Chess/Types/Move, moves)
  choose_from_count(state, moves, count)

def choose_from_count(
  state: Chess/Types/GameState,
  moves: List(Chess/Types/Move),
  count: U32,
) -> Maybe(Chess/Types/Move):
  match count === 0:
    case 0:
      idx = bot_index(state, count)
      move_at(moves, idx)
    case _:
      none{}

def bot_index(state: Chess/Types/GameState, count: U32) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      (((seed * 1664525) + 1013904223) % count)

def move_at(moves: List(Chess/Types/Move), idx: U32) -> Maybe(Chess/Types/Move):
  match moves:
    case []:
      none{}
    case mv<>rest:
      match idx === 0:
        case 0:
          move_at(rest, idx - 1)
        case _:
          some{mv}
