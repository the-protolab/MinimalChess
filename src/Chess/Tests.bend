# Minimal engine assertions.

def init_board_0() -> List(Maybe(Chess/Types/Piece)):
  Chess/Engine/init_board()

def white_a1_piece() -> Maybe(Chess/Types/Piece):
  Chess/Engine/board_get(init_board_0(), 7, 0)

def black_a8_piece() -> Maybe(Chess/Types/Piece):
  Chess/Engine/board_get(init_board_0(), 0, 0)

def white_pawn_a2() -> Chess/Types/Piece:
  white_pawn_a2_cell(Chess/Engine/board_get(init_board_0(), 6, 0))

def white_pawn_a2_cell(cell: Maybe(Chess/Types/Piece)) -> Chess/Types/Piece:
  match cell:
    case none{}:
      piece{white{}, pawn{}}
    case some{p}:
      p

def white_pawn_can_step_one() -> U32:
  Chess/Engine/piece_can_move(init_board_0(), white_pawn_a2(), 6, 0, 5, 0)

def white_pawn_can_step_two() -> U32:
  Chess/Engine/piece_can_move(init_board_0(), white_pawn_a2(), 6, 0, 4, 0)

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
  white_pawn_can_step_one()
  == 1

assert : U32
  white_pawn_can_step_two()
  == 1
