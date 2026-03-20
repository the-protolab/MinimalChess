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
          inv2 = Chess/Queens/select(inv, cursor)
          msg = select_only_message(queen_id_eq(Chess/Queens/selected_queen(inv), cursor), cursor)
          root{queen_screen{}, cursor, inv2, Chess/Queens/resolve_rules(inv2), game, msg}
        case scr:
          root{scr, cursor, inv, rules, game, menu_status}

def select_only_message(already_selected: U32, qid: Chess/Types/QueenId) -> String:
  match already_selected:
    case 0:
      "Selected " ++ Chess/Queens/queen_name(qid) ++ "."
    case _:
      Chess/Queens/queen_name(qid) ++ " already selected."

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
      <div class="screen_stack">
        {render_menu(inv, screen)}
        {render_queen_screen(cursor, inv, screen)}
        {render_match(rules, game, screen)}
      </div>

def render_menu(inv: Chess/Types/Inventory, screen: Chess/Types/Screen) -> HTML(Event):
  qid = Chess/Queens/selected_queen(inv)
  info = queen_wire_name(qid)
  details = queen_passive_text(qid)
  match is_menu_screen(screen):
    case 0:
      render_menu_view_hidden(qid, info, details)
    case _:
      render_menu_view_visible(qid, info, details)

def render_menu_title_row(info: String) -> HTML(Event):
  <div class="queen_nav">
    <span class="nav_spacer">{text{""}}</span>
    <div class="menu_title">{text{info}}</div>
    <span class="nav_spacer">{text{""}}</span>
  </div>

def render_queen_stage_nav(cursor: Chess/Types/QueenId) -> HTML(Event):
  <div class="queen_stage_nav">
    <button class="btn_nav" on_click={queen_prev{}}>{text{"<"}}</button>
    <div class="queen_sprite_box">{render_queen_sprite(cursor)}</div>
    <button class="btn_nav" on_click={queen_next{}}>{text{">"}}</button>
  </div>

def render_passive_block(details: String) -> HTML(Event):
  <div class="passive_block">
    <div class="passive_label">{text{"PASSIVE"}}</div>
    <div class="passive_text">{text{details}}</div>
  </div>

def render_menu_actions() -> HTML(Event):
  <div class="menu_actions">
    <button class="btn_primary btn_play" on_click={start{}}>{text{"PLAY"}}</button>
    <button class="btn_link btn_change_queen" on_click={open_queen{}}>{text{"change queen"}}</button>
  </div>

def render_queen_actions(selected: U32) -> HTML(Event):
  <div class="queen_actions">
    {render_select_button(selected)}
    <button class="btn_link btn_change_queen" on_click={back_menu{}}>{text{"back"}}</button>
  </div>

