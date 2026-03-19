# Chess engine: pure rules and state transitions.

BOARD_SIZE : U32 = 8
BOARD_CELLS : U32 = 64

# ----------
# List utils
# ----------

def list_append(A: Type, xs: List(A), ys: List(A)) -> List(A):
  match xs:
    case []:
      ys
    case x<>rest:
      x<>list_append(A, rest, ys)

def list_length(A: Type, xs: List(A)) -> U32:
  match xs:
    case []:
      0
    case _<>rest:
      1 + list_length(A, rest)

def list_is_empty(A: Type, xs: List(A)) -> U32:
  match xs:
    case []:
      1
    case _<>_:
      0

def no_selection() -> Maybe(Chess/Types/Pos):
  (none{} :: Maybe(Chess/Types/Pos))

def no_targets() -> List(Chess/Types/Move):
  ([] :: List(Chess/Types/Move))

def list_get_opt(A: Type, xs: List(A), i: U32) -> Maybe(A):
  match xs:
    case []:
      none{}
    case x<>rest:
      match i === 0:
        case 0:
          list_get_opt(A, rest, i - 1)
        case _:
          some{x}

def list_set(A: Type, xs: List(A), i: U32, v: A) -> List(A):
  match xs:
    case []:
      ([] :: List(A))
    case x<>rest:
      list_set_pick(A, x, rest, i, v, i === 0)

def list_set_pick(A: Type, x: A, rest: List(A), i: U32, v: A, is_zero: U32) -> List(A):
  match is_zero:
    case 0:
      x<>list_set(A, rest, i - 1, v)
    case _:
      v<>rest

# ----------------
# Piece primitives
# ----------------

def color_eq(a: Chess/Types/Color, b: Chess/Types/Color) -> U32:
  match a b:
    case white{} white{}:
      1
    case black{} black{}:
      1
    case _ _:
      0

def other_color(c: Chess/Types/Color) -> Chess/Types/Color:
  match c:
    case white{}:
      black{}
    case black{}:
      white{}

def color_name(c: Chess/Types/Color) -> String:
  match c:
    case white{}:
      "White"
    case black{}:
      "Black"

def piece_color(p: Chess/Types/Piece) -> Chess/Types/Color:
  match p:
    case piece{color, kind}:
      color

def piece_kind(p: Chess/Types/Piece) -> Chess/Types/PieceKind:
  match p:
    case piece{color, kind}:
      kind

def is_piece_of_color(cell: Maybe(Chess/Types/Piece), color: Chess/Types/Color) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{c, k}}:
      color_eq(c, color)

def has_enemy_piece(cell: Maybe(Chess/Types/Piece), color: Chess/Types/Color) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{c, k}}:
      color_eq(c, color) === 0

def cell_is_empty(cell: Maybe(Chess/Types/Piece)) -> U32:
  match cell:
    case none{}:
      1
    case some{_}:
      0

# -----------------
# Position and move
# -----------------

def pos_eq(a: Chess/Types/Pos, b: Chess/Types/Pos) -> U32:
  match a b:
    case pos{ar, ac} pos{br, bc}:
      (ar === br) & (ac === bc)

def move_eq(a: Chess/Types/Move, b: Chess/Types/Move) -> U32:
  match a b:
    case move{af, at} move{bf, bt}:
      pos_eq(af, bf) & pos_eq(at, bt)

def move_in_list(mv: Chess/Types/Move, xs: List(Chess/Types/Move)) -> U32:
  match xs:
    case []:
      0
    case x<>rest:
      match move_eq(mv, x):
        case 0:
          move_in_list(mv, rest)
        case _:
          1

# ---------------
# Board accessors
# ---------------

def board_index(row: U32, col: U32) -> U32:
  row * BOARD_SIZE + col

def board_get_idx(board: List(Maybe(Chess/Types/Piece)), idx: U32) -> Maybe(Chess/Types/Piece):
  match board:
    case []:
      none{}
    case cell<>rest:
      match idx === 0:
        case 0:
          board_get_idx(rest, idx - 1)
        case _:
          cell

def board_get(board: List(Maybe(Chess/Types/Piece)), row: U32, col: U32) -> Maybe(Chess/Types/Piece):
  board_get_idx(board, board_index(row, col))

