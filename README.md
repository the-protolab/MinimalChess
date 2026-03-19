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

## Engine Assertions

```sh
bend src/Chess/Tests.bend --to-js --no-strict > /tmp/minimal_chess_tests.js
```

## Notes for HOC

This project compiles and runs with `--no-strict`.
Strict mode currently rejects this app-style code shape (case-tree validation), so the current Bend2 limitation to report is strict top-level case-tree constraints for richer state-machine/UI code.
