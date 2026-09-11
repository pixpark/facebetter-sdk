#pragma once

struct GLFWwindow;

namespace demo {
class Studio;

void ApplyStudioTheme();
void LoadStudioFonts(float dpi_scale);
void DrawStudio(Studio& studio, GLFWwindow* window);

}  // namespace demo
