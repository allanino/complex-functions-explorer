# Complex Functions Explorer

<p align="center">
  <img src="docs/images/hero.png" width="800" alt="Complex Functions Explorer Zeta">
</p>

**Complex Functions Explorer** is an interactive 3D visualization tool for exploring complex analysis through immersive landscapes.
Navigate functions such as the Riemann zeta function and discover zeros, poles, critical structures,
and transformations directly in the complex plane.

Designed for students, researchers, and the mathematically curious, it offers an intuitive way to
experience the geometry hidden inside complex functions.

Check the [web page](https://allanino.github.io/complex-functions-explorer/) and the [docs](https://allanino.github.io/complex-functions-explorer/docs) for more details.

## Highlights

* Explore complex functions in real time as immersive 3D landscapes.
* Visualize function values using color for phase and terrain height for magnitude.
* Navigate the complex plane freely with smooth first-person camera controls.
* No bounding boxes — the landscape unfolds as you travel.
* Discover zeros, poles, and critical structures.
* Explore the Riemann zeta function and its hidden geometry.
* Use the minimap to orient yourself across the complex plane.
* Adjust function parameters and watch the landscape transform instantly.
* Navigate between branches of multivalued functions through immersive portals.
* Walk on the Riemann Sphere instead of the plane (Visualization tab), with adjustable radius and optional radial height.
* Customize environment, colors and rendering options.

<p align="center">
  <img src="docs/images/highlights.png" width="800" alt="Complex Functions Explorer Highlights">
</p>

## Technical Details

Built with the **Godot Engine**, the project leverages modern rendering and audio techniques:

*   **GPU Shaders:** Terrain displacement and domain coloring are handled via GLSL shaders for high-performance real-time visualization.
*   **Spatial Audio:** A topographic drone responds to terrain height and phase, providing an auditory dimension to the mathematical exploration.
*   **Dynamic World:** Features a dynamic day/night cycle with customizable duration, a static time mode, and adjustable sunrise direction.

## Development

### Building the GDExtension (C++)

This project uses **GDExtension + godot-cpp + SCons**.

#### First-time setup

Clone submodules:

```bash
git submodule update --init --recursive
```

Build `godot-cpp` bindings and static library:

```bash
cd godot-cpp
scons platform=linux target=template_debug generate_bindings=yes
cd ..
```

Build the extension:

```bash
scons platform=linux target=template_debug
```

This should generate:

```text
bin/libcomplex_functions.linux.template_debug.x86_64.so
```

#### Development workflow

Whenever a `.cpp` or `.h` file changes:

```bash
scons platform=linux target=template_debug
```

SCons rebuilds incrementally (only changed files).

Then reload the Godot project if changes do not appear.

#### Exporting and packaging release builds

1. **Build the release GDExtension library:**

   ```bash
   scons platform=linux target=template_release
   ```

   This generates:

   ```text
   bin/libcomplex_functions.linux.template_release.x86_64.so
   ```

   Godot automatically loads:
   * `*.debug.*` → Editor + Debug exports
   * `*.release.*` → Release exports

2. **Install Godot Export Templates (one-time per Godot version):**

   Open the project in the Godot editor, go to **Editor → Manage Export Templates...**, and click **Download and Install** for the current Godot version (templates are installed to `~/.local/share/godot/export_templates/`).

3. **Export and package releases:**

   Run the packaging script from the repository root:

   ```bash
   ./utils/package_releases.sh
   ```

   This script runs `godot --headless --export-release` for both **Linux** and **Windows Desktop** presets and packages the final artifacts:
   * `bin/Linux/Complex_Functions_Explorer-x86_64.AppImage`
   * `bin/Windows/ComplexFunctionsExplorer.zip`

### Common problems

#### Missing GDExtension library

Error:

```text
GDExtension dynamic library not found
```

Check:

* `godot-cpp/` exists
* `godot-cpp` was built
* `bin/*.so` exists
* paths match `complex_functions.gdextension`

#### Fresh clone fails

Run:

```bash
git submodule update --init --recursive
```

to fetch `godot-cpp`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
