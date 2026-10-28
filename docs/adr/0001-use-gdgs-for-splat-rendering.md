# Use GDGS instead of a custom splat renderer

The original intent was a custom Gaussian splat renderer in Godot, but the decision was "use an existing renderer if one fits, otherwise write our own". GDGS (github.com/ReconWorldLab/godot-gaussian-splatting, MIT) fits: it is actively maintained, supports Godot 4.3+, renders through a compute-shader CompositorEffect on Forward+, composites depth with regular meshes, and loads .ply, .splat, .sog and .glb. We vendor it into `client/addons/` pinned to v3.3.0 and modify it as needed rather than writing a renderer from scratch.

## Considered Options

- **2Retr0/GodotGaussianSplatting**: dormant since 2024, described by its author as a toy viewer, uses gigabytes of memory, and its depth compositing with meshes is unknown.
- **haztro/godot-gaussian-splatting**: smaller in scope, and its depth compositing is unknown.
- **klausi3D/godotGS**: a fork of the Godot engine rather than an addon, which would tie us to its engine version; its own benchmark reports 12 fps at about 4.9M Splats.
- **Write our own**: full control, but months of work to reach what GDGS already does.

## Consequences

- Rendering is Forward+ only, since GDGS's compute backend needs it.
- Verified on Godot 4.7.2 (D3D12, RTX 4070): the 2.54M-Splat Truck Map renders at ~120 fps at 1080p via `client/tests/render_smoke.gd`.
- Since the addon is vendored, upstream fixes are pulled in by hand.
