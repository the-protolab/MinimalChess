# Minimal engine assertions + queen passive checks.

def init_board_0() -> List(Maybe(Chess/Types/Piece)):
  Chess/Engine/init_board()

def default_rules_0() -> Chess/Types/RuleSet:
  Chess/Queens/default_rules()

def plus_rules_0() -> Chess/Types/RuleSet:
  inv0 = Chess/Queens/initial_inventory()
  inv1 = Chess/Queens/buy(inv0, queen_plus{})
  inv2 = Chess/Queens/select(inv1, queen_plus{})
  Chess/Queens/resolve_rules(inv2)

def minus_rules_0() -> Chess/Types/RuleSet:
  inv0 = Chess/Queens/initial_inventory()
  inv1 = Chess/Queens/buy(inv0, queen_minus{})
  inv2 = Chess/Queens/select(inv1, queen_minus{})
  Chess/Queens/resolve_rules(inv2)

def white_a1_piece() -> Maybe(Chess/Types/Piece):
  Chess/Engine/board_get(init_board_0(), 7, 0)

def black_a8_piece() -> Maybe(Chess/Types/Piece):
  Chess/Engine/board_get(init_board_0(), 0, 0)

def piece_or_white_pawn(cell: Maybe(Chess/Types/Piece)) -> Chess/Types/Piece:
  match cell:
    case none{}:
      piece{white{}, pawn{}}
    case some{p}:
      p

def white_pawn_a2() -> Chess/Types/Piece:
  piece_or_white_pawn(Chess/Engine/board_get(init_board_0(), 6, 0))

def board_after_a2_a3() -> List(Maybe(Chess/Types/Piece)):
  mv = (move{pos{6, 0}, pos{5, 0}} :: Chess/Types/Move)
  Chess/Engine/board_after_move(init_board_0(), mv)

def white_pawn_a3() -> Chess/Types/Piece:
  piece_or_white_pawn(Chess/Engine/board_get(board_after_a2_a3(), 5, 0))

def pawn_default_step_one() -> U32:
  Chess/Engine/piece_can_move(default_rules_0(), init_board_0(), white_pawn_a2(), 6, 0, 5, 0)

def pawn_default_step_two() -> U32:
  Chess/Engine/piece_can_move(default_rules_0(), init_board_0(), white_pawn_a2(), 6, 0, 4, 0)

def pawn_default_step_three() -> U32:
  Chess/Engine/piece_can_move(default_rules_0(), init_board_0(), white_pawn_a2(), 6, 0, 3, 0)

def pawn_plus_step_three() -> U32:
  Chess/Engine/piece_can_move(plus_rules_0(), init_board_0(), white_pawn_a2(), 6, 0, 3, 0)

def pawn_minus_step_two() -> U32:
  Chess/Engine/piece_can_move(minus_rules_0(), init_board_0(), white_pawn_a2(), 6, 0, 4, 0)

def pawn_after_first_move_only_one() -> U32:
  Chess/Engine/piece_can_move(plus_rules_0(), board_after_a2_a3(), white_pawn_a3(), 5, 0, 3, 0)

def pawn_after_first_move_step_one() -> U32:
  Chess/Engine/piece_can_move(plus_rules_0(), board_after_a2_a3(), white_pawn_a3(), 5, 0, 4, 0)

def plus_start_game() -> Chess/Types/GameState:
  Chess/Engine/init_state_with_rules(plus_rules_0())

def minus_start_game() -> Chess/Types/GameState:
  Chess/Engine/init_state_with_rules(minus_rules_0())

def plus_legal_a2_a5() -> U32:
  mv = (move{pos{6, 0}, pos{3, 0}} :: Chess/Types/Move)
  moves = Chess/Engine/legal_moves_from(plus_rules_0(), plus_start_game(), pos{6, 0})
  Chess/Engine/move_in_list(mv, moves)

def minus_legal_a2_a4() -> U32:
  mv = (move{pos{6, 0}, pos{4, 0}} :: Chess/Types/Move)
  moves = Chess/Engine/legal_moves_from(minus_rules_0(), minus_start_game(), pos{6, 0})
  Chess/Engine/move_in_list(mv, moves)

def empty_board_i(i: U32) -> List(Maybe(Chess/Types/Piece)):
  match i === Chess/Engine/BOARD_CELLS:
    case 0:
      (none{}<>empty_board_i(i + 1) :: List(Maybe(Chess/Types/Piece)))
    case _:
      ([] :: List(Maybe(Chess/Types/Piece)))

def empty_board() -> List(Maybe(Chess/Types/Piece)):
  empty_board_i(0)

def white_king_missing_board() -> List(Maybe(Chess/Types/Piece)):
  b0 = empty_board()
  b1 = Chess/Engine/board_set(b0, 0, 0, some{piece{black{}, king{}}})
  b2 = Chess/Engine/board_set(b1, 7, 0, some{piece{white{}, rook{}}})
  b2

def white_king_missing_state() -> Chess/Types/GameState:
  game{white_king_missing_board(), white{}, Chess/Engine/no_selection(), Chess/Engine/no_targets(), "-", "-", "-", "-", playing{}, 1, human{}, human{}}

def white_king_missing_evaluated() -> Chess/Types/GameState:
  Chess/Engine/evaluate_outcome(default_rules_0(), white_king_missing_state())

def white_king_missing_outcome_live_state(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      Chess/Engine/is_playing(outcome)

def white_king_missing_outcome_live() -> U32:
  white_king_missing_outcome_live_state(white_king_missing_evaluated())

def white_king_missing_winner_is_black_state(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      match outcome:
        case checkmate{winner}:
          Chess/Engine/color_eq(winner, black{})
        case _:
          0

def white_king_missing_winner_is_black() -> U32:
  white_king_missing_winner_is_black_state(white_king_missing_evaluated())

assert : U32
  Chess/Engine/square_is_dark(7, 0)
  == 1

assert : U32
  Chess/Engine/square_is_dark(7, 7)
  == 0

assert : U32
  Chess/Engine/is_piece_of_color(white_a1_piece(), white{})
  == 1

assert : U32
  Chess/Engine/is_piece_of_color(black_a8_piece(), black{})
  == 1

assert : U32
  pawn_default_step_one()
  == 1

assert : U32
  pawn_default_step_two()
  == 1

assert : U32
  pawn_default_step_three()
  == 0

assert : U32
  pawn_plus_step_three()
  == 1

assert : U32
  pawn_minus_step_two()
  == 0

assert : U32
  pawn_after_first_move_only_one()
  == 0

assert : U32
  pawn_after_first_move_step_one()
  == 1

assert : U32
  plus_legal_a2_a5()
  == 1

assert : U32
  minus_legal_a2_a4()
  == 0

assert : U32
  white_king_missing_outcome_live()
  == 0

assert : U32
  white_king_missing_winner_is_black()
  == 1
