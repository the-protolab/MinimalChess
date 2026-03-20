# Minimal Chess app root: pre-match queen shop + match gameplay.

# App events.
type Event {
  square_click{row: U32, col: U32}
  bot_tick{}
  restart{}
  open_queen{}
  queen_prev{}
  queen_next{}
  select_unlock{}
  start{}
  back_menu{}
  nop{}
}

def init_root() -> Chess/Types/RootState:
  inv = Chess/Queens/initial_inventory()
  rules = Chess/Queens/resolve_rules(inv)
  game = Chess/Engine/init_state_with_rules(rules)
  root{menu_screen{}, Chess/Queens/selected_queen(inv), inv, rules, game, "Pick a queen, then press PLAY."}

init : Chess/Types/RootState =
  init_root()

# ----------
# Root events
# ----------

def on_event(evt: Event, state: Chess/Types/RootState) -> Chess/Types/RootState:
  match evt:
    case square_click{row, col}:
      on_square_click_root(state, row, col)
    case bot_tick{}:
      on_bot_tick_root(state)
    case restart{}:
      on_restart_match(state)
    case open_queen{}:
      on_open_queen(state)
    case queen_prev{}:
      on_queen_prev(state)
    case queen_next{}:
      on_queen_next(state)
    case select_unlock{}:
      on_select_unlock(state)
    case start{}:
      on_start_match(state)
    case back_menu{}:
      on_back_menu(state)
    case nop{}:
      state

def on_square_click_root(state: Chess/Types/RootState, row: U32, col: U32) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, cursor, inv, rules, game, menu_status}
        case queen_screen{}:
          root{queen_screen{}, cursor, inv, rules, game, menu_status}
        case match_screen{}:
          game2 = on_square_click_game(rules, game, row, col)
          root{match_screen{}, cursor, inv, rules, game2, menu_status}

def on_bot_tick_root(state: Chess/Types/RootState) -> Chess/Types/RootState:
  # Tick disabled to avoid UI click contention from continuous rerender.
  state

def on_restart_match(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, cursor, inv, rules, game, "Start a match first."}
        case queen_screen{}:
          root{queen_screen{}, cursor, inv, rules, game, "Start a match from the menu."}
        case match_screen{}:
          game2 = Chess/Engine/init_state_with_rules(rules)
          game3 = Chess/Engine/set_status(game2, "Match restarted.")
          root{match_screen{}, cursor, inv, rules, game3, menu_status}

