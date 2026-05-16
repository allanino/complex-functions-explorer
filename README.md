# Complex Functions Explorer

<p align="center">
  <img src="docs/images/background.png" width="800" alt="Complex Functions Explorer Background">
</p>

**Complex Functions Explorer** is an interactive 3D visualization tool that brings the abstract beauty of complex analysis to life. By mapping complex numbers into a navigable three-dimensional landscape, the software allows users to explore the intricate structures of functions such as the Riemann zeta function, including zeros, poles, and the critical line, within an immersive environment.

## Features

### Domain Coloring
The explorer uses **domain coloring** to visualize complex-valued functions. Each point in the complex plane is assigned a color according to the phase (argument) of the function, while the magnitude determines the height of the terrain.

*   **Phase to Color:** The color cycle represents the angle of the complex value.
*   **Magnitude to Height:** Peaks and valleys represent high and low magnitudes, respectively. Zeros are visible as deep pits that reach the "floor" of the domain.

<p align="center">
  <img src="docs/images/domain.png" width="300" alt="Domain Coloring">
  <img src="docs/images/terrain.png" width="300" alt="Terrain Magnitude">
</p>

### Curve Levels

Superimposed on the terrain are contour lines, or **curve levels**, which provide a geometric reference for the values of the function. These curves make it possible to trace how the real and imaginary components evolve across the complex plane.

*   **Black Curves (Real Part):** These correspond to level sets where the real part of the function, $ \text{Re}(f(s)) $, takes integer values. They reveal the underlying structure of the function’s real transformation.
    
*   **White Curves (Imaginary Part):** These correspond to level sets where the imaginary part, $ \text{Im}(f(s)) $, takes integer values. Together with the black curves, they form a curvilinear grid that reflects the conformal character of the mapping.

When a black curve and a white curve intersect at the base of the terrain, the point may correspond to a **zero** of the function, where both the real and imaginary parts vanish simultaneously.

### Supported Functions
The explorer supports various standard complex functions, including trigonometric, exponential, and logarithmic functions. The centerpiece is the **Riemann zeta function** $\zeta(s)$.

#### The Riemann Zeta Function
Implementation uses the **Dirichlet Eta representation** for numerical stability:
$$\zeta(s) = \frac{1}{1 - 2^{1-s}} \sum_{n=1}^\infty \frac{(-1)^{n-1}}{n^s}$$
This allows evaluation across the critical strip, essential for visualizing the region related to the Riemann Hypothesis.

## Technical Details

Built with the **Godot Engine**, the project leverages modern rendering and audio techniques:

*   **GPU Shaders:** Terrain displacement and domain coloring are handled via GLSL shaders for high-performance real-time visualization.
*   **Spatial Audio:** A topographic drone responds to terrain height and phase, providing an auditory dimension to the mathematical exploration.
*   **Dynamic World:** Features a day/night cycle, golden hour transitions, and customizable rendering modes (Estimated vs. Precise shading).

## Controls

*   **Movement:** `W`, `A`, `S`, `D` keys.
*   **Elevation:** `Space` (Double-press to reset height).
*   **Sprint:** Hold `Shift`.
*   **Slow Walk:** Hold `Ctrl`.
*   **Menu:** `Esc` to toggle settings.
*   **Automatic Walking:** `Ctrl + C` (when viewing the Zeta function) to walk along the critical line.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
