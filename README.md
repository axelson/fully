# Fully

Elixir Nerves app that interfaces with my [Jarvis stand-up desk from fully.com](https://www.fully.com/standing-desks/jarvis.html).

Credit for reverse-engineering goes to Phil Hord, who has extensive notes up at
https://github.com/phord/Jarvis

This is one part of my automated office that is orchestrated by my Scenic Side Screen:
https://github.com/axelson/scenic-side-screen

Implementation status:
- This currently implements the minimum that is needed for my own use case, which right now is
  primarily raising and lowering to my memory presets
- In particular it's not easy to use commands that pass params (they have to be passed as raw binary)
- I also only implemented the ability to read the HEIGHT response

# Usage

To start your Nerves app:
- `export MIX_TARGET=rpi0_2`
- `mix deps.get`
- `mix firmware`
- `mix burn` or `mix upload nerves.local`
