# Test fixtures

* `DejaVuSansMono.ttf`: DejaVu Sans Mono, under `DejaVu-LICENSE.txt`.
* `DejaVuSans.pfb`, `DejaVuSans-SVG.ttf`: DejaVu Sans subsets made by the SDL
  translation's test data tools (`sdl3-ttf/src/testdata/fonts`), as a Type 1
  PFB font and as a TrueType font with OpenType SVG colour glyphs; under
  `DejaVu-LICENSE.txt` too.
* `sample.avif`, `sample.jxl`, `avif_anim.avifs`: the SDL translation's own
  synthetic test pictures (`sdl3-image/src/testdata/images` in
  [danielpclark/SDL](https://github.com/danielpclark/SDL), zlib license),
  a 23x42 picture as AVIF and JPEG XL and a three-frame AVIF image sequence.

None of these ship in the gem (see `rbgame.gemspec`).
