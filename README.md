# love-2d-tetris

An unofficial falling-block puzzle game made with LÖVE.

## Timing notice

This game intentionally uses frame-based timing and assumes that
`love.update` runs at 60 Hz. It does not use delta time (`dt`) to normalize
gameplay speed. Run the game at 60 Hz for the intended gravity, movement,
lock-delay, and animation timing; other update rates may make the game run
faster or slower.

## Architecture

The game uses a lightweight MVC-style structure. `gameState.lua`,
`tetromino.lua`, and `guidelineScoreCalc.lua` form the model;
`gameController.lua` handles input and game flow; and `batchDraws.lua`
provides the renderer.

`gameController.draw(renderer)` accepts a duck-typed renderer rather than a
concrete implementation. The required renderer methods are documented beside
the `draw` function in `gameController.lua`. Matrix data passed to a renderer
must be treated as read-only.

## Benchmark

Run the headless frame-budget benchmark with LuaJIT:

```sh
luajit main.lua benchtest
```

The optional final argument sets the number of replay runs, for example
`luajit main.lua benchtest 250`. The benchmark preserves the recorded gaps
between human input events, measures cold and warmed-up update-and-draw frames,
and fails if any measured frame takes 16 ms or longer. Its renderer performs a
read-only traversal of the full game matrix but does not issue graphics calls,
so this measures game and renderer-dispatch CPU work, not LÖVE or GPU
presentation time. Results list the timer and frame scope, sample counts, and
average, p99, and maximum times for both cold and warm frames. Cold and warm
maximums should not be compared directly because the warm group contains many
more samples and is therefore more likely to include a rare outlier.

## License

Code and original project material are available under the [MIT License](LICENSE).
Third-party names, trademarks, logos, and assets are not licensed under the
MIT License. See [NOTICE](NOTICE) for important details.

This project is not affiliated with, sponsored by, or endorsed by Tetris
Holding, LLC, The Tetris Company, Inc., or their affiliates. TETRIS and
related names and logos are trademarks of their respective owners.
