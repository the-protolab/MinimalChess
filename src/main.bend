# Minimal Chess app: human (white) vs random bot (black).

# App events.
type Event {
  square_click{row: U32, col: U32}
  bot_tick{}
  restart{}
  nop{}
}

init : Chess/Types/GameState =
  Chess/Engine/init_state

# ----------
# Event loop
# ----------

def on_event(evt: Event, state: Chess/Types/GameState) -> Chess/Types/GameState:
  match evt:
    case square_click{row, col}:
      on_square_click(state, row, col)
    case bot_tick{}:
      on_bot_tick(state)
    case restart{}:
      init
    case nop{}:
      state

def on_bot_tick(state: Chess/Types/GameState) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      on_bot_tick_live(state, Chess/Engine/is_playing(outcome))

def on_bot_tick_live(state: Chess/Types/GameState, live: U32) -> Chess/Types/GameState:
  match live:
    case 0:
      state
    case _:
      ctrl = Chess/Engine/active_controller(state)
      on_bot_tick_ctrl(state, ctrl)

def on_bot_tick_ctrl(state: Chess/Types/GameState, ctrl: Chess/Types/Controller) -> Chess/Types/GameState:
  match ctrl:
    case human{}:
      state
    case bot{}:
      # Multiplayer extension point: keep Engine.apply_move pure; replace local bot/human chooser with remote move provider without changing chess rules.
      mv = Chess/Bot/choose_random_legal_move(state)
      on_bot_tick_move(state, mv)

def on_bot_tick_move(state: Chess/Types/GameState, mv: Maybe(Chess/Types/Move)) -> Chess/Types/GameState:
  match mv:
    case none{}:
      Chess/Engine/set_status(state, "No legal bot move.")
    case some{m}:
      Chess/Engine/apply_move(state, m)

def on_square_click(state: Chess/Types/GameState, row: U32, col: U32) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      match Chess/Engine/is_playing(outcome):
        case 0:
          Chess/Engine/set_status(state, "Game over. Press Restart to play again.")
        case _:
          ctrl = Chess/Engine/active_controller(state)
          on_square_click_ctrl(state, row, col, ctrl)

def on_square_click_ctrl(
  state: Chess/Types/GameState,
  row: U32,
  col: U32,
  ctrl: Chess/Types/Controller,
) -> Chess/Types/GameState:
  match ctrl:
    case bot{}:
      Chess/Engine/set_status(state, "Bot turn. Please wait.")
    case human{}:
      on_square_click_human(state, row, col)

def on_square_click_human(state: Chess/Types/GameState, row: U32, col: U32) -> Chess/Types/GameState:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      clicked = (pos{row, col} :: Chess/Types/Pos)
      cell = Chess/Engine/board_get(board, row, col)
      on_square_click_human_sel(state, clicked, cell, side, selected)

def on_square_click_human_sel(
  state: Chess/Types/GameState,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
  selected: Maybe(Chess/Types/Pos),
) -> Chess/Types/GameState:
  match selected:
    case none{}:
      select_if_own(state, clicked, cell, side)
    case some{sel}:
      on_selected_click(state, sel, clicked, cell, side)

