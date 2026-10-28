# Gaussian FPV

A first-person drone game where the player freely explores real-world places captured as Gaussian Splats.

## Language

**World**:
The persistent environment holding the Drone, into which exactly one Map at a time is injected and swapped.
_Avoid_: Level, game scene

**Map**:
An abstraction over one or more splat files of a real-world place, each with its own placement, plus what's needed to fly in it (orientation, scale, Map Bounds, Spawn Point). It is injected into the World. It has no goals; the player explores it freely.
_Avoid_: Scene (reserved for Godot scenes), level

**Splat**:
One Gaussian in a Map: a soft, colored, semi-transparent ellipsoid. A Map is made of millions of them.
_Avoid_: Point, particle

**Spawn Point**:
The position and heading in a Map where the Drone starts, and returns to on reset.
_Avoid_: Start, checkpoint

**Map Bounds**:
The box a Map's flyable space is confined to; the Drone cannot leave it.
_Avoid_: Level edge, play area

**Drone**:
The aircraft the player controls, viewed first-person (FPV) from its camera.
_Avoid_: Quad, player, ship

**Acro**:
The Drone's only flight model: the sticks command rotation rates, not angles, the Drone never levels itself, and throttle is raw thrust against gravity.
_Avoid_: Rate mode, manual mode

**Uptilt**:
The fixed upward angle of the Drone's camera relative to its body.
_Avoid_: Camera angle, pitch

**Collision Mesh**:
The solid surface the Drone can hit, derived from a Map's Splats. The Splats themselves are only visual.
_Avoid_: Collider, physics mesh
