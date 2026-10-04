# Ruby GORILLAS

QBasic's GORILLA.BAS (1990), written again in Ruby on rbgame. Two gorillas on
a random skyline take turns typing an angle and a velocity; the banana flies
under gravity and wind, blows craters in buildings, startles the sun, and
scores when it lands on the other gorilla. The tunes are the original PLAY
strings, rendered by `Rbgame::Synth` as PC-speaker square waves.

```sh
bin/gorillas                                  # play (Esc or Q quits)
bin/gorillas --autoplay                       # watch Ruby play Rust
bin/gorillas --autoplay --record frames/ --frames 600 --every 2 --seed 7
bin/gorillas --points 5 --gravity 1.6 --names Neil,Buzz
```

Until the SDL translation grows a platform video backend the game draws to
an offscreen framebuffer; `--record` is how to watch it today.

## Layout

The model knows nothing about pixels or keys:

| | |
|---|---|
| `Skyline`, `Building` | the city, generated as MakeCityScape did (five slope shapes) |
| `Terrain` | the city as pixels, for POINT-style collisions and craters |
| `Shot` | the trajectory equations of the original |
| `Wind`, `Sun`, `Gorilla`, `Banana`, `Explosion` | things on the field |
| `Round` | one city, turns, flights, explosions, the victory dance |
| `Match`, `Player` | names, scores, gravity, who throws first |
| `Prompt` | QBasic `INPUT` with a blinking cursor |
| `Autoplayer` | aims by simulating `Shot`s against the `Terrain` |

Scenes (`scenes/`) draw the model and feed it events; `Game` is the
`Rbgame::Game` subclass that runs them. `test/` covers the model and runs
the whole game headless for a few hundred frames.