def render_menu_view_hidden(
  qid: Chess/Types/QueenId,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame menu_frame_menu screen_hidden">
    <div class="menu_kicker">{text{"SELECTED QUEEN:"}}</div>
    {render_menu_title_row(info)}
    <div class="queen_sprite_box">{render_queen_sprite(qid)}</div>
    {render_passive_block(details)}
    {render_menu_actions()}
  </section>

def render_menu_view_visible(
  qid: Chess/Types/QueenId,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame menu_frame_menu">
    <div class="menu_kicker">{text{"SELECTED QUEEN:"}}</div>
    {render_menu_title_row(info)}
    <div class="queen_sprite_box">{render_queen_sprite(qid)}</div>
    {render_passive_block(details)}
    {render_menu_actions()}
  </section>

def render_queen_screen(
  cursor: Chess/Types/QueenId,
  inv: Chess/Types/Inventory,
  screen: Chess/Types/Screen,
) -> HTML(Event):
  selected = queen_id_eq(Chess/Queens/selected_queen(inv), cursor)
  info = queen_wire_name(cursor)
  details = queen_passive_text(cursor)
  match is_queen_screen(screen):
    case 0:
      render_queen_screen_view_hidden(cursor, selected, info, details)
    case _:
      render_queen_screen_view_visible(cursor, selected, info, details)

def render_queen_screen_view_hidden(
  cursor: Chess/Types/QueenId,
  selected: U32,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame screen_hidden">
    <div class="menu_kicker">{text{"QUEEN"}}</div>
    {render_menu_title_row(info)}
    {render_queen_stage_nav(cursor)}
    {render_passive_block(details)}
    {render_queen_actions(selected)}
  </section>

def render_queen_screen_view_visible(
  cursor: Chess/Types/QueenId,
  selected: U32,
  info: String,
  details: String,
) -> HTML(Event):
  <section class="menu_frame">
    <div class="menu_kicker">{text{"QUEEN"}}</div>
    {render_menu_title_row(info)}
    {render_queen_stage_nav(cursor)}
    {render_passive_block(details)}
    {render_queen_actions(selected)}
  </section>

def render_select_button(selected: U32) -> HTML(Event):
  match selected:
    case 0:
      render_select_button_label("SELECT", "btn_primary btn_play btn_select_available")
    case _:
      render_select_button_label("SELECTED", "btn_primary btn_play btn_select_current")

def render_select_button_label(label: String, classes: String) -> HTML(Event):
  <button class={classes} on_click={select_unlock{}}>{text{label}}</button>

def render_match(
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
  screen: Chess/Types/Screen,
) -> HTML(Event):
  turn_side = match_turn_side(game)
  info_line = match_info_line(game)
  match is_match_screen(screen):
    case 0:
      render_match_view_hidden(rules, game, turn_side, info_line)
    case _:
      render_match_view_visible(rules, game, turn_side, info_line)

def render_match_view_hidden(
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
  turn_side: String,
  info_line: String,
) -> HTML(Event):
  <section class="match_frame screen_hidden">
    <div class="match_header">
      <div class="match_top">
        <div class="match_turn">
          <span class="match_turn_label">{text{"Turn:"}}</span>
          <span class="match_turn_value">{text{turn_side}}</span>
        </div>
        {render_match_close_link()}
      </div>
      <div class="match_info">{text{info_line}}</div>
    </div>
    <div class="match_grid_wrap">
      <div class="board">{...board_rows(game, rules, state_zero(game))}</div>
    </div>
    {render_match_outcome_modal(game)}
  </section>

def render_match_view_visible(
  rules: Chess/Types/RuleSet,
  game: Chess/Types/GameState,
  turn_side: String,
  info_line: String,
) -> HTML(Event):
  <section class="match_frame">
    <div class="match_header">
      <div class="match_top">
        <div class="match_turn">
          <span class="match_turn_label">{text{"Turn:"}}</span>
          <span class="match_turn_value">{text{turn_side}}</span>
        </div>
        {render_match_close_link()}
      </div>
      <div class="match_info">{text{info_line}}</div>
    </div>
    {render_match_board_mount(game, rules)}
    {render_match_outcome_modal(game)}
  </section>

def render_match_close_link() -> HTML(Event):
  <a class="btn_x" href="./">
    <span class="match_close_mobile">{text{"X"}}</span>
    <span class="match_close_desktop">{text{"RESIGN"}}</span>
  </a>

def render_match_outcome_modal(game: Chess/Types/GameState) -> HTML(Event):
  match match_outcome_modal_visible(game):
    case 0:
      render_match_outcome_modal_hidden()
    case _:
      render_match_outcome_modal_visible(game)

def render_match_outcome_modal_hidden() -> HTML(Event):
  <div class="match_outcome_modal screen_hidden">{text{""}}</div>

def render_match_outcome_modal_visible(game: Chess/Types/GameState) -> HTML(Event):
  <div class="match_outcome_modal">
    <div class="match_outcome_card">
      <div class="match_outcome_text">{text{match_outcome_popup_text(game)}}</div>
      <a class="match_outcome_ok" href="./">{text{"OK"}}</a>
    </div>
  </div>

def render_match_board_mount(
  game: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
) -> HTML(Event):
  match match_board_toggle(game):
    case 0:
      render_match_board_even(game, rules)
    case _:
      render_match_board_odd(game, rules)

def match_board_toggle(game: Chess/Types/GameState) -> U32:
  match game:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      seed & 1

def render_match_board_even(
  game: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
) -> HTML(Event):
  <div class="match_grid_wrap">
    <div class="board">{...board_rows(game, rules, state_zero(game))}</div>
  </div>

def render_match_board_odd(
  game: Chess/Types/GameState,
  rules: Chess/Types/RuleSet,
) -> HTML(Event):
  <section class="match_grid_wrap">
    <div class="board">{...board_rows(game, rules, state_zero(game))}</div>
  </section>

def match_turn_side(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      Chess/Engine/color_name(side)

def match_info_line(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      moves_line = "Last White: " ++ last_white ++ " | Last Black: " ++ last_black
      match Chess/Engine/is_playing(outcome):
        case 0:
          moves_line
        case _:
          moves_line ++ " | Outcome: " ++ Chess/Engine/outcome_text(outcome)

def match_outcome_modal_visible(state: Chess/Types/GameState) -> U32:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      match Chess/Engine/is_playing(outcome):
        case 0:
          1
        case _:
          0

def match_outcome_popup_text(state: Chess/Types/GameState) -> String:
  match state:
    case game{board, side, selected, targets, status, last_move, last_white, last_black, outcome, seed, wc, bc}:
      Chess/Engine/outcome_text(outcome)

def is_menu_screen(screen: Chess/Types/Screen) -> U32:
  match screen:
    case menu_screen{}:
      1
    case _:
      0

def is_queen_screen(screen: Chess/Types/Screen) -> U32:
  match screen:
    case queen_screen{}:
      1
    case _:
      0

def is_match_screen(screen: Chess/Types/Screen) -> U32:
  match screen:
    case match_screen{}:
      1
    case _:
      0

def queen_wire_name(qid: Chess/Types/QueenId) -> String:
  match qid:
    case queen_default{}:
      "DEFAULT"
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
@import url('https://fonts.googleapis.com/css2?family=Gasoek+One&family=Poppins:wght@500;800;900&display=swap');
:root{
  --app-pad:50px;
  --card-width:min(92vw,560px);
  --menu-card-height:min(90vh,760px);
  --match-card-height:min(90vh,760px);
  --card-border:none;
  --card-pad:3px;
  --card-gap:20px;
  --menu-kicker-row:24px;
  --menu-title-row:72px;
  --menu-passive-row:92px;
  --menu-button-width:420px;
  --menu-button-height:64px;
  --menu-action-row:var(--menu-button-height);
  --menu-link-row:44px;
  --menu-actions-gap:5px;
  --menu-actions-top-space:0px;
  --menu-header-offset-y:10px;
  --menu-body-offset-y:-10px;
  --menu-title-offset-y:-8px;
  --menu-selected-title-size:clamp(38px,7vw,66px);
  --menu-stage-top-offset-y:-8px;
  --match-header-gap:1px;
  --match-board-gap:8px;
  --match-close-top:18px;
  --match-close-right:22px;
  --board-gap:2px;
  --board-radius:8px;
  --board-max-size:calc(var(--card-width) - (2 * var(--card-pad)));
  --board-piece-size:90%;
  --queen-nav-size:52px;
  --queen-nav-gap:8px;
  --queen-stage-nav-gap:12px;
  --queen-header-gap:2px;
  --queen-stage-size:clamp(210px,40vh,340px);
  --queen-stage-top-offset-y:-20px;
  --queen-stage-offset-y:40px;
  --queen-bg-size:65%;
  --queen-piece-size:70%;
  --body-font:'Poppins','Trebuchet MS',sans-serif;
  --queen-name-font:'Gasoek One','Trebuchet MS',sans-serif;
  --micro-label-font:'Poppins','Trebuchet MS',sans-serif;
  --micro-label-size:clamp(12px,1.9vw,15px);
}
"

css_b : String = "
html{height:100%;overflow:hidden}
*{box-sizing:border-box;margin:0}
body{height:100%;overflow:hidden;background:#FFFADA;color:#111;font-family:var(--body-font);font-weight:500}
.page{height:100%;padding:var(--app-pad);display:grid;place-items:center}
.screen_stack{width:100%;display:grid;place-items:center}
.menu_frame{
  width:var(--card-width);
  height:var(--menu-card-height);
  border:var(--card-border);
  padding:var(--card-pad);
  display:grid;
  gap:var(--card-gap);
  background:transparent;
  overflow:hidden;
  grid-template-rows:var(--menu-kicker-row) var(--menu-title-row) var(--queen-stage-size) var(--menu-passive-row) minmax(0,1fr) var(--menu-action-row) var(--menu-link-row);
}
.menu_frame_menu{grid-template-rows:var(--menu-kicker-row) var(--menu-title-row) var(--queen-stage-size) var(--menu-passive-row) var(--menu-actions-top-space) auto minmax(0,1fr)}
.match_frame{
  width:var(--card-width);
  height:var(--match-card-height);
  border:var(--card-border);
  padding:var(--card-pad);
  position:relative;
  display:grid;
  gap:var(--match-board-gap);
  background:transparent;
  overflow:hidden;
  grid-template-rows:auto minmax(0,1fr);
}
"

css_c : String = "
.screen_hidden{display:none !important}
.menu_frame_menu>.menu_kicker{transform:translateY(var(--menu-header-offset-y))}
.menu_frame_menu>.queen_nav{transform:translateY(calc(var(--menu-header-offset-y) + var(--menu-title-offset-y)))}
.menu_frame_menu>.queen_sprite_box{transform:translateY(calc(var(--menu-body-offset-y) + var(--menu-stage-top-offset-y)))}
.menu_frame_menu>.passive_block,.menu_frame_menu>.menu_actions{transform:translateY(var(--menu-body-offset-y))}
.menu_kicker{height:100%;display:flex;align-items:flex-end;justify-content:center;text-align:center;font-family:var(--micro-label-font);font-size:var(--micro-label-size);font-weight:800;letter-spacing:.02em;color:#BE0F0F}
.menu_title{text-align:center;font-size:var(--menu-selected-title-size);line-height:1;font-family:var(--queen-name-font);font-weight:400}
.passive_block{height:100%;display:grid;grid-template-rows:auto auto;gap:8px;align-content:start}
.passive_label{text-align:center;font-family:var(--micro-label-font);font-size:var(--micro-label-size);font-weight:800;letter-spacing:.02em;color:rgba(21,47,81,.72)}
.passive_text{height:auto;display:grid;place-items:start center;text-align:center;font-size:clamp(14px,2.4vw,18px);font-style:italic;color:rgba(17,17,17,.7);overflow:hidden}
"

css_d : String = "
.queen_nav{height:100%;display:grid;grid-template-columns:var(--queen-nav-size) 1fr var(--queen-nav-size);align-items:start;gap:var(--queen-nav-gap);margin-top:calc(var(--queen-header-gap) - var(--card-gap))}
.queen_stage_nav{width:100%;display:grid;grid-template-columns:var(--queen-nav-size) minmax(0,var(--queen-stage-size)) var(--queen-nav-size);justify-content:center;align-items:center;gap:var(--queen-stage-nav-gap);transform:translateY(var(--queen-stage-top-offset-y))}
.nav_spacer{width:var(--queen-nav-size);height:var(--queen-nav-size);display:block}
.btn_nav{width:var(--queen-nav-size);height:var(--queen-nav-size);border:2px solid #111;background:#fff;font-size:30px;line-height:1;cursor:pointer}
.menu_actions,.queen_actions{grid-row:6;display:grid;justify-items:center;align-content:start;gap:var(--menu-actions-gap)}
.queen_sprite_box{width:var(--queen-stage-size);height:var(--queen-stage-size);margin:0 auto;display:grid;place-items:center;background-image:url('./assets/bg-square.png');background-repeat:no-repeat;background-size:var(--queen-bg-size);background-position:center calc(50% + var(--queen-stage-offset-y))}
.queen_sprite{width:var(--queen-piece-size);height:var(--queen-piece-size);max-width:100%;max-height:100%;object-fit:contain;pointer-events:none;transform:translateY(var(--queen-stage-offset-y))}
"

css_e : String = "
.btn_primary,.btn_selected{width:min(var(--menu-button-width),90vw);height:var(--menu-button-height);margin:0 auto;border:3px solid #111;background:#fff;font-size:clamp(28px,6vw,44px);font-weight:900;cursor:pointer}
.btn_play{width:auto;min-width:160px;height:46px;padding:0 28px;border:none;outline:none;background:#A4F28E;font-family:'Poppins','Trebuchet MS',sans-serif;font-weight:900;font-size:clamp(18px,4vw,25px)}
.btn_select_available{background:#A4F28E;color:#111}
.btn_select_current{background:#D8D8D8;color:#4C4C4C;cursor:default}
.btn_selected{color:#4c4c4c;cursor:default}
.btn_link{height:100%;border:none;background:transparent;width:fit-content;margin:0 auto;text-decoration:underline;font-size:clamp(24px,5.2vw,38px);color:#111;cursor:pointer;display:grid;place-items:center}
.btn_change_queen{height:auto;font-family:'Poppins','Trebuchet MS',sans-serif;font-weight:900;font-size:clamp(12px,2.4vw,16px);text-transform:uppercase;color:#1D4E0E}
.btn_back{height:100%;border:none;background:transparent;width:fit-content;margin:0 auto;text-decoration:underline;font-size:clamp(24px,5.2vw,38px);color:#111;cursor:pointer;display:grid;place-items:center}
"

css_f : String = "
.match_header{display:grid;grid-template-rows:auto auto;gap:var(--match-header-gap)}
.match_top{height:100%;display:flex;justify-content:space-between;align-items:center;gap:6px}
.match_turn{display:inline-flex;align-items:center;gap:5px;font-size:clamp(16px,2.8vw,24px);font-weight:700;line-height:1}
.match_turn_label{color:#403E3E;text-transform:uppercase}
.match_turn_value{color:#000;text-transform:uppercase}
.btn_x{border:none;background:transparent;color:#111;font-size:clamp(24px,4vw,34px);font-weight:900;line-height:1;cursor:pointer;padding:0;text-decoration:none;display:inline-block}
.match_close_mobile{display:inline}
.match_close_desktop{display:none}
.match_info{overflow:hidden;font-size:clamp(11px,1.7vw,15px);line-height:1.05}
.match_outcome_modal{position:fixed;inset:0;display:grid;place-items:center;padding:24px;background:rgba(255,250,218,.78);z-index:40}
.match_outcome_card{width:min(360px,calc(100vw - 40px));border:2px solid #111;border-radius:16px;background:#FFFADA;padding:24px 20px;display:grid;justify-items:center;gap:14px;box-shadow:0 12px 32px rgba(0,0,0,.18)}
.match_outcome_text{text-align:center;font-family:'Poppins','Trebuchet MS',sans-serif;font-size:clamp(18px,3vw,24px);font-weight:800;line-height:1.1;color:#111}
.match_outcome_ok{min-width:96px;height:42px;padding:0 20px;border:none;border-radius:999px;background:#A4F28E;color:#111;text-decoration:none;display:grid;place-items:center;font-family:'Poppins','Trebuchet MS',sans-serif;font-size:14px;font-weight:900;letter-spacing:.04em}
.match_grid_wrap{width:100%;height:100%;min-height:0;display:grid;place-items:center;overflow:hidden}
.board{
  width:100%;
  max-width:var(--board-max-size);
  max-height:100%;
  aspect-ratio:1/1;
  display:grid;
  grid-template-rows:repeat(8,minmax(0,1fr));
  gap:var(--board-gap);
  border-radius:var(--board-radius);
  overflow:hidden;
}
.board_row{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:var(--board-gap)}
.cell_light,.cell_dark{width:100%;height:100%;border:none;cursor:pointer;display:grid;place-items:center;position:relative;overflow:hidden;padding:0}
.cell_light{background:#A4F28E}
.cell_dark{background:#82B786}
"

css_g : String = "
.cell_inner{width:100%;height:100%;display:grid;place-items:center;position:relative}
.piece_empty,.overlay_none{display:none}
.piece_img{width:var(--board-piece-size);height:var(--board-piece-size);object-fit:contain;pointer-events:none;filter:drop-shadow(0 1px 1px rgba(0,0,0,.25))}
.cell_target_dot{position:absolute;inset:0;display:grid;place-items:center;font-size:clamp(20px,4vw,30px);color:#31586f;line-height:1;pointer-events:none}
.cell_selected_ring{position:absolute;inset:3px;border:3px solid #1f6fa5;border-radius:8px;pointer-events:none}
.cell_check_badge{position:absolute;top:2px;right:2px;min-width:16px;height:16px;border-radius:999px;background:#b42318;color:#fff;font-size:11px;font-weight:800;display:flex;align-items:center;justify-content:center;pointer-events:none}
@media (max-width: 600px){
  :root{--app-pad:8px;--card-width:100vw;--menu-card-height:100vh;--match-card-height:100vh}
  .page{padding:var(--app-pad);overflow:auto}
}
@media (min-width: 900px){
  .btn_x{position:fixed;top:var(--match-close-top);right:var(--match-close-right);z-index:20;font-family:'Poppins','Trebuchet MS',sans-serif;font-size:12px;font-weight:900;letter-spacing:.08em;text-transform:uppercase;color:rgba(122,31,31,.82)}
  .match_close_mobile{display:none}
  .match_close_desktop{display:inline}
}
"

css : String = css_a ++ css_b ++ css_c ++ css_d ++ css_e ++ css_f ++ css_g

main : App = app{Chess/Types/RootState, Event, init, render, on_event}