def select_if_own(
  state: Chess/Types/GameState,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/is_piece_of_color(cell, side):
    case 0:
      Chess/Engine/set_status(state, "Select one of your pieces.")
    case _:
      select_piece(state, clicked)

def on_selected_click(
  state: Chess/Types/GameState,
  sel: Chess/Types/Pos,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/pos_eq(sel, clicked):
    case 0:
      on_selected_click_not_same(state, sel, clicked, cell, side)
    case _:
      Chess/Engine/clear_selection(state, "Selection cleared.")

def on_selected_click_not_same(
  state: Chess/Types/GameState,
  sel: Chess/Types/Pos,
  clicked: Chess/Types/Pos,
  cell: Maybe(Chess/Types/Piece),
  side: Chess/Types/Color,
) -> Chess/Types/GameState:
  match Chess/Engine/is_piece_of_color(cell, side):
    case 0:
      try_selected_move(state, sel, clicked)
    case _:
      select_piece(state, clicked)

def try_selected_move(
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
          Chess/Engine/apply_move(state, mv)

def select_piece(state: Chess/Types/GameState, p: Chess/Types/Pos) -> Chess/Types/GameState:
  moves = Chess/Engine/legal_moves_from(state, p)
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

def render(state: Chess/Types/GameState) -> HTML(Event):
  z = state_zero(state);
  <div class="page" every_ms={260, bot_tick{}}>
    <style>{text{css}}</style>
    <section class="shell">
      <header class="head">
        <h1 class="title">Minimal Chess</h1>
        <div class="sub">Human (White) vs Random Bot (Black)</div>
      </header>

      <div class="layout">
        <div class="board">{...board_rows(state, z)}</div>
        {render_panel(state)}
      </div>

      <footer class="foot">
        <button class="restart" on_click={restart{}}>{text{"Restart"}}</button>
      </footer>
    </section>
  </div>

def board_rows(state: Chess/Types/GameState, row: U32) -> List(HTML(Event)):
  board_rows_stop(state, row, row === 8)

def board_rows_stop(state: Chess/Types/GameState, row: U32, stop: U32) -> List(HTML(Event)):
  match stop:
    case 0:
      (board_row(state, row)<>board_rows(state, row + 1) :: List(HTML(Event)))
    case _:
      ([] :: List(HTML(Event)))

def board_row(state: Chess/Types/GameState, row: U32) -> HTML(Event):
  z = state_zero(state);
  <div class="board-row">{...board_cells(state, row, z)}</div>

def board_cells(state: Chess/Types/GameState, row: U32, col: U32) -> List(HTML(Event)):
  board_cells_stop(state, row, col, col === 8)

def board_cells_stop(state: Chess/Types/GameState, row: U32, col: U32, stop: U32) -> List(HTML(Event)):
  match stop:
    case 0:
      (render_cell(state, col, row)<>board_cells(state, row, col + 1) :: List(HTML(Event)))
    case _:
      ([] :: List(HTML(Event)))

def state_zero(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      seed - seed

def render_panel(state: Chess/Types/GameState) -> HTML(Event):
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      <aside class="panel">
        <div class="panel-row"><span class="k">Turn</span><span class="v">{text{Chess/Engine/color_name(side)}}</span></div>
        <div class="panel-row"><span class="k">Outcome</span><span class="v">{text{Chess/Engine/outcome_text(outcome)}}</span></div>
        <div class="panel-row"><span class="k">Last Move</span><span class="v">{text{last_move}}</span></div>
        <div class="status">{text{status}}</div>
      </aside>

def render_cell(state: Chess/Types/GameState, col: U32, row: U32) -> HTML(Event):
  match state:
    case game{board, side, selected, targets, status, last_move, outcome, seed, wc, bc}:
      cell = Chess/Engine/board_get(board, row, col)
      cls = cell_class(state, row, col);
      <button class={cls} on_click={square_click{row, col}}>
        <span class="piece">{text{Chess/Engine/piece_symbol(cell)}}</span>
      </button>

def cell_class(state: Chess/Types/GameState, row: U32, col: U32) -> String:
  dark = Chess/Engine/square_is_dark(row, col)
  base = base_class(dark)
  base = add_class(base, is_selected(state, row, col), "selected")
  base = add_class(base, is_target(state, row, col), "target")
  add_class(base, is_checked_king(state, row, col), "checked")

def base_class(dark: U32) -> String:
  match dark:
    case 0:
      "cell light"
    case _:
      "cell dark"

def add_class(base: String, on: U32, cls: String) -> String:
  match on:
    case 0:
      base
    case _:
      base ++ " " ++ cls

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

def is_checked_king(state: Chess/Types/GameState, row: U32, col: U32) -> U32:
  is_checked_king_kp(row, col, Chess/Engine/checked_king_pos(state))

def is_checked_king_kp(row: U32, col: U32, kp: Maybe(Chess/Types/Pos)) -> U32:
  match kp:
    case none{}:
      0
    case some{pos{kr, kc}}:
      (kr === row) & (kc === col)

css : String = "
  :root {
    --cell-light:#f0d9b5;
    --cell-dark:#b58863;
    --cell-size:clamp(44px,8vw,76px);
    --cell-gap:2px;
    --sel-ring:#2a9d8f;
    --target-dot:#1d3557;
    --check-ring:#c1121f;
    --paper:#fffaf0;
    --panel:#fff4df;
    --ink:#231b14;
    --accent:#355070;
  }
  * { box-sizing:border-box; margin:0; }
  body { min-height:100vh; background:linear-gradient(180deg,#ffe8cc,#f3ead9); color:var(--ink); font-family:Trebuchet MS, sans-serif; padding:14px; }
  .page { display:flex; justify-content:center; }
  .shell { width:min(980px,100%); display:grid; gap:12px; background:var(--paper); border:2px solid #d7c19b; border-radius:18px; padding:14px; }
  .head { display:grid; gap:4px; }
  .title { font-size:clamp(24px,4vw,36px); line-height:1; }
  .sub { font-size:14px; color:#6f5a43; }
  .layout { display:grid; gap:12px; grid-template-columns:auto minmax(220px,300px); align-items:start; }
  .board { width:fit-content; display:inline-flex; flex-direction:column; gap:var(--cell-gap); background:#3f2d21; padding:4px; border-radius:10px; border:2px solid #63462f; }
  .board-row { display:flex; gap:var(--cell-gap); }
  .cell { width:var(--cell-size); height:var(--cell-size); border:none; position:relative; cursor:pointer; display:grid; place-items:center; font-size:clamp(24px,5vw,42px); }
  .cell.light { background:var(--cell-light); }
  .cell.dark { background:var(--cell-dark); }
  .cell.selected { outline:4px solid var(--sel-ring); outline-offset:-4px; }
  .cell.target::after { content:''; width:14px; height:14px; border-radius:999px; background:var(--target-dot); opacity:.8; position:absolute; }
  .cell.checked { outline:4px solid var(--check-ring); outline-offset:-4px; }
  .panel { background:var(--panel); border:2px solid #ddc7a1; border-radius:12px; padding:10px; display:grid; gap:8px; }
  .panel-row { display:flex; justify-content:space-between; gap:10px; font-size:14px; }
  .k { color:#7a5f44; }
  .v { font-weight:700; text-align:right; }
  .status { background:#fff2cf; border:1px solid #e4cd94; border-radius:8px; padding:8px; font-size:13px; min-height:54px; }
  .foot { display:flex; justify-content:flex-end; }
  .restart { border:none; border-radius:10px; background:var(--accent); color:#fff; font-weight:700; padding:10px 14px; cursor:pointer; }
  @media (max-width:860px) {
    .layout { grid-template-columns:1fr; }
    .board { margin:0 auto; }
    .foot { justify-content:center; }
  }
"

main : App = app{Chess/Types/GameState, Event, init, render, on_event}
