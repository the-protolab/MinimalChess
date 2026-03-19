# Chess core shared types.

# Piece side.
type Color {
  white{}
  black{}
}

# Piece kind.
type PieceKind {
  king{}
  queen{}
  rook{}
  bishop{}
  knight{}
  pawn{}
}

# One piece on board.
type Piece {
  piece{color: Color, kind: PieceKind}
}

# Board coordinate.
type Pos {
  pos{row: U32, col: U32}
}

# One move from -> to.
type Move {
  move{from: Pos, to: Pos}
}

# Game outcome.
type Outcome {
  playing{}
  checkmate{winner: Color}
  stalemate{}
}

# Future player source for each side.
type Controller {
  human{}
  bot{}
}

# Full game state used by app + engine + bot.
type GameState {
  game{
    board: List(Maybe(Piece)),
    side: Color,
    selected: Maybe(Pos),
    targets: List(Move),
    status: String,
    last_move: String,
    outcome: Outcome,
    seed: U32,
    white_ctrl: Controller,
    black_ctrl: Controller,
  }
}
