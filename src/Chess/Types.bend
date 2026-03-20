# Chess shared types.

type Color {
  white{}
  black{}
}

type PieceKind {
  king{}
  queen{}
  rook{}
  bishop{}
  knight{}
  pawn{}
}

type Piece {
  piece{color: Color, kind: PieceKind}
}

type Pos {
  pos{row: U32, col: U32}
}

type Move {
  move{from: Pos, to: Pos}
}

type Outcome {
  playing{}
  checkmate{winner: Color}
  stalemate{}
}

type Controller {
  human{}
  bot{}
}

type Screen {
  menu_screen{}
  queen_screen{}
  match_screen{}
}

type EffectTarget {
  target_player{}
  target_opponent{}
  target_both{}
}

type Passive {
  pawn_first_move_max{target: EffectTarget, max_steps: U32}
}

type QueenId {
  queen_default{}
  queen_plus{}
  queen_minus{}
}

type QueenDef {
  queen_def{id: QueenId, name: String, passive: Passive}
}

type Inventory {
  inventory{
    selected: QueenId,
    unlocked_default: U32,
    unlocked_plus: U32,
    unlocked_minus: U32,
  }
}

type RuleSet {
  ruleset{
    player_pawn_first_max: U32,
    opponent_pawn_first_max: U32,
  }
}

type GameState {
  game{
    board: List(Maybe(Piece)),
    side: Color,
    selected: Maybe(Pos),
    targets: List(Move),
    status: String,
    last_move: String,
    last_white_move: String,
    last_black_move: String,
    outcome: Outcome,
    seed: U32,
    white_ctrl: Controller,
    black_ctrl: Controller,
  }
}

type RootState {
  root{
    screen: Screen,
    queen_cursor: QueenId,
    inventory: Inventory,
    rules: RuleSet,
    game_state: GameState,
    menu_status: String,
  }
}