def board_set_idx(board: List(Maybe(Chess/Types/Piece)), idx: U32, val: Maybe(Chess/Types/Piece)) -> List(Maybe(Chess/Types/Piece)):
  match board:
    case []:
      ([] :: List(Maybe(Chess/Types/Piece)))
    case cell<>rest:
      board_set_idx_pick(cell, rest, idx, val, idx === 0)

def board_set_idx_pick(
  cell: Maybe(Chess/Types/Piece),
  rest: List(Maybe(Chess/Types/Piece)),
  idx: U32,
  val: Maybe(Chess/Types/Piece),
  is_zero: U32,
) -> List(Maybe(Chess/Types/Piece)):
  match is_zero:
    case 0:
      cell<>board_set_idx(rest, idx - 1, val)
    case _:
      val<>rest

def board_set(board: List(Maybe(Chess/Types/Piece)), row: U32, col: U32, val: Maybe(Chess/Types/Piece)) -> List(Maybe(Chess/Types/Piece)):
  board_set_idx(board, board_index(row, col), val)

# -----------------
# Initial board map
# -----------------

def major_piece(col: U32, color: Chess/Types/Color) -> Maybe(Chess/Types/Piece):
  match col:
    case 0:
      some{piece{color, rook{}}}
    case 1:
      some{piece{color, knight{}}}
    case 2:
      some{piece{color, bishop{}}}
    case 3:
      some{piece{color, queen{}}}
    case 4:
      some{piece{color, king{}}}
    case 5:
      some{piece{color, bishop{}}}
    case 6:
      some{piece{color, knight{}}}
    case 7:
      some{piece{color, rook{}}}
    case _:
      none{}

def initial_piece(row: U32, col: U32) -> Maybe(Chess/Types/Piece):
  match row:
    case 0:
      major_piece(col, black{})
    case 1:
      some{piece{black{}, pawn{}}}
    case 6:
      some{piece{white{}, pawn{}}}
    case 7:
      major_piece(col, white{})
    case _:
      none{}

def init_board_i(i: U32) -> List(Maybe(Chess/Types/Piece)):
  init_board_i_stop(i, i === BOARD_CELLS)

def init_board_i_stop(i: U32, stop: U32) -> List(Maybe(Chess/Types/Piece)):
  match stop:
    case 0:
      row = i // BOARD_SIZE;
      col = i % BOARD_SIZE;
      initial_piece(row, col) <> init_board_i(i + 1)
    case _:
      ([] :: List(Maybe(Chess/Types/Piece)))

def init_board() -> List(Maybe(Chess/Types/Piece)):
  init_board_i(0)

init_state : Chess/Types/GameState =
  game{init_board(), white{}, none{}, [], "White to move.", "-", playing{}, 1, human{}, bot{}}

# ----------
# UI helpers
# ----------

def square_is_dark(row: U32, col: U32) -> U32:
  ((row + col) % 2) === 1

def file_name(col: U32) -> String:
  match col:
    case 0:
      "a"
    case 1:
      "b"
    case 2:
      "c"
    case 3:
      "d"
    case 4:
      "e"
    case 5:
      "f"
    case 6:
      "g"
    case 7:
      "h"
    case _:
      "?"

def square_name(p: Chess/Types/Pos) -> String:
  match p:
    case pos{row, col}:
      file_name(col) ++ U32/show(8 - row)

def move_to_string(mv: Chess/Types/Move) -> String:
  match mv:
    case move{from, to}:
      square_name(from) ++ " -> " ++ square_name(to)

def piece_symbol(cell: Maybe(Chess/Types/Piece)) -> String:
  match cell:
    case none{}:
      ""
    case some{piece{color, kind}}:
      piece_symbol_kind(color, kind)

def piece_symbol_kind(color: Chess/Types/Color, kind: Chess/Types/PieceKind) -> String:
  match color kind:
    case white{} king{}:
      "♔"
    case white{} queen{}:
      "♕"
    case white{} rook{}:
      "♖"
    case white{} bishop{}:
      "♗"
    case white{} knight{}:
      "♘"
    case white{} pawn{}:
      "♙"
    case black{} king{}:
      "♚"
    case black{} queen{}:
      "♛"
    case black{} rook{}:
      "♜"
    case black{} bishop{}:
      "♝"
    case black{} knight{}:
      "♞"
    case black{} pawn{}:
      "♟"

