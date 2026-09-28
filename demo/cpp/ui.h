#pragma once

struct GLFWwindow;

namespace demo {
class Studio;

void ApplyStudioTheme();
// ui_scale enlarges layout in window coordinates. On macOS that is ~1
// (points already follow DPI). On Windows it is the display scale.
void SetUiScale(float ui_scale);
// framebuffer_scale is pixels per window coordinate (Retina). Fonts are
// rasterized at framebuffer_scale * ui_scale and drawn at ui_scale.
void LoadStudioFonts(float framebuffer_scale, float ui_scale);
void DrawStudio(Studio& studio, GLFWwindow* window);

}  // namespace demo
