# Minimal Chess (Bend2)

Human (White) vs random bot (Black), with modular architecture:
- `src/Chess/Types.bend`
- `src/Chess/Engine.bend`
- `src/Chess/Bot.bend`
- `src/main.bend`

## Run

```sh
bend src/main.bend --no-strict
```

## Build Artifacts

```sh
bend src/main.bend --to-js --no-strict > /tmp/minimal_chess.js
bend src/main.bend --to-web --no-strict > /tmp/minimal_chess.html
```

## Web Preview (With Piece Assets)

To preview the web build with chess-piece SVG files available, run:

```sh
./scripts/preview_web.sh
```

Then open `http://127.0.0.1:61424`.

## GitHub Pages / Deploy Build

The deployed site is served from `docs/`, so rebuild that directory before pushing deploy changes:

```sh
./scripts/build_docs.sh
```

## Engine Assertions

```sh
bend src/Chess/Tests.bend --to-js --no-strict > /tmp/minimal_chess_tests.js
```

## Notes for HOC

This project compiles and runs with `--no-strict`.
Strict mode currently rejects this app-style code shape (case-tree validation), so the current Bend2 limitation to report is strict top-level case-tree constraints for richer state-machine/UI code.