def on_open_queen(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{queen_screen{}, Chess/Queens/selected_queen(inv), inv, rules, game, "Use < and > to browse queens."}
        case queen_screen{}:
          root{queen_screen{}, cursor, inv, rules, game, menu_status}
        case match_screen{}:
          root{match_screen{}, cursor, inv, rules, game, menu_status}

def on_queen_prev(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case queen_screen{}:
          root{queen_screen{}, queen_prev_id(cursor), inv, rules, game, menu_status}
        case scr:
          root{scr, cursor, inv, rules, game, menu_status}

def on_queen_next(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case queen_screen{}:
          root{queen_screen{}, queen_next_id(cursor), inv, rules, game, menu_status}
        case scr:
          root{scr, cursor, inv, rules, game, menu_status}

def on_select_unlock(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case queen_screen{}:
          was_unlocked = Chess/Queens/is_unlocked(inv, cursor)
          inv2 = Chess/Queens/buy(inv, cursor)
          inv3 = Chess/Queens/select(inv2, cursor)
          msg = select_unlock_message(was_unlocked, cursor)
          root{queen_screen{}, cursor, inv3, Chess/Queens/resolve_rules(inv3), game, msg}
        case scr:
          root{scr, cursor, inv, rules, game, menu_status}

def select_unlock_message(was_unlocked: U32, qid: Chess/Types/QueenId) -> String:
  name = Chess/Queens/queen_name(qid)
  select_unlock_message_with_name(was_unlocked, name)

def select_unlock_message_with_name(was_unlocked: U32, name: String) -> String:
  match was_unlocked:
    case 0:
      "Unlocked and selected " ++ name ++ "."
    case _:
      "Selected " ++ name ++ "."

def on_start_match(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          rules2 = Chess/Queens/resolve_rules(inv)
          game2 = Chess/Engine/init_state_with_rules(rules2)
          qid = Chess/Queens/selected_queen(inv)
          qname = Chess/Queens/queen_name(qid)
          game3 = Chess/Engine/set_status(game2, "Match started with " ++ qname ++ ". " ++ active_rules_text(rules2))
          root{match_screen{}, cursor, inv, rules2, game3, menu_status}
        case queen_screen{}:
          root{queen_screen{}, cursor, inv, rules, game, "Tap back, then PLAY from the menu."}
        case match_screen{}:
          root{match_screen{}, cursor, inv, rules, game, menu_status}

def on_back_menu(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, Chess/Queens/selected_queen(inv), inv, rules, game, menu_status}
        case queen_screen{}:
          root{menu_screen{}, Chess/Queens/selected_queen(inv), inv, Chess/Queens/resolve_rules(inv), game, "Pick a queen, then press PLAY."}
        case match_screen{}:
          root{menu_screen{}, Chess/Queens/selected_queen(inv), inv, Chess/Queens/resolve_rules(inv), game, "Back in menu. Pick a queen, then press PLAY."}

def queen_prev_id(qid: Chess/Types/QueenId) -> Chess/Types/QueenId:
  match qid:
    case queen_default{}:
      queen_minus{}
    case queen_plus{}:
      queen_default{}
    case queen_minus{}:
      queen_plus{}

def queen_next_id(qid: Chess/Types/QueenId) -> Chess/Types/QueenId:
  match qid:
    case queen_default{}:
      queen_plus{}
    case queen_plus{}:
      queen_minus{}
    case queen_minus{}:
      queen_default{}

# ----------------
# Match event loop
# ----------------

def on_bot_tick_game(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      on_bot_tick_live(rules, state, Chess/Engine/is_playing(outcome))

def on_bot_tick_live(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  live: U32,
) -> Chess/Types/GameState:
  match live:
    case 0:
      state
    case _:
      ctrl = Chess/Engine/active_controller(state)
      on_bot_tick_ctrl(rules, state, ctrl)

def on_bot_tick_ctrl(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  ctrl: Chess/Types/Controller,
) -> Chess/Types/GameState:
  match ctrl:
    case human{}:
      state
    case bot{}:
      # Multiplayer extension point: keep Engine.apply_move pure; replace local bot/human chooser with remote move provider without changing chess rules.
      mv = Chess/Bot/choose_random_legal_move(rules, state)
      on_bot_tick_move(rules, state, mv)

def on_bot_tick_move(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  mv: Maybe(Chess/Types/Move),
) -> Chess/Types/GameState:
  match mv:
    case none{}:
      Chess/Engine/set_status(state, "No legal bot move.")
    case some{m}:
      Chess/Engine/apply_move(rules, state, m)

def on_square_click_game(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  row: U32,
  col: U32,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      match Chess/Engine/is_playing(outcome):
        case 0:
          Chess/Engine/set_status(state, "Game over.")
        case _:
          ctrl = Chess/Engine/active_controller(state)
          on_square_click_ctrl(rules, state, row, col, ctrl)

def on_square_click_ctrl(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  row: U32,
  col: U32,
  ctrl: Chess/Types/Controller,
) -> Chess/Types/GameState:
  match ctrl:
    case bot{}:
      Chess/Engine/set_status(state, "Bot turn. Please wait.")
    case human{}:
      on_square_click_human(rules, state, row, col)

def on_square_click_human(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  row: U32,
  col: U32,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      clicked = (pos{row, col} :: Chess/Types/Pos)
      cell = Chess/Engine/board_get(board, row, col)
      on_square_click_human_sel(rules, state, clicked, cell, side, selected)

def on_square_click_human_sel(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
) -> Chess/Types/GameState:
  match selected:
    case none{}:
      select_if_own(rules, state, clicked, cell, side)
    case some{sel}:
      on_selected_click(rules, state, sel, clicked, cell, side)

def select_if_own(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/is_piece_of_color(cell, side):
    case 0:
      Chess/Engine/set_status(state, "Select one of your pieces.")
    case _:
      select_piece(rules, state, clicked)

def on_selected_click(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  sel: Chess/Types/Pos,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/pos_eq(sel, clicked):
    case 0:
      on_selected_click_not_same(rules, state, sel, clicked, cell, side)
    case _:
      Chess/Engine/clear_selection(state, "Selection cleared.")

def on_selected_click_not_same(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  sel: Chess/Types/Pos,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/is_piece_of_color(cell, side):
    case 0:
      try_selected_move(rules, state, sel, clicked)
    case _:
      select_piece(rules, state, clicked)

def try_selected_move(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  sel: Chess/Types/Pos,
  clicked: Chess/Types/Pos,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      mv = (move{sel, clicked} :: Chess/Types/Move)
      match Chess/Engine/move_in_list(mv, targets):
        case 0:
          Chess/Engine/set_status(state, "Invalid target for selected piece.")
        case _:
          after_human = Chess/Engine/apply_move(rules, state, mv)
          on_bot_tick_game(rules, after_human)

def select_piece(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
  p: Chess/Types/Pos,
) -> Chess/Types/GameState:
  moves = Chess/Engine/legal_moves_from(rules, state, p)
  msg = select_message(p, Chess/Engine/list_is_empty(Chess/Types/Move, moves))
  Chess/Engine/set_selection(state, some{p}, moves, msg)

def select_message(p: Chess/Types/Pos, no_moves: U32) -> String:
  match no_moves:
    case 0:
      "Selected " ++ Chess/Engine/square_name(p)
    case _:
      "Selected " ++ Chess/Engine/square_name(p) ++ " (no legal moves)"

# ---------
# Rendering
# ---------

def render(state: Chess/Types/RootState) -> HTML(Event):
  <div class="page">
    <style>{text{css}}</style>
    {render_screen(state)}
  </div>

def render_screen(state: Chess/Types/RootState) -> HTML(Event):
  match state:
    case root{screen, cursor, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          <section class="screen_root">{render_menu(inv)}</section>
        case queen_screen{}:
          <article class="screen_root">{render_queen_screen(cursor, inv)}</article>
        case match_screen{}:
          <main class="screen_root">{render_match(rules, game)}</main>

def render_menu(inv: Chess/Types/Inventory) -> HTML(Event):
  qid = Chess/Queens/selected_queen(inv)
  info = queen_wire_name(qid)
  details = queen_passive_text(qid)
  render_menu_view(qid, info, details)

def render_menu_view(
  qid: Chess/Types/QueenId,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame">
    <div class="menu_kicker">{text{"SELECTED QUEEN"}}</div>
    <div class="menu_title">{text{info}}</div>
    <div class="menu_desc">{text{details}}</div>
    <div class="queen_sprite_box">{render_queen_sprite(qid)}</div>
    <button class="btn_primary" on_click={start{}}>{text{"PLAY"}}</button>
    <button class="btn_link" on_click={open_queen{}}>{text{"change queen"}}</button>
  </section>

def render_queen_screen(
  cursor: Chess/Types/QueenId,
  inv: Chess/Types/Inventory,
) -> HTML(Event):
  unlocked = Chess/Queens/is_unlocked(inv, cursor)
  selected = queen_id_eq(Chess/Queens/selected_queen(inv), cursor)
  info = queen_wire_name(cursor)
  details = queen_passive_text(cursor)
  render_queen_screen_view(cursor, unlocked, selected, info, details)

def render_queen_screen_view(
  cursor: Chess/Types/QueenId,
  unlocked: U32,
  selected: U32,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame">
    <div class="menu_kicker">{text{"SELECT QUEEN"}}</div>
    <div class="queen_nav">
      <button class="btn_nav" on_click={queen_prev{}}>{text{"<"}}</button>
      <div class="menu_title">{text{info}}</div>
      <button class="btn_nav" on_click={queen_next{}}>{text{">"}}</button>
    </div>
    <div class="menu_desc">{text{details}}</div>
    <div class="queen_sprite_box">{render_queen_sprite(cursor)}</div>
    {render_select_unlock_button(unlocked, selected)}
    <button class="btn_link" on_click={back_menu{}}>{text{"back"}}</button>
  </section>

def render_select_unlock_button(unlocked: U32, selected: U32) -> HTML(Event):
  render_select_unlock_button_selected(selected, unlocked)

def render_select_unlock_button_selected(selected: U32, unlocked: U32) -> HTML(Event):
  match selected:
    case 0:
      render_select_unlock_button_unlocked(unlocked)
    case _:
      <button class="btn_selected" on_click={nop{}}>{text{"SELECTED"}}</button>

def render_select_unlock_button_unlocked(unlocked: U32) -> HTML(Event):
  match unlocked:
    case 0:
      <button class="btn_primary" on_click={select_unlock{}}>{text{"UNLOCK"}}</button>
    case _:
      <button class="btn_primary" on_click={select_unlock{}}>{text{"SELECT"}}</button>

def render_match(
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
) -> HTML(Event):
  turn_line = match_turn_line(game)
  info_line = match_info_line(game)
  render_match_view(rules, game, turn_line, info_line)

def render_match_view(
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
  turn_line: String,
  info_line: String,
) -> HTML(Event):
  <section class="match_frame">
    <div class="match_top">
      <div class="match_turn">{text{turn_line}}</div>
      <button class="btn_x" on_click={back_menu{}}>{text{"X"}}</button>
    </div>
    <div class="match_info">{text{info_line}}</div>
    <div class="match_grid_wrap">
      <div class="board">{...board_rows(game, rules, state_zero(game))}</div>
    </div>
  </section>

def match_turn_line(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      "Turn: " ++ Chess/Engine/color_name(side)

def match_info_line(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      "Last White: " ++ last_white
      ++ " | Last Black: " ++ last_black
      ++ " | Outcome: " ++ Chess/Engine/outcome_text(outcome)

def queen_wire_name(qid: Chess/Types/QueenId) -> String:
  match qid:
    case queen_default{}:
      "DEFAULT QUEEN"
    case queen_plus{}:
      "QUEEN +"
    case queen_minus{}:
      "QUEEN -"

def render_queen_sprite(qid: Chess/Types/QueenId) -> HTML(Event):
  <img class="queen_sprite" src={queen_sprite_src(qid)} alt={queen_wire_name(qid)}></img>

def queen_sprite_src(qid: Chess/Types/QueenId) -> String:
  match qid:
    case queen_default{}:
      "./assets/chess-pieces/whitequeen.svg"
    case queen_plus{}:
      "./assets/chess-pieces/blackqueen.svg"
    case queen_minus{}:
      "./assets/chess-pieces/whiteking.svg"

def active_rules_text(rules: Chess/Types/RuleSet) -> String:
  match rules:
    case ruleset{player_max, opponent_max}:
      "Pawn first move (you/bot): " ++ U32/show(player_max) ++ "/" ++ U32/show(opponent_max)

def board_rows(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
) -> List(HTML(Event)):
  board_rows_stop(state, rules, row, row === 8)

def board_rows_stop(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
  stop: U32,
) -> List(HTML(Event)):
  match stop:
    case 0:
      (board_row(state, rules, row)<>board_rows(state, rules, row + 1) :: List(HTML(Event)))
    case _:
      ([] :: List(HTML(Event)))

def board_row(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
) -> HTML(Event):
  <div class="board_row">{...board_cells(state, rules, row, state_zero(state))}</div>

def board_cells(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
  col: U32,
) -> List(HTML(Event)):
  board_cells_stop(state, rules, row, col, col === 8)

def board_cells_stop(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
  col: U32,
  stop: U32,
) -> List(HTML(Event)):
  match stop:
    case 0:
      (render_cell(state, rules, row, col)<>board_cells(state, rules, row, col + 1) :: List(HTML(Event)))
    case _:
      ([] :: List(HTML(Event)))

def render_cell(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
  col: U32,
) -> HTML(Event):
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      cell = Chess/Engine/board_get(board, row, col)
      sel = is_selected(state, row, col)
      trg = is_target(state, row, col)
      chk = is_checked_king(state, rules, row, col)
      dark = Chess/Engine/square_is_dark(row, col)
      render_cell_dark(dark, row, col, cell, sel, trg, chk)

def render_cell_dark(
  dark: U32,
  row: U32,
  col: U32,
  cell: Maybe(Chess/Types/Piece),
  selected: U32,
  target: U32,
  checked: U32,
) -> HTML(Event):
  match dark:
    case 0:
      <button class="cell_light" on_click={square_click{row, col}}>{render_cell_inner(cell, selected, target, checked)}</button>
    case _:
      <button class="cell_dark" on_click={square_click{row, col}}>{render_cell_inner(cell, selected, target, checked)}</button>

def render_cell_inner(
  cell: Maybe(Chess/Types/Piece),
  selected: U32,
  target: U32,
  checked: U32,
) -> HTML(Event):
  <div class="cell_inner">
    {render_selected_overlay(selected)}
    {render_checked_overlay(checked)}
    {render_piece(cell)}
    {render_target_overlay(cell, target)}
  </div>

def render_selected_overlay(selected: U32) -> HTML(Event):
  match selected:
    case 0:
      <span class="overlay_none">{text{""}}</span>
    case _:
      <span class="cell_selected_ring">{text{""}}</span>

def render_checked_overlay(checked: U32) -> HTML(Event):
  match checked:
    case 0:
      <span class="overlay_none">{text{""}}</span>
    case _:
      <span class="cell_check_badge">{text{"!"}}</span>

def render_target_overlay(cell: Maybe(Chess/Types/Piece), target: U32) -> HTML(Event):
  empty = Chess/Engine/cell_is_empty(cell)
  render_target_overlay_empty(empty, target)

def render_target_overlay_empty(empty: U32, target: U32) -> HTML(Event):
  match empty:
    case 0:
      <span class="overlay_none">{text{""}}</span>
    case _:
      render_target_overlay_target(target)

def render_target_overlay_target(target: U32) -> HTML(Event):
  match target:
    case 0:
      <span class="overlay_none">{text{""}}</span>
    case _:
      <span class="cell_target_dot">{text{"•"}}</span>

def render_piece(cell: Maybe(Chess/Types/Piece)) -> HTML(Event):
  match cell:
    case none{}:
      <span class="piece_empty">{text{""}}</span>
    case some{piece{color, kind}}:
      <img class="piece_img" src={piece_src_kind(color, kind)} alt={piece_alt_kind(color, kind)}></img>

def piece_src_kind(color: Chess/Types/Color, kind: Chess/Types/PieceKind) -> String:
  match color kind:
    case white{} king{}:
      "./assets/chess-pieces/whiteking.svg"
    case white{} queen{}:
      "./assets/chess-pieces/whitequeen.svg"
    case white{} rook{}:
      "./assets/chess-pieces/whiterook.svg"
    case white{} bishop{}:
      "./assets/chess-pieces/whitebishop.svg"
    case white{} knight{}:
      "./assets/chess-pieces/whiteknight.svg"
    case white{} pawn{}:
      "./assets/chess-pieces/whitepawn.svg"
    case black{} king{}:
      "./assets/chess-pieces/blackking.svg"
    case black{} queen{}:
      "./assets/chess-pieces/blackqueen.svg"
    case black{} rook{}:
      "./assets/chess-pieces/blackrook.svg"
    case black{} bishop{}:
      "./assets/chess-pieces/blackbishop.svg"
    case black{} knight{}:
      "./assets/chess-pieces/blackknight.svg"
    case black{} pawn{}:
      "./assets/chess-pieces/blackpawn.svg"

def piece_alt_kind(color: Chess/Types/Color, kind: Chess/Types/PieceKind) -> String:
  match color kind:
    case white{} king{}:
      "White king"
    case white{} queen{}:
      "White queen"
    case white{} rook{}:
      "White rook"
    case white{} bishop{}:
      "White bishop"
    case white{} knight{}:
      "White knight"
    case white{} pawn{}:
      "White pawn"
    case black{} king{}:
      "Black king"
    case black{} queen{}:
      "Black queen"
    case black{} rook{}:
      "Black rook"
    case black{} bishop{}:
      "Black bishop"
    case black{} knight{}:
      "Black knight"
    case black{} pawn{}:
      "Black pawn"

def state_zero(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      seed - seed

def is_selected(state: Chess/Types/GameState, row: U32, col: U32) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      match selected:
        case none{}:
          0
        case some{pos{sr, sc}}:
          (sr === row) & (sc === col)

def is_target(state: Chess/Types/GameState, row: U32, col: U32) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      Chess/Engine/move_targets_pos(targets, row, col)

def is_checked_king(
  state: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
  row: U32,
  col: U32,
) -> U32:
  is_checked_king_kp(row, col, Chess/Engine/checked_king_pos(rules, state))

def is_checked_king_kp(row: U32, col: U32, kp: Maybe(Chess/Types/Pos)) -> U32:
  match kp:
    case none{}:
      0
    case some{pos{kr, kc}}:
      (kr === row) & (kc === col)

def queen_id_eq(a: Chess/Types/QueenId, b: Chess/Types/QueenId) -> U32:
  match a b:
    case queen_default{} queen_default{}:
      1
    case queen_plus{} queen_plus{}:
      1
    case queen_minus{} queen_minus{}:
      1
    case _ _:
      0

def queen_passive_text(qid: Chess/Types/QueenId) -> String:
  match qid:
    case queen_default{}:
      "Pawn first move: up to 2 squares."
    case queen_plus{}:
      "Pawn first move: up to 3 squares."
    case queen_minus{}:
      "Pawn first move: only 1 square."

css_a : String = "
html{overflow-y:scroll}
*{box-sizing:border-box;margin:0}
body{min-height:100vh;overflow-x:hidden;padding:16px;background:#efefef;color:#111;font-family:Trebuchet MS,sans-serif}
.page{min-height:calc(100vh - 32px);display:grid;place-items:center}
.screen_root{width:100%;display:grid;place-items:center}
.menu_frame,.match_frame{width:min(92vw,560px);border:3px solid #111;padding:22px;display:grid;gap:14px;background:transparent}
.menu_kicker{text-align:center;font-size:clamp(22px,4vw,40px);font-weight:800;letter-spacing:.06em}
.menu_title{text-align:center;font-size:clamp(36px,7vw,64px);line-height:1;font-weight:900}
.menu_desc{text-align:center;font-size:clamp(18px,2.8vw,30px);font-style:italic;min-height:40px;max-height:78px;overflow:hidden}
"

css_b : String = "
.queen_nav{display:grid;grid-template-columns:52px 1fr 52px;align-items:center;gap:8px}
.btn_nav{width:52px;height:52px;border:2px solid #111;background:#fff;font-size:30px;line-height:1;cursor:pointer}
.queen_sprite_box{width:min(70vw,250px);height:min(70vw,250px);margin:0 auto;border:3px solid #111;display:grid;place-items:center;background:#f8f8f8}
.queen_sprite{width:84%;height:84%;object-fit:contain;pointer-events:none}
.btn_primary,.btn_selected{width:min(100%,420px);height:64px;margin:0 auto;border:3px solid #111;background:#fff;font-size:clamp(30px,7vw,50px);font-weight:900;cursor:pointer}
.btn_selected{color:#4c4c4c;cursor:default}
.btn_link{border:none;background:transparent;width:fit-content;margin:0 auto;text-decoration:underline;font-size:clamp(24px,6vw,44px);color:#111;cursor:pointer}
"

css_c : String = "
.match_top{display:flex;justify-content:space-between;align-items:flex-start;gap:10px}
.match_turn{font-size:clamp(26px,4.5vw,46px);font-weight:800;line-height:1}
.btn_x{border:none;background:transparent;color:#111;font-size:clamp(34px,5.5vw,54px);font-weight:900;line-height:1;cursor:pointer;padding:0}
.match_info{min-height:62px;max-height:62px;overflow:hidden;font-size:clamp(18px,2.8vw,30px);line-height:1.18}
.match_grid_wrap{display:grid;justify-items:center}
.board{display:inline-flex;flex-direction:column;gap:2px;width:fit-content}
.board_row{display:flex;gap:2px}
.cell_light,.cell_dark{width:clamp(40px,8vw,64px);height:clamp(40px,8vw,64px);border:none;cursor:pointer;display:grid;place-items:center;position:relative;overflow:hidden;padding:0}
.cell_light{background:#efe5d3}
.cell_dark{background:#bba27f}
"

css_d : String = "
.cell_inner{width:100%;height:100%;display:grid;place-items:center;position:relative}
.piece_empty,.overlay_none{display:none}
.piece_img{width:84%;height:84%;object-fit:contain;pointer-events:none;filter:drop-shadow(0 1px 1px rgba(0,0,0,.25))}
.cell_target_dot{position:absolute;inset:0;display:grid;place-items:center;font-size:clamp(20px,4vw,30px);color:#31586f;line-height:1;pointer-events:none}
.cell_selected_ring{position:absolute;inset:3px;border:3px solid #1f6fa5;border-radius:8px;pointer-events:none}
.cell_check_badge{position:absolute;top:2px;right:2px;min-width:16px;height:16px;border-radius:999px;background:#b42318;color:#fff;font-size:11px;font-weight:800;display:flex;align-items:center;justify-content:center;pointer-events:none}
"

css : String = css_a ++ css_b ++ css_c ++ css_d

main : App = app{Chess/Types/RootState, Event, init, render, on_event}
