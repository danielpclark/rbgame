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

Three layers, and the model never sees a pixel or a key:

**Model** (`lib/gorillas/`)

| | |
|---|---|
| `Match`, `Player` | names, scores, gravity, who throws first |
| `Round` | one city, two gorillas, turns; its behaviour lives in phase objects |
| `Round::Phase` | `Aiming`, `Flying`, `Exploding`, `Dancing`, `Over`: each handles time and throws and hands over to the next |
| `Skyline`, `Building` | the city, built by an `Architect` walking the field under a `Slope` (rising, falling, valley, peak, random) |
| `Terrain` | the city as pixels, for POINT-style collisions and craters |
| `Shot`, `Flight`, `Banana` | the trajectory equations, a banana in the air, the banana at an instant |
| `Wind`, `Sun`, `Gorilla`, `Explosion`, `Outcome` | immutable values of the field |
| `Autoplayer` | aims by rehearsing `Shot`s against the `Terrain` |

**Input** (`lib/gorillas/`, `controllers/`)

| | |
|---|---|
| `Prompt`, `Questionnaire` | QBasic `INPUT`, and a series of them answered by key |
| `Controllers::Keyboard`, `Controllers::Autopilot` | who answers: the player, or a `Typist` typing the autoplayer's aim |
| `Jukebox` | the tunes; it listens to the round for things worth hearing |

**View** (`lib/gorillas/view/`, `scenes/`)

| | |
|---|---|
| `GorillaSprite`, `SunSprite`, `BananaSprite`, `ExplosionSprite`, `WindGauge`, `CityView` | draw one model object each |
| `FieldView`, `Scoreboard`, `Typography` | compose them |
| `Scenes::Intro`, `Setup`, `Play`, `GameOver` | the screens; a scene returns the next one |

`Game` is the `Rbgame::Game` subclass that wires it together. `test/` covers
the model, the input objects, and runs the whole game headless for a few
hundred frames.