# -------------------------
# Movement geometry helpers
# -------------------------

def step_axis(cur: U32, targ: U32) -> U32:
  match cur < targ:
    case 0:
      step_axis_down(cur, cur > targ)
    case _:
      cur + 1

def step_axis_down(cur: U32, gt: U32) -> U32:
  match gt:
    case 0:
      cur
    case _:
      cur - 1

def path_clear_between(
  board: List(Maybe(Chess/Types/Piece)),
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  nr = step_axis(fr, tr);
  nc = step_axis(fc, tc);
  path_clear_step(board, nr, nc, tr, tc)

def path_clear_step(
  board: List(Maybe(Chess/Types/Piece)),
  cr: U32,
  cc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  hit = (cr === tr) & (cc === tc);
  match hit:
    case 0:
      path_clear_open(board_get(board, cr, cc), board, cr, cc, tr, tc)
    case _:
      1

def path_clear_open(
  cell: Maybe(Chess/Types/Piece),
  board: List(Maybe(Chess/Types/Piece)),
  cr: U32,
  cc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  match cell:
    case none{}:
      nr = step_axis(cr, tr);
      nc = step_axis(cc, tc);
      path_clear_step(board, nr, nc, tr, tc)
    case some{_}:
      0

# -----------------
# Piece move checks
# -----------------

def piece_can_move(
  board: List(Maybe(Chess/Types/Piece)),
  piece: Chess/Types/Piece,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  same = (fr === tr) & (fc === tc);
  match same:
    case 0:
      dest = board_get(board, tr, tc)
      own  = is_piece_of_color(dest, piece_color(piece))
      match own:
        case 0:
          piece_can_move_kind(board, piece, fr, fc, tr, tc, dest)
        case _:
          0
    case _:
      0

def piece_can_move_kind(
  board: List(Maybe(Chess/Types/Piece)),
  piece: Chess/Types/Piece,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
  dest: Maybe(Chess/Types/Piece),
) -> U32:
  match piece:
    case piece{color, kind}:
      match kind:
        case pawn{}:
          pawn_can_move(board, color, fr, fc, tr, tc, dest)
        case knight{}:
          knight_can_move(fr, fc, tr, tc)
        case bishop{}:
          bishop_can_move(board, fr, fc, tr, tc)
        case rook{}:
          rook_can_move(board, fr, fc, tr, tc)
        case queen{}:
          queen_can_move(board, fr, fc, tr, tc)
        case king{}:
          king_can_move(fr, fc, tr, tc)

def pawn_can_move(
  board: List(Maybe(Chess/Types/Piece)),
  color: Chess/Types/Color,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
  dest: Maybe(Chess/Types/Piece),
) -> U32:
  match color:
    case white{}:
      pawn_can_move_white(board, fr, fc, tr, tc, dest)
    case black{}:
      pawn_can_move_black(board, fr, fc, tr, tc, dest)

def pawn_can_move_white(
  board: List(Maybe(Chess/Types/Piece)),
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
  dest: Maybe(Chess/Types/Piece),
) -> U32:
  one_fwd = (fc === tc) & (fr === (tr + 1)) & cell_is_empty(dest)
  mid     = board_get(board, 5, fc)
  two_fwd = (fc === tc) & (fr === 6) & (tr === 4) & cell_is_empty(dest) & cell_is_empty(mid)
  diag    = (fr === (tr + 1)) & (U32/abs_diff(fc, tc) === 1) & has_enemy_piece(dest, white{})
  one_fwd | two_fwd | diag

def pawn_can_move_black(
  board: List(Maybe(Chess/Types/Piece)),
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
  dest: Maybe(Chess/Types/Piece),
) -> U32:
  one_fwd = (fc === tc) & (tr === (fr + 1)) & cell_is_empty(dest)
  mid     = board_get(board, 2, fc)
  two_fwd = (fc === tc) & (fr === 1) & (tr === 3) & cell_is_empty(dest) & cell_is_empty(mid)
  diag    = (tr === (fr + 1)) & (U32/abs_diff(fc, tc) === 1) & has_enemy_piece(dest, black{})
  one_fwd | two_fwd | diag

def knight_can_move(fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  dr = U32/abs_diff(fr, tr)
  dc = U32/abs_diff(fc, tc)
  ((dr === 2) & (dc === 1)) | ((dr === 1) & (dc === 2))

def bishop_can_move(board: List(Maybe(Chess/Types/Piece)), fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  dr = U32/abs_diff(fr, tr)
  dc = U32/abs_diff(fc, tc)
  diag = (dr === dc) & (dr > 0)
  match diag:
    case 0:
      0
    case _:
      path_clear_between(board, fr, fc, tr, tc)

def rook_can_move(board: List(Maybe(Chess/Types/Piece)), fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  same_row = fr === tr
  same_col = fc === tc
  line = same_row | same_col
  match line:
    case 0:
      0
    case _:
      path_clear_between(board, fr, fc, tr, tc)

def queen_can_move(board: List(Maybe(Chess/Types/Piece)), fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  rook_can_move(board, fr, fc, tr, tc) | bishop_can_move(board, fr, fc, tr, tc)

def king_can_move(fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  dr = U32/abs_diff(fr, tr)
  dc = U32/abs_diff(fc, tc)
  same = (dr === 0) & (dc === 0)
  (dr <= 1) & (dc <= 1) & (same === 0)

# -------------------------
# Piece attack check helper
# -------------------------

def piece_attacks_square(
  board: List(Maybe(Chess/Types/Piece)),
  piece: Chess/Types/Piece,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  same = (fr === tr) & (fc === tc)
  piece_attacks_square_same(board, piece, fr, fc, tr, tc, same)

def piece_attacks_square_same(
  board: List(Maybe(Chess/Types/Piece)),
  piece: Chess/Types/Piece,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
  same: U32,
) -> U32:
  match same:
    case 0:
      piece_attacks_square_piece(board, piece, fr, fc, tr, tc)
    case _:
      0

def piece_attacks_square_piece(
  board: List(Maybe(Chess/Types/Piece)),
  piece: Chess/Types/Piece,
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  match piece:
    case piece{color, kind}:
      match kind:
        case pawn{}:
          pawn_attacks_square(color, fr, fc, tr, tc)
        case knight{}:
          knight_can_move(fr, fc, tr, tc)
        case bishop{}:
          bishop_can_move(board, fr, fc, tr, tc)
        case rook{}:
          rook_can_move(board, fr, fc, tr, tc)
        case queen{}:
          queen_can_move(board, fr, fc, tr, tc)
        case king{}:
          king_can_move(fr, fc, tr, tc)

def pawn_attacks_square(color: Chess/Types/Color, fr: U32, fc: U32, tr: U32, tc: U32) -> U32:
  match color:
    case white{}:
      (fr === (tr + 1)) & (U32/abs_diff(fc, tc) === 1)
    case black{}:
      (tr === (fr + 1)) & (U32/abs_diff(fc, tc) === 1)

# -----------------------
# Check and legal-move API
# -----------------------

def find_king(board: List(Maybe(Chess/Types/Piece)), color: Chess/Types/Color) -> Maybe(Chess/Types/Pos):
  find_king_i(board, color, 0)

def find_king_i(board: List(Maybe(Chess/Types/Piece)), color: Chess/Types/Color, idx: U32) -> Maybe(Chess/Types/Pos):
  match board:
    case []:
      none{}
    case cell<>rest:
      match cell:
        case none{}:
          find_king_i(rest, color, idx + 1)
        case some{piece{c, k}}:
          own = color_eq(c, color)
          isk = king_is(k)
          match own & isk:
            case 0:
              find_king_i(rest, color, idx + 1)
            case _:
              some{pos{idx // BOARD_SIZE, idx % BOARD_SIZE}}

def king_is(k: Chess/Types/PieceKind) -> U32:
  match k:
    case king{}:
      1
    case _:
      0

def is_square_attacked(
  board: List(Maybe(Chess/Types/Piece)),
  attacker: Chess/Types/Color,
  tr: U32,
  tc: U32,
) -> U32:
  is_square_attacked_i(board, attacker, tr, tc, 0)

def is_square_attacked_i(
  board: List(Maybe(Chess/Types/Piece)),
  attacker: Chess/Types/Color,
  tr: U32,
  tc: U32,
  idx: U32,
) -> U32:
  match idx === BOARD_CELLS:
    case 0:
      fr = idx // BOARD_SIZE
      fc = idx % BOARD_SIZE
      cell = board_get(board, fr, fc)
      hit = cell_attacks(cell, attacker, board, fr, fc, tr, tc)
      match hit:
        case 0:
          is_square_attacked_i(board, attacker, tr, tc, idx + 1)
        case _:
          1
    case _:
      0

def cell_attacks(
  cell: Maybe(Chess/Types/Piece),
  attacker: Chess/Types/Color,
  board: List(Maybe(Chess/Types/Piece)),
  fr: U32,
  fc: U32,
  tr: U32,
  tc: U32,
) -> U32:
  match cell:
    case none{}:
      0
    case some{piece{c, k}}:
      match color_eq(c, attacker):
        case 0:
          0
        case _:
          piece_attacks_square(board, piece{c, k}, fr, fc, tr, tc)

def is_in_check(board: List(Maybe(Chess/Types/Piece)), color: Chess/Types/Color) -> U32:
  is_in_check_kp(board, color, find_king(board, color))

def is_in_check_kp(
  board: List(Maybe(Chess/Types/Piece)),
  color: Chess/Types/Color,
  kp: Maybe(Chess/Types/Pos),
) -> U32:
  match kp:
    case none{}:
      1
    case some{pos{kr, kc}}:
      is_square_attacked(board, other_color(color), kr, kc)

# ---------------
# Move application
# ---------------

def promote_if_needed(piece: Chess/Types/Piece, tr: U32) -> Chess/Types/Piece:
  match piece:
    case piece{color, kind}:
      match kind:
        case pawn{}:
          promote_pawn(color, kind, tr)
        case _:
          piece{color, kind}

def promote_pawn(color: Chess/Types/Color, kind: Chess/Types/PieceKind, tr: U32) -> Chess/Types/Piece:
  match color:
    case white{}:
      promote_pawn_white(color, kind, tr)
    case black{}:
      promote_pawn_black(color, kind, tr)

def promote_pawn_white(color: Chess/Types/Color, kind: Chess/Types/PieceKind, tr: U32) -> Chess/Types/Piece:
  promote_pawn_white_last(color, kind, tr === 0)

def promote_pawn_white_last(color: Chess/Types/Color, kind: Chess/Types/PieceKind, is_last: U32) -> Chess/Types/Piece:
  match is_last:
    case 0:
      piece{color, kind}
    case _:
      piece{color, queen{}}

def promote_pawn_black(color: Chess/Types/Color, kind: Chess/Types/PieceKind, tr: U32) -> Chess/Types/Piece:
  promote_pawn_black_last(color, kind, tr === 7)

def promote_pawn_black_last(color: Chess/Types/Color, kind: Chess/Types/PieceKind, is_last: U32) -> Chess/Types/Piece:
  match is_last:
    case 0:
      piece{color, kind}
    case _:
      piece{color, queen{}}

def move_piece_cell(cell: Maybe(Chess/Types/Piece), tr: U32) -> Maybe(Chess/Types/Piece):
  match cell:
    case none{}:
      none{}
    case some{piece{color, kind}}:
      some{promote_if_needed(piece{color, kind}, tr)}

def board_after_move(board: List(Maybe(Chess/Types/Piece)), mv: Chess/Types/Move) -> List(Maybe(Chess/Types/Piece)):
  match mv:
    case move{from, to}:
      match from to:
        case pos{fr, fc} pos{tr, tc}:
          moving = board_get(board, fr, fc)
          board1 = board_set(board, fr, fc, none{})
          board2 = board_set(board1, tr, tc, move_piece_cell(moving, tr))
          board2

# ---------------------
# Legal move generation
# ---------------------

def legal_moves_for_side(state: Chess/Types/GameState) -> List(Chess/Types/Move):
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      legal_moves_for_board_side(board, side)

def legal_moves_for_board_side(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
) -> List(Chess/Types/Move):
  legal_moves_for_board_side_i(board, side, 0)

def legal_moves_for_board_side_i(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  idx: U32,
) -> List(Chess/Types/Move):
  match idx === BOARD_CELLS:
    case 0:
      fr = idx // BOARD_SIZE
      fc = idx % BOARD_SIZE
      cell = board_get(board, fr, fc)
      here = legal_moves_from_cell(cell, board, side, fr, fc)
      rest = legal_moves_for_board_side_i(board, side, idx + 1)
      list_append(Chess/Types/Move, here, rest)
    case _:
      ([] :: List(Chess/Types/Move))

def legal_moves_from_cell(
  cell: Maybe(Chess/Types/Piece),
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  fr: U32,
  fc: U32,
) -> List(Chess/Types/Move):
  match cell:
    case none{}:
      ([] :: List(Chess/Types/Move))
    case some{piece{c, k}}:
      match color_eq(c, side):
        case 0:
          ([] :: List(Chess/Types/Move))
        case _:
          legal_moves_from_piece(piece{c, k}, board, side, fr, fc, 0)

def legal_moves_from_piece(
  piece: Chess/Types/Piece,
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  fr: U32,
  fc: U32,
  to_idx: U32,
) -> List(Chess/Types/Move):
  legal_moves_from_piece_stop(piece, board, side, fr, fc, to_idx, to_idx === BOARD_CELLS)

def legal_moves_from_piece_stop(
  piece: Chess/Types/Piece,
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  fr: U32,
  fc: U32,
  to_idx: U32,
  stop: U32,
) -> List(Chess/Types/Move):
  match stop:
    case 0:
      tr = to_idx // BOARD_SIZE
      tc = to_idx % BOARD_SIZE
      mv = (move{pos{fr, fc}, pos{tr, tc}} :: Chess/Types/Move)
      ok_pseudo = piece_can_move(board, piece, fr, fc, tr, tc)
      ok_legal  = legal_after_check(board, side, mv, ok_pseudo)
      rest = legal_moves_from_piece(piece, board, side, fr, fc, to_idx + 1)
      legal_moves_from_piece_join(mv, rest, ok_legal)
    case _:
      ([] :: List(Chess/Types/Move))

def legal_moves_from_piece_join(
  mv: Chess/Types/Move,
  rest: List(Chess/Types/Move),
  ok_legal: U32,
) -> List(Chess/Types/Move):
  match ok_legal:
    case 0:
      rest
    case _:
      move_list_cons(mv, rest)

def move_list_cons(
  mv: Chess/Types/Move,
  rest: List(Chess/Types/Move),
) -> List(Chess/Types/Move):
  (mv<>rest :: List(Chess/Types/Move))

def legal_after_check(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  mv: Chess/Types/Move,
  ok_pseudo: U32,
) -> U32:
  match ok_pseudo:
    case 0:
      0
    case _:
      board2 = board_after_move(board, mv)
      is_in_check(board2, side) === 0

def legal_moves_from(state: Chess/Types/GameState, from: Chess/Types/Pos) -> List(Chess/Types/Move):
  moves = legal_moves_for_side(state)
  legal_moves_from_filter(moves, from)

def legal_moves_from_filter(moves: List(Chess/Types/Move), from: Chess/Types/Pos) -> List(Chess/Types/Move):
  match moves:
    case []:
      ([] :: List(Chess/Types/Move))
    case mv<>rest:
      match move_has_from(mv, from):
        case 0:
          legal_moves_from_filter(rest, from)
        case _:
          mv<>legal_moves_from_filter(rest, from)

def move_has_from(mv: Chess/Types/Move, from: Chess/Types/Pos) -> U32:
  match mv:
    case move{f, t}:
      pos_eq(f, from)

def move_targets_pos(moves: List(Chess/Types/Move), row: U32, col: U32) -> U32:
  match moves:
    case []:
      0
    case mv<>rest:
      match mv:
        case move{from, pos{tr, tc}}:
          hit = (tr === row) & (tc === col)
          match hit:
            case 0:
              move_targets_pos(rest, row, col)
            case _:
              1

# --------------------
# Outcome + state APIs
# --------------------

def turn_status(side: Chess/Types/Color, check: U32) -> String:
  match check:
    case 0:
      color_name(side) ++ " to move."
    case _:
      color_name(side) ++ " to move (check)."

def outcome_text(outcome: Chess/Types/Outcome) -> String:
  match outcome:
    case playing{}:
      "In progress"
    case stalemate{}:
      "Stalemate"
    case checkmate{winner}:
      "Checkmate - " ++ color_name(winner) ++ " wins"

def is_playing(outcome: Chess/Types/Outcome) -> U32:
  match outcome:
    case playing{}:
      1
    case _:
      0

def evaluate_outcome(state: Chess/Types/GameState) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      moves = legal_moves_for_board_side(board, side)
      no_moves = list_is_empty(Chess/Types/Move, moves)
      check = is_in_check(board, side)
      evaluate_outcome_flags(board, side, selected, targets, status, last_move, outcome, seed, wc, bc, no_moves, check)

def evaluate_outcome_flags(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  status: String,
  last_move: String,
  outcome: Chess/Types/Outcome,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
  no_moves: U32,
  check: U32,
) -> Chess/Types/GameState:
  match no_moves:
    case 0:
      game{board, side, selected, targets, turn_status(side, check), last_move, playing{}, seed, wc, bc}
    case _:
      evaluate_no_moves(board, side, selected, targets, status, last_move, outcome, seed, wc, bc, check)

def evaluate_no_moves(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  status: String,
  last_move: String,
  outcome: Chess/Types/Outcome,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
  check: U32,
) -> Chess/Types/GameState:
  match check:
    case 0:
      game{board, side, selected, targets, "Stalemate.", last_move, stalemate{}, seed, wc, bc}
    case _:
      winner = other_color(side)
      game{board, side, selected, targets, "Checkmate. " ++ color_name(winner) ++ " wins.", last_move, checkmate{winner}, seed, wc, bc}

def set_status(state: Chess/Types/GameState, msg: String) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      game{board, side, selected, targets, msg, last_move, outcome, seed, wc, bc}

def set_selection(
  state: Chess/Types/GameState,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  msg: String,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, s0, t0, status, last_move, outcome, seed, wc, bc}:
      game{board, side, selected, targets, msg, last_move, outcome, seed, wc, bc}

def clear_selection(state: Chess/Types/GameState, msg: String) -> Chess/Types/GameState:
  set_selection(state, no_selection(), no_targets(), msg)

def active_controller(state: Chess/Types/GameState) -> Chess/Types/Controller:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      match side:
        case white{}:
          wc
        case black{}:
          bc

def checked_king_pos(state: Chess/Types/GameState) -> Maybe(Chess/Types/Pos):
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      checked_king_pos_flag(board, side, is_in_check(board, side))

def checked_king_pos_flag(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  flag: U32,
) -> Maybe(Chess/Types/Pos):
  match flag:
    case 0:
      (none{} :: Maybe(Chess/Types/Pos))
    case _:
      find_king(board, side)

def apply_move(state: Chess/Types/GameState, mv: Chess/Types/Move) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      legal = move_in_list(mv, legal_moves_for_board_side(board, side))
      apply_move_legal(board, side, selected, targets, status, last_move, outcome, seed, wc, bc, mv, legal)

def apply_move_legal(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  status: String,
  last_move: String,
  outcome: Chess/Types/Outcome,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
  mv: Chess/Types/Move,
  legal: U32,
) -> Chess/Types/GameState:
  apply_move_legal_case(board, side, selected, targets, status, last_move, outcome, seed, wc, bc, mv, legal)

def apply_move_legal_case(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  status: String,
  last_move: String,
  outcome: Chess/Types/Outcome,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
  mv: Chess/Types/Move,
  legal: U32,
) -> Chess/Types/GameState:
  match legal:
    case 0:
      apply_move_illegal(board, side, selected, targets, last_move, outcome, seed, wc, bc)
    case _:
      apply_move_commit(board, side, seed, wc, bc, mv)

def apply_move_illegal(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
  targets: List(Chess/Types/Move),
  last_move: String,
  outcome: Chess/Types/Outcome,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
) -> Chess/Types/GameState:
  game{board, side, selected, targets, "Invalid move.", last_move, outcome, seed, wc, bc}

def apply_move_commit(
  board: List(Maybe(Chess/Types/Piece)),
  side: Chess/Types/Color,
  seed: U32,
  wc: Chess/Types/Controller,
  bc: Chess/Types/Controller,
  mv: Chess/Types/Move,
) -> Chess/Types/GameState:
  board2 = board_after_move(board, mv)
  side2 = other_color(side)
  lm = move_to_string(mv)
  state2 = (game{
    board2,
    side2,
    no_selection(),
    no_targets(),
    "Moved " ++ lm,
    lm,
    playing{},
    seed + 1,
    wc,
    bc,
  } :: Chess/Types/GameState)
  evaluate_outcome(state2)
