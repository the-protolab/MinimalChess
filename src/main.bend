# Minimal Chess app root: pre-match queen shop + match gameplay.

# App events.
type Event {
  square_click{row: U32, col: U32}
  bot_tick{}
  restart{}
  open_shop{}
  close_shop{}
  buy{qid: Chess/Types/QueenId}
  equip{qid: Chess/Types/QueenId}
  start{}
  back{}
  nop{}
}

def init_root() -> Chess/Types/RootState:
  inv = Chess/Queens/initial_inventory()
  rules = Chess/Queens/resolve_rules(inv)
  game = Chess/Engine/init_state_with_rules(rules)
  root{menu_screen{}, 0, inv, rules, game, "Pick a queen, then start a match."}

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
    case open_shop{}:
      on_open_shop(state)
    case close_shop{}:
      on_close_shop(state)
    case buy{qid}:
      on_buy_queen(state, qid)
    case equip{qid}:
      on_select_queen(state, qid)
    case start{}:
      on_start_match(state)
    case back{}:
      on_back_to_menu(state)
    case nop{}:
      state

def on_square_click_root(state: Chess/Types/RootState, row: U32, col: U32) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, popup, inv, rules, game, "Press START MATCH to play."}
        case match_screen{}:
          game2 = on_square_click_game(rules, game, row, col)
          root{match_screen{}, popup, inv, rules, game2, menu_status}

def on_bot_tick_root(state: Chess/Types/RootState) -> Chess/Types/RootState:
  # Tick disabled to avoid UI click contention from continuous rerender.
  state

def on_restart_match(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, popup, inv, rules, game, "Start a match first."}
        case match_screen{}:
          game2 = Chess/Engine/init_state_with_rules(rules)
          game3 = Chess/Engine/set_status(game2, "Match restarted.")
          root{match_screen{}, popup, inv, rules, game3, menu_status}

def on_open_shop(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, 1, inv, rules, game, menu_status}
        case match_screen{}:
          game2 = Chess/Engine/set_status(game, "Back to menu to change queen.")
          root{match_screen{}, popup, inv, rules, game2, menu_status}

def on_close_shop(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, 0, inv, rules, game, menu_status}
        case match_screen{}:
          root{match_screen{}, popup, inv, rules, game, menu_status}

def on_buy_queen(state: Chess/Types/RootState, qid: Chess/Types/QueenId) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          was = Chess/Queens/is_unlocked(inv, qid)
          inv2 = Chess/Queens/buy(inv, qid)
          msg = buy_menu_message(was, Chess/Queens/queen_name(qid))
          root{menu_screen{}, popup, inv2, Chess/Queens/resolve_rules(inv2), game, msg}
        case match_screen{}:
          game2 = Chess/Engine/set_status(game, "Queen shop is only available before match.")
          root{match_screen{}, popup, inv, rules, game2, menu_status}

def buy_menu_message(was_unlocked: U32, name: String) -> String:
  match was_unlocked:
    case 0:
      "Unlocked " ++ name ++ "."
    case _:
      name ++ " is already unlocked."

def on_select_queen(state: Chess/Types/RootState, qid: Chess/Types/QueenId) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          unlocked = Chess/Queens/is_unlocked(inv, qid)
          inv2 = Chess/Queens/select(inv, qid)
          msg = select_menu_message(unlocked, qid)
          root{menu_screen{}, popup, inv2, Chess/Queens/resolve_rules(inv2), game, msg}
        case match_screen{}:
          game2 = Chess/Engine/set_status(game, "Queen can only be changed before match.")
          root{match_screen{}, popup, inv, rules, game2, menu_status}

def select_menu_message(unlocked: U32, qid: Chess/Types/QueenId) -> String:
  select_menu_message_name(unlocked, Chess/Queens/queen_name(qid))

def select_menu_message_name(unlocked: U32, name: String) -> String:
  match unlocked:
    case 0:
      "Buy " ++ name ++ " first."
    case _:
      "Selected " ++ name ++ "."

def on_start_match(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          rules2 = Chess/Queens/resolve_rules(inv)
          game2 = Chess/Engine/init_state_with_rules(rules2)
          qid = Chess/Queens/selected_queen(inv)
          qname = Chess/Queens/queen_name(qid)
          game3 = Chess/Engine/set_status(game2, "Match started with " ++ qname ++ ".")
          root{match_screen{}, 0, inv, rules2, game3, menu_status}
        case match_screen{}:
          root{match_screen{}, popup, inv, rules, game, menu_status}

def on_back_to_menu(state: Chess/Types/RootState) -> Chess/Types/RootState:
  match state:
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          root{menu_screen{}, popup, inv, rules, game, menu_status}
        case match_screen{}:
          root{menu_screen{}, 0, inv, Chess/Queens/resolve_rules(inv), game, "Back in menu. Change queen and start a match."}

# ----------------
# Match event loop
# ----------------

def on_bot_tick_game(
  rules: Chess/Types/RuleSet,
  state: Chess/Types/GameState,
) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
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
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      match Chess/Engine/is_playing(outcome):
        case 0:
          Chess/Engine/set_status(state, "Game over. Press Restart to play again.")
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
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
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
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
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
    case root{screen, popup, inv, rules, game, menu_status}:
      match screen:
        case menu_screen{}:
          render_menu(inv, popup, menu_status)
        case match_screen{}:
          render_match(inv, rules, game)

def render_menu(
  inv: Chess/Types/Inventory,
  popup: U32,
  menu_status: String,
) -> HTML(Event):
  qid = Chess/Queens/selected_queen(inv)
  qname = Chess/Queens/queen_name(qid)
  info = "Selected Queen: " ++ qname ++ " | " ++ queen_passive_text(qid)
  render_menu_popup(popup, info, menu_status, inv)

def render_menu_popup(
  popup: U32,
  info: String,
  menu_status: String,
  inv: Chess/Types/Inventory,
) -> HTML(Event):
  match popup:
    case 0:
      render_menu_closed(info, menu_status)
    case _:
      render_menu_open(info, menu_status, inv)

def render_menu_closed(info: String, menu_status: String) -> HTML(Event):
  <section class="shell_menu">
    <h1 class="title">Minimal Chess</h1>
    <div class="sub">Pre-match queen shop</div>
    <div class="status_menu">{text{info}}</div>
    <div><button class="secondary" on_click={open_shop{}}>{text{"CHANGE QUEEN"}}</button></div>
    <div><button class="restart" on_click={start{}}>{text{"START MATCH"}}</button></div>
    <div class="status_menu">{text{menu_status}}</div>
  </section>

def render_menu_open(
  info: String,
  menu_status: String,
  inv: Chess/Types/Inventory,
) -> HTML(Event):
  <section class="shell_menu">
    <h1 class="title">Minimal Chess</h1>
    <div class="sub">Pre-match queen shop</div>
    <div class="status_menu">{text{info}}</div>
    <div><button class="secondary" on_click={close_shop{}}>{text{"CLOSE SHOP"}}</button></div>
    <div><button class="restart" on_click={start{}}>{text{"START MATCH"}}</button></div>
    <div class="status_menu">{text{menu_status}}</div>
    <section class="shop">
      {render_shop_card(inv, queen_default{})}
      {render_shop_card(inv, queen_plus{})}
      {render_shop_card(inv, queen_minus{})}
    </section>
  </section>

def render_shop_card(inv: Chess/Types/Inventory, qid: Chess/Types/QueenId) -> HTML(Event):
  unlocked = Chess/Queens/is_unlocked(inv, qid)
  selected = queen_id_eq(Chess/Queens/selected_queen(inv), qid)
  label = Chess/Queens/queen_name(qid) ++ " - " ++ queen_passive_text(qid)
  render_shop_card_selected(selected, qid, unlocked, label)

def render_shop_card_selected(
  selected: U32,
  qid: Chess/Types/QueenId,
  unlocked: U32,
  label: String,
) -> HTML(Event):
  match selected:
    case 0:
      render_shop_card_unlocked(qid, unlocked, label)
    case _:
      <div class="shop_row">
        <div>{text{label}}</div>
        <button class="qbtn_selected" on_click={nop{}}>{text{"Selected"}}</button>
      </div>

def render_shop_card_unlocked(qid: Chess/Types/QueenId, unlocked: U32, label: String) -> HTML(Event):
  match unlocked:
    case 0:
      <div class="shop_row">
        <div>{text{label}}</div>
        <button class="qbtn_buy" on_click={buy{qid}}>{text{"Buy"}}</button>
      </div>
    case _:
      <div class="shop_row">
        <div>{text{label}}</div>
        <button class="qbtn_select" on_click={equip{qid}}>{text{"Select"}}</button>
      </div>

def render_match(
  inv: Chess/Types/Inventory,
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
) -> HTML(Event):
  <div>
    <section class="shell">
      <h1 class="title">Minimal Chess</h1>
      <div class="status">{text{game_status_line(game)}}</div>
      <div><button class="secondary" on_click={back{}}>{text{"Back to Menu"}}</button></div>
      <div><button class="restart" on_click={restart{}}>{text{"Restart Match"}}</button></div>
    </section>
    <section class="shell">
      <div class="board">{...board_rows(game, rules, state_zero(game))}</div>
    </section>
  </div>

def game_status_line(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      "Turn: " ++ Chess/Engine/color_name(side) ++ " | Outcome: " ++ Chess/Engine/outcome_text(outcome) ++ " | Last: " ++ last_move ++ " | " ++ status

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
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      cell = Chess/Engine/board_get(board, row, col)
      label = cell_label(cell, is_selected(state, row, col), is_target(state, row, col), is_checked_king(state, rules, row, col))
      dark = Chess/Engine/square_is_dark(row, col)
      render_cell_dark(dark, row, col, label)

def render_cell_dark(dark: U32, row: U32, col: U32, label: String) -> HTML(Event):
  match dark:
    case 0:
      <button class="cell_light" on_click={square_click{row, col}}>{text{label}}</button>
    case _:
      <button class="cell_dark" on_click={square_click{row, col}}>{text{label}}</button>

def cell_label(
  cell: Maybe(Chess/Types/Piece),
  selected: U32,
  target: U32,
  checked: U32,
) -> String:
  piece = Chess/Engine/piece_symbol(cell)
  base = target_label(piece, cell, target)
  base = mark_checked(base, checked)
  mark_selected(base, selected)

def target_label(piece: String, cell: Maybe(Chess/Types/Piece), target: U32) -> String:
  match target:
    case 0:
      piece
    case _:
      match Chess/Engine/cell_is_empty(cell):
        case 0:
          piece
        case _:
          "•"

def mark_checked(base: String, checked: U32) -> String:
  match checked:
    case 0:
      base
    case _:
      "!" ++ base

def mark_selected(base: String, selected: U32) -> String:
  match selected:
    case 0:
      base
    case _:
      "[" ++ base ++ "]"

def state_zero(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      seed - seed

def is_selected(state: Chess/Types/GameState, row: U32, col: U32) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      match selected:
        case none{}:
          0
        case some{pos{sr, sc}}:
          (sr === row) & (sc === col)

def is_target(state: Chess/Types/GameState, row: U32, col: U32) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
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

css : String = "
  :root {
    --cell-light:#f0d9b5;
    --cell-dark:#b58863;
    --cell-size:clamp(44px,8vw,72px);
    --cell-gap:2px;
    --paper:#fffaf0;
    --ink:#231b14;
    --accent:#355070;
  }
  * { box-sizing:border-box; margin:0; }
  body { min-height:100vh; background:linear-gradient(180deg,#ffe8cc,#f3ead9); color:var(--ink); font-family:Trebuchet MS, sans-serif; padding:12px; }
  .page { display:flex; justify-content:center; }
  .shell, .shell_menu { width:min(980px,100%); display:grid; gap:10px; background:var(--paper); border:2px solid #d7c19b; border-radius:16px; padding:12px; }
  .shell_menu { width:min(760px,100%); }
  .title { font-size:clamp(24px,4vw,34px); line-height:1; }
  .sub { font-size:14px; color:#6f5a43; }
  .status, .status_menu { background:#fff2cf; border:1px solid #e4cd94; border-radius:8px; padding:8px; font-size:13px; }
  .board { width:fit-content; display:inline-flex; flex-direction:column; gap:var(--cell-gap); background:#3f2d21; padding:4px; border-radius:10px; border:2px solid #63462f; }
  .board_row { display:flex; gap:var(--cell-gap); }
  .cell_light, .cell_dark { width:var(--cell-size); height:var(--cell-size); border:none; cursor:pointer; font-size:clamp(20px,4vw,30px); display:grid; place-items:center; }
  .cell_light { background:var(--cell-light); }
  .cell_dark { background:var(--cell-dark); }
  .shop { background:#fff4df; border:1px solid #ddc7a1; border-radius:10px; padding:8px; display:grid; gap:8px; }
  .shop_row { background:#fff8ed; border:1px solid #ddc7a1; border-radius:8px; padding:8px; display:grid; gap:6px; }
  .restart, .secondary, .qbtn_buy, .qbtn_select, .qbtn_selected { border:none; border-radius:10px; font-weight:700; padding:10px 14px; cursor:pointer; }
  .restart { background:var(--accent); color:#fff; }
  .secondary { background:#d8e3ff; color:#263859; }
  .qbtn_buy { background:#6c5b4a; color:#fff; }
  .qbtn_select { background:#375a7f; color:#fff; }
  .qbtn_selected { background:#2e7d5b; color:#fff; }
"

main : App = app{Chess/Types/RootState, Event, init, render, on_event}
