#include "ui.h"

#include "i18n.h"
#include "native_dialog.h"
#include "studio.h"

#include <imgui.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace demo {

ImFont* g_btn_font = nullptr;
ImFont* g_icon_font = nullptr;
constexpr float kUiFontPx = 12.f;
constexpr float kBtnFontPx = 11.f;
constexpr float kIconFontPx = 14.f;
constexpr float kCtrlHeight = 28.f;
constexpr float kTabBarHeight = 56.f;

// Material Icons PUA → UTF-8（与 Web Demo 同一套图标名）
constexpr const char kIconFace[] = "\xEE\xA1\xBC";        // U+E87C face
constexpr const char kIconReshape[] = "\xEE\xA4\xAC";     // U+E92C accessibility_new
constexpr const char kIconMakeup[] = "\xEE\x8E\xAE";      // U+E3AE brush
constexpr const char kIconFilter[] = "\xEE\x90\x8A";      // U+E40A palette
constexpr const char kIconSticker[] = "\xEE\x99\x9F";     // U+E65F auto_awesome
constexpr const char kIconBackground[] = "\xEE\x8E\xA5";  // U+E3A5 blur_on

namespace {

ImVec4 Rgba(int r, int g, int b, int a = 255) {
  return ImVec4(r / 255.f, g / 255.f, b / 255.f, a / 255.f);
}

ImTextureID TexId(unsigned int tex) {
  return static_cast<ImTextureID>(tex);
}

constexpr float kInspectorWidth = 380.f;

const ImVec4 kBg = Rgba(11, 12, 16);
const ImVec4 kTop = Rgba(14, 16, 20);
const ImVec4 kPanel = Rgba(17, 19, 23);
const ImVec4 kCard = Rgba(24, 26, 32);
const ImVec4 kBorder = Rgba(34, 38, 48);
const ImVec4 kChip = Rgba(32, 35, 43);
const ImVec4 kText = Rgba(243, 244, 246);
const ImVec4 kMuted = Rgba(156, 163, 175);

int g_tab = 0;

ImVec2 LockedButtonSize(const char* label, ImVec2 size) {
  if (size.x <= 0.f)
    size.x = ImGui::CalcTextSize(label).x + ImGui::GetStyle().FramePadding.x * 2.f;
  if (size.y <= 0.f)
    size.y = kCtrlHeight;
  return size;
}

void PushBtnFont() {
  if (g_btn_font)
    ImGui::PushFont(g_btn_font);
}

void PopBtnFont() {
  if (g_btn_font)
    ImGui::PopFont();
}

float LogicalPx(const ImFont* font) {
  return font->FontSize * ImGui::GetIO().FontGlobalScale;
}

bool IconTab(const char* icon, const char* label, bool active, const ImVec2& size) {
  const bool hit = ImGui::InvisibleButton("##tab", size);
  const bool hovered = ImGui::IsItemHovered();
  const ImVec2 rmin = ImGui::GetItemRectMin();
  const ImVec2 rmax = ImGui::GetItemRectMax();
  ImDrawList* dl = ImGui::GetWindowDrawList();
  if (active)
    dl->AddRectFilled(rmin, rmax, IM_COL32(255, 255, 255, 255), 8.f);
  else if (hovered)
    dl->AddRectFilled(rmin, rmax, IM_COL32(32, 35, 43, 255), 8.f);
  const ImU32 fg = active ? IM_COL32(10, 10, 10, 255)
                          : hovered ? IM_COL32(229, 231, 235, 255)
                                    : IM_COL32(156, 163, 175, 255);

  ImFont* label_font = g_btn_font ? g_btn_font : ImGui::GetFont();
  const float label_px = LogicalPx(label_font);
  const ImVec2 label_ts =
      label_font->CalcTextSizeA(label_px, size.x, 0.f, label);

  float icon_h = 0.f;
  float icon_px = 0.f;
  ImVec2 icon_ts(0, 0);
  if (g_icon_font && icon && icon[0]) {
    icon_px = LogicalPx(g_icon_font);
    icon_ts = g_icon_font->CalcTextSizeA(icon_px, 1e9f, 0.f, icon);
    icon_h = icon_ts.y;
  }

  const float gap = icon_h > 0.f ? 2.f : 0.f;
  const float block_h = icon_h + gap + label_ts.y;
  float y = rmin.y + (size.y - block_h) * 0.5f;
  dl->PushClipRect(rmin, rmax, true);
  if (icon_h > 0.f) {
    dl->AddText(g_icon_font, icon_px,
                ImVec2(rmin.x + (size.x - icon_ts.x) * 0.5f, y), fg, icon);
    y += icon_h + gap;
  }
  dl->AddText(label_font, label_px,
              ImVec2(rmin.x + (size.x - label_ts.x) * 0.5f, y), fg, label);
  dl->PopClipRect();
  return hit;
}

bool Chip(const char* label, bool active, const ImVec2& size) {
  const ImVec2 sz = LockedButtonSize(label, size);
  ImGui::PushStyleColor(ImGuiCol_Button,
                        active ? ImVec4(1, 1, 1, 0.10f) : kChip);
  ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(1, 1, 1, 0.16f));
  ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(1, 1, 1, 0.22f));
  ImGui::PushStyleColor(ImGuiCol_Text, active ? ImVec4(1, 1, 1, 1) : kMuted);
  ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 1.f);
  ImGui::PushStyleColor(ImGuiCol_Border,
                        active ? ImVec4(1, 1, 1, 0.22f) : ImVec4(1, 1, 1, 0.05f));
  PushBtnFont();
  const bool hit = ImGui::Button(label, sz);
  PopBtnFont();
  ImGui::PopStyleColor(5);
  ImGui::PopStyleVar();
  return hit;
}

bool Pill(const char* label, bool active) {
  const ImVec2 sz = LockedButtonSize(label, ImVec2(0, 0));
  ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 14.f);
  ImGui::PushStyleColor(ImGuiCol_Button,
                        active ? ImVec4(1, 1, 1, 1) : Rgba(24, 26, 32));
  ImGui::PushStyleColor(ImGuiCol_ButtonHovered,
                        active ? Rgba(229, 231, 235) : Rgba(34, 38, 48));
  ImGui::PushStyleColor(ImGuiCol_Text,
                        active ? Rgba(10, 10, 10) : kMuted);
  ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 1.f);
  ImGui::PushStyleColor(ImGuiCol_Border,
                        active ? ImVec4(1, 1, 1, 1) : ImVec4(1, 1, 1, 0.10f));
  PushBtnFont();
  const bool hit = ImGui::Button(label, sz);
  PopBtnFont();
  ImGui::PopStyleColor(4);
  ImGui::PopStyleVar(2);
  return hit;
}

void BeginCard(const char* id) {
  ImGui::PushStyleColor(ImGuiCol_ChildBg, kCard);
  ImGui::PushStyleColor(ImGuiCol_Border, Rgba(38, 42, 53));
  ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, 12.f);
  ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(16, 14));
  ImGui::BeginChild(id, ImVec2(-1, 0),
                    ImGuiChildFlags_AutoResizeY | ImGuiChildFlags_Border);
}

void EndCard() {
  ImGui::EndChild();
  ImGui::PopStyleVar(2);
  ImGui::PopStyleColor(2);
  ImGui::Spacing();
}

void CardTitle(const char* title, const char* extra = nullptr) {
  ImGui::TextUnformatted(title);
  if (extra) {
    ImGui::SameLine(ImGui::GetWindowContentRegionMax().x -
                    ImGui::CalcTextSize(extra).x);
    ImGui::TextColored(kMuted, "%s", extra);
  }
  ImGui::Dummy(ImVec2(0, 2));
  ImGui::PushStyleColor(ImGuiCol_Separator, Rgba(38, 42, 53));
  ImGui::Separator();
  ImGui::PopStyleColor();
  ImGui::Spacing();
}

bool SliderBar(int* value, int vmin, int vmax, bool bipolar) {
  constexpr float kHitH = 14.f;
  constexpr float kTrackH = 6.f;
  constexpr float kGrabR = 7.f;
  const ImVec2 p = ImGui::GetCursorScreenPos();
  const float w = ImGui::GetContentRegionAvail().x;
  ImGui::InvisibleButton("##s", ImVec2(w, kHitH));
  bool changed = false;
  if (ImGui::IsItemActive()) {
    const float t =
        std::clamp((ImGui::GetIO().MousePos.x - p.x) / std::max(w, 1.f), 0.f, 1.f);
    const int nv =
        vmin + static_cast<int>(std::lround(t * static_cast<float>(vmax - vmin)));
    if (nv != *value) {
      *value = nv;
      changed = true;
    }
  }
  const float t = static_cast<float>(*value - vmin) /
                  static_cast<float>(std::max(1, vmax - vmin));
  const float cy = p.y + kHitH * 0.5f;
  const ImVec2 t0(p.x, cy - kTrackH * 0.5f);
  const ImVec2 t1(p.x + w, cy + kTrackH * 0.5f);
  const float gx = p.x + t * w;
  ImDrawList* dl = ImGui::GetWindowDrawList();
  dl->AddRectFilled(t0, t1, IM_COL32(37, 40, 48, 255), 99.f);
  dl->PushClipRect(t0, t1, true);
  const ImU32 fill = IM_COL32(229, 231, 235, 255);
  if (bipolar) {
    const float mid = p.x + w * 0.5f;
    if (gx >= mid)
      dl->AddRectFilled(ImVec2(mid, t0.y), ImVec2(gx, t1.y), fill);
    else
      dl->AddRectFilled(ImVec2(gx, t0.y), ImVec2(mid, t1.y), fill);
  } else {
    dl->AddRectFilled(t0, ImVec2(gx, t1.y), fill, 99.f);
  }
  dl->PopClipRect();
  const float grab_x = std::clamp(gx, p.x + kGrabR, p.x + w - kGrabR);
  dl->AddCircleFilled(ImVec2(grab_x, cy), kGrabR, IM_COL32(17, 19, 23, 255), 24);
  dl->AddCircle(ImVec2(grab_x, cy), kGrabR, IM_COL32(255, 255, 255, 255), 24, 2.f);
  return changed;
}

bool ParamSlider(const char* label, float* value) {
  int iv = static_cast<int>(std::lround(*value * 100.f));
  iv = std::clamp(iv, 0, 100);
  ImGui::PushID(label);
  ImGui::TextColored(kMuted, "%s", label);
  ImGui::SameLine(ImGui::GetContentRegionAvail().x - 8);
  ImGui::Text("%d", iv);
  const bool changed = SliderBar(&iv, 0, 100, false);
  ImGui::PopID();
  if (changed)
    *value = iv / 100.f;
  return changed;
}

bool BipolarSlider(const char* label, float* value) {
  int iv = static_cast<int>(std::lround(*value * 100.f));
  iv = std::clamp(iv, -100, 100);
  ImGui::PushID(label);
  ImGui::TextColored(kMuted, "%s", label);
  ImGui::SameLine(ImGui::GetContentRegionAvail().x - 16);
  ImGui::Text("%d", iv);
  const bool changed = SliderBar(&iv, -100, 100, true);
  ImGui::PopID();
  if (changed)
    *value = iv / 100.f;
  return changed;
}

bool Toggle(const char* id, bool* on) {
  ImGui::PushID(id);
  ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 12.f);
  ImGui::PushStyleColor(ImGuiCol_Button, *on ? Rgba(52, 199, 89) : Rgba(58, 58, 60));
  ImGui::PushStyleColor(ImGuiCol_ButtonHovered, *on ? Rgba(48, 209, 88)
                                                    : Rgba(72, 72, 74));
  const bool hit = ImGui::Button("##sw", ImVec2(42, 24));
  ImGui::PopStyleColor(2);
  ImGui::PopStyleVar();
  const ImVec2 min = ImGui::GetItemRectMin();
  const float knob = *on ? min.x + 20.f : min.x + 2.f;
  ImGui::GetWindowDrawList()->AddCircleFilled(
      ImVec2(knob + 10.f, min.y + 12.f), 10.f, IM_COL32(255, 255, 255, 255));
  ImGui::PopID();
  if (hit)
    *on = !*on;
  return hit;
}

template <typename Fn>
void ChipGrid(int columns, int count, Fn&& fn) {
  const float avail = ImGui::GetContentRegionAvail().x;
  const float gap = ImGui::GetStyle().ItemSpacing.x;
  const float w = (avail - gap * static_cast<float>(columns - 1)) /
                  static_cast<float>(columns);
  for (int i = 0; i < count; ++i) {
    if (i % columns != 0)
      ImGui::SameLine();
    ImGui::PushID(i);
    fn(i, ImVec2(w, 0));
    ImGui::PopID();
  }
}

void DrawLandmarks(ImDrawList* dl,
                   ImVec2 p0,
                   ImVec2 p1,
                   const std::vector<FaceDetectionResult>& faces) {
  const float w = p1.x - p0.x;
  const float h = p1.y - p0.y;
  int index = 0;
  for (const auto& face : faces) {
    const float x = p0.x + face.rect.x * w;
    const float y = p0.y + face.rect.y * h;
    const float rw = face.rect.width * w;
    const float rh = face.rect.height * h;
    const ImU32 line = IM_COL32(255, 255, 255, 200);
    const float c = 8.f;
    dl->AddRect(ImVec2(x, y), ImVec2(x + rw, y + rh), IM_COL32(255, 255, 255, 90));
    dl->AddLine(ImVec2(x, y + c), ImVec2(x, y), line, 2.f);
    dl->AddLine(ImVec2(x, y), ImVec2(x + c, y), line, 2.f);
    dl->AddLine(ImVec2(x + rw - c, y), ImVec2(x + rw, y), line, 2.f);
    dl->AddLine(ImVec2(x + rw, y), ImVec2(x + rw, y + c), line, 2.f);
    dl->AddLine(ImVec2(x, y + rh - c), ImVec2(x, y + rh), line, 2.f);
    dl->AddLine(ImVec2(x, y + rh), ImVec2(x + c, y + rh), line, 2.f);
    dl->AddLine(ImVec2(x + rw - c, y + rh), ImVec2(x + rw, y + rh), line, 2.f);
    dl->AddLine(ImVec2(x + rw, y + rh), ImVec2(x + rw, y + rh - c), line, 2.f);

    for (size_t i = 0; i < face.key_points.size(); ++i) {
      const bool visible =
          i >= face.visibility.size() || face.visibility[i] > 0.4f;
      if (!visible)
        continue;
      dl->AddCircleFilled(
          ImVec2(p0.x + face.key_points[i].x * w,
                 p0.y + face.key_points[i].y * h),
          1.6f, IM_COL32(255, 255, 255, 230));
    }

    char label[48];
    std::snprintf(label, sizeof(label), "Face_%02d %.1f%%", ++index,
                  face.score * 100.f);
    const ImVec2 ts = ImGui::CalcTextSize(label);
    const ImVec2 lp(x + rw * 0.5f - ts.x * 0.5f, y - 18.f);
    dl->AddRectFilled(ImVec2(lp.x - 6, lp.y - 2),
                      ImVec2(lp.x + ts.x + 6, lp.y + ts.y + 2),
                      IM_COL32(255, 255, 255, 230), 3.f);
    dl->AddText(lp, IM_COL32(17, 19, 23, 255), label);
  }
}

float PillWidth(const char* label) {
  return ImGui::CalcTextSize(label).x + ImGui::GetStyle().FramePadding.x * 2.f;
}

void DrawTopBar(Studio& studio) {
  ImGui::PushStyleColor(ImGuiCol_ChildBg, kTop);
  ImGui::PushStyleColor(ImGuiCol_Border, kBorder);
  ImGui::BeginChild("topbar", ImVec2(-1, 48), ImGuiChildFlags_Border,
                    ImGuiWindowFlags_NoScrollbar);
  ImGui::SetCursorPos(ImVec2(16, (48.f - kCtrlHeight) * 0.5f));
  ImGui::AlignTextToFramePadding();
  ImGui::TextUnformatted("Facebetter");
  ImGui::SameLine();
  ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 10.f);
  ImGui::PushStyleColor(ImGuiCol_Button, Rgba(24, 26, 32));
  ImGui::PushStyleColor(ImGuiCol_Border, ImVec4(1, 1, 1, 0.10f));
  ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 1.f);
  const ImVec2 demo_sz = LockedButtonSize("Demo", ImVec2(0, 0));
  PushBtnFont();
  ImGui::Button("Demo", demo_sz);
  PopBtnFont();
  ImGui::PopStyleVar(2);
  ImGui::PopStyleColor(2);

  ImGui::SameLine();
  ImGui::Dummy(ImVec2(8, 0));
  ImGui::SameLine();
  if (Pill(T("nav.replaceImage"), false)) {
    const std::string path = OpenImageDialog();
    if (!path.empty()) {
      studio.StopCamera();
      studio.LoadImageFile(path);
    }
  }
  ImGui::SameLine();
  if (Pill(T("nav.camera"), studio.IsCamera())) {
    if (studio.IsCamera())
      studio.StopCamera();
    else
      studio.StartCamera();
  }

  const float gap = 8.f;
  const float lang_w = 78.f;
  const float cluster =
      PillWidth(T("nav.website")) + gap + lang_w + gap +
      PillWidth(T("nav.export"));
  ImGui::SameLine();
  ImGui::Dummy(ImVec2(std::max(8.f, ImGui::GetContentRegionAvail().x - cluster - 16.f),
                      0));
  ImGui::SameLine();
  if (Pill(T("nav.website"), false))
    OpenUrl(SiteUrl());
  ImGui::SameLine(0, gap);
  ImGui::PushStyleVar(ImGuiStyleVar_ChildRounding, 14.f);
  ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(3, 3));
  ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(3, 0));
  ImGui::PushStyleColor(ImGuiCol_ChildBg, Rgba(24, 26, 32));
  ImGui::BeginChild("lang", ImVec2(lang_w, kCtrlHeight),
                    ImGuiChildFlags_Border |
                        ImGuiChildFlags_AlwaysUseWindowPadding,
                    ImGuiWindowFlags_NoScrollbar);
  const float lang_h = ImGui::GetContentRegionAvail().y;
  if (Chip(T("nav.langZh"), g_lang == Lang::Zh, ImVec2(32, lang_h)))
    g_lang = Lang::Zh;
  ImGui::SameLine(0, 3);
  if (Chip(T("nav.langEn"), g_lang == Lang::En, ImVec2(32, lang_h)))
    g_lang = Lang::En;
  ImGui::EndChild();
  ImGui::PopStyleColor();
  ImGui::PopStyleVar(3);

  ImGui::SameLine(0, gap);
  ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(1, 1, 1, 1));
  ImGui::PushStyleColor(ImGuiCol_ButtonHovered, Rgba(229, 231, 235));
  ImGui::PushStyleColor(ImGuiCol_Text, Rgba(10, 10, 10));
  ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 14.f);
  const ImVec2 export_sz = LockedButtonSize(T("nav.export"), ImVec2(0, 0));
  PushBtnFont();
  const bool export_clicked = ImGui::Button(T("nav.export"), export_sz);
  PopBtnFont();
  if (export_clicked) {
    const std::string path = SavePngDialog();
    if (!path.empty())
      studio.ExportPng(path);
  }
  ImGui::PopStyleVar();
  ImGui::PopStyleColor(3);

  ImGui::EndChild();
  ImGui::PopStyleColor(2);
}

void DrawViewport(Studio& studio) {
  ImGui::PushStyleColor(ImGuiCol_ChildBg, kBg);
  ImGui::BeginChild("viewport", ImVec2(-kInspectorWidth, 0),
                    ImGuiChildFlags_None, ImGuiWindowFlags_NoScrollbar);
  const ImVec2 avail = ImGui::GetContentRegionAvail();
  const GpuFrame& processed = studio.ProcessedGpu();
  const GpuFrame& original = studio.OriginalGpu();
  Params& p = studio.params();

  if (!studio.HasFrame()) {
    const ImVec2 ts = ImGui::CalcTextSize(T("preview.empty"));
    ImGui::SetCursorPos(ImVec2((avail.x - ts.x) * 0.5f, avail.y * 0.5f));
    ImGui::TextColored(kMuted, "%s", T("preview.empty"));
    ImGui::EndChild();
    ImGui::PopStyleColor();
    return;
  }

  const float scale = std::min(
      {1.f, avail.x / static_cast<float>(processed.width),
       avail.y / static_cast<float>(processed.height)});
  const ImVec2 img(processed.width * scale, processed.height * scale);
  const ImVec2 origin(ImGui::GetCursorScreenPos().x + (avail.x - img.x) * 0.5f,
                      ImGui::GetCursorScreenPos().y + (avail.y - img.y) * 0.5f);
  ImGui::SetCursorScreenPos(origin);
  ImGui::InvisibleButton("stage", img);
  const bool holding = ImGui::IsItemActive() && original.texture != 0;
  const unsigned int tex =
      holding && original.texture ? original.texture : processed.texture;
  ImDrawList* dl = ImGui::GetWindowDrawList();
  const ImVec2 p1(origin.x + img.x, origin.y + img.y);
  dl->AddRectFilled(origin, p1, IM_COL32(20, 22, 28, 255), 6.f);
  dl->AddImageRounded(TexId(tex), origin, p1, ImVec2(0, 0), ImVec2(1, 1),
                      IM_COL32_WHITE, 6.f);
  dl->AddRect(origin, p1, IM_COL32(35, 39, 49, 255), 6.f);

  if (p.face_overlay && !holding)
    DrawLandmarks(dl, origin, p1, studio.Faces());

  if (holding) {
    const char* tag = T("preview.original");
    const ImVec2 ts = ImGui::CalcTextSize(tag);
    dl->AddRectFilled(ImVec2(origin.x + 12, origin.y + 12),
                      ImVec2(origin.x + 24 + ts.x, origin.y + 32),
                      IM_COL32(14, 16, 20, 220), 6.f);
    dl->AddText(ImVec2(origin.x + 18, origin.y + 16), IM_COL32(220, 220, 220, 255),
                tag);
  }

  ImGui::SetCursorScreenPos(ImVec2(p1.x - 108, origin.y + 12));
  if (Pill(T("preview.keypoints"), p.face_overlay))
    p.face_overlay = !p.face_overlay;

  const char* hint = holding ? T("preview.release") : T("preview.hold");
  const ImVec2 hs = ImGui::CalcTextSize(hint);
  dl->AddRectFilled(
      ImVec2(origin.x + img.x * 0.5f - hs.x * 0.5f - 10, p1.y - 32),
      ImVec2(origin.x + img.x * 0.5f + hs.x * 0.5f + 10, p1.y - 12),
      IM_COL32(14, 16, 20, 210), 12.f);
  dl->AddText(ImVec2(origin.x + img.x * 0.5f - hs.x * 0.5f, p1.y - 30),
              IM_COL32(180, 180, 180, 255), hint);

  ImGui::EndChild();
  ImGui::PopStyleColor();
}

void DrawSkin(Studio& studio) {
  Params& p = studio.params();
  BeginCard("skin");
  CardTitle(T("skin.title"));
  ImGui::TextColored(kMuted, "%s", T("skin.skinOnly"));
  ImGui::SameLine(ImGui::GetContentRegionAvail().x - 20);
  if (Toggle("skinonly", &p.skin_only))
    studio.NotifyParamsChanged();
  ImGui::TextColored(kMuted, "%s", T("skin.smoothingStyle"));
  ImGui::SameLine(ImGui::GetWindowContentRegionMax().x -
                  ImGui::CalcTextSize(T("skin.reset")).x);
  ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0, 0, 0, 0));
  ImGui::PushStyleColor(ImGuiCol_Text, kMuted);
  const ImVec2 reset_sz = LockedButtonSize(T("skin.reset"), ImVec2(0, 0));
  PushBtnFont();
  const bool reset_skin = ImGui::Button(T("skin.reset"), reset_sz);
  PopBtnFont();
  if (reset_skin) {
    p.smoothing = p.whitening = p.rosiness = p.sharpening = 0.f;
    studio.NotifyParamsChanged();
  }
  ImGui::PopStyleColor(2);

  const SmoothingStyle styles[] = {
      SmoothingStyle::Texture, SmoothingStyle::Natural, SmoothingStyle::Smooth};
  const char* style_keys[] = {"smoothing.texture", "smoothing.natural",
                              "smoothing.smooth"};
  ChipGrid(3, 3, [&](int i, ImVec2 size) {
    if (Chip(T(style_keys[i]), p.smoothing_style == styles[i], size)) {
      p.smoothing_style = styles[i];
      studio.NotifyParamsChanged();
    }
  });
  if (ParamSlider(T("skin.smoothing"), &p.smoothing))
    studio.NotifyParamsChanged();

  ImGui::TextColored(kMuted, "%s", T("skin.whiteningTone"));
  const WhiteningStyle tones[] = {
      WhiteningStyle::ColdWhite, WhiteningStyle::PinkWhite,
      WhiteningStyle::WarmWhite, WhiteningStyle::Wheat, WhiteningStyle::Tan};
  const char* tone_keys[] = {"whitening.coldWhite", "whitening.pinkWhite",
                             "whitening.warmWhite", "whitening.wheat",
                             "whitening.tan"};
  ChipGrid(5, 5, [&](int i, ImVec2 size) {
    if (Chip(T(tone_keys[i]), p.whitening_style == tones[i], size)) {
      p.whitening_style = tones[i];
      studio.NotifyParamsChanged();
    }
  });
  if (ParamSlider(T("skin.whitening"), &p.whitening))
    studio.NotifyParamsChanged();
  if (ParamSlider(T("skin.rosiness"), &p.rosiness))
    studio.NotifyParamsChanged();
  if (ParamSlider(T("skin.sharpening"), &p.sharpening))
    studio.NotifyParamsChanged();
  EndCard();
}

void DrawReshape(Studio& studio) {
  Params& p = studio.params();
  struct Item {
    Reshape param;
    const char* key;
  };
  struct Group {
    const char* key;
    const Item* items;
    int count;
  };
  static const Item kFace[] = {
      {Reshape::FaceThin, "reshape.faceThin"},
      {Reshape::FaceNarrow, "reshape.faceNarrow"},
      {Reshape::FaceSmall, "reshape.faceSmall"},
      {Reshape::FaceShort, "reshape.faceShort"},
      {Reshape::FaceVShape, "reshape.faceVShape"},
      {Reshape::Cheekbone, "reshape.cheekbone"},
      {Reshape::Jawbone, "reshape.jawbone"},
      {Reshape::Chin, "reshape.chin"},
  };
  static const Item kBrow[] = {
      {Reshape::Forehead, "reshape.forehead"},
      {Reshape::BrowPosition, "reshape.browPosition"},
      {Reshape::BrowDistance, "reshape.browDistance"},
      {Reshape::BrowThickness, "reshape.browThickness"},
  };
  static const Item kEye[] = {
      {Reshape::EyeSize, "reshape.eyeSize"},
      {Reshape::EyeRound, "reshape.eyeRound"},
      {Reshape::EyeDistance, "reshape.eyeDistance"},
      {Reshape::EyePosition, "reshape.eyePosition"},
      {Reshape::EyeAngle, "reshape.eyeAngle"},
      {Reshape::EyeCornerOpen, "reshape.eyeCornerOpen"},
      {Reshape::LowerEyelid, "reshape.lowerEyelid"},
  };
  static const Item kNose[] = {
      {Reshape::NoseSlim, "reshape.noseSlim"},
      {Reshape::NoseLong, "reshape.noseLong"},
  };
  static const Item kMouth[] = {
      {Reshape::Philtrum, "reshape.philtrum"},
      {Reshape::MouthSize, "reshape.mouthSize"},
      {Reshape::MouthPosition, "reshape.mouthPosition"},
      {Reshape::MouthSmile, "reshape.mouthSmile"},
      {Reshape::LipThickness, "reshape.lipThickness"},
  };
  const Group groups[] = {
      {"reshape.face", kFace, 8}, {"reshape.brow", kBrow, 4},
      {"reshape.eye", kEye, 7},   {"reshape.nose", kNose, 2},
      {"reshape.mouth", kMouth, 5},
  };
  for (const Group& g : groups) {
    BeginCard(g.key);
    CardTitle(T(g.key));
    ImGui::PushID(g.key);
    for (int i = 0; i < g.count; ++i) {
      float& v = p.reshape[static_cast<size_t>(g.items[i].param)];
      if (BipolarSlider(T(g.items[i].key), &v))
        studio.NotifyParamsChanged();
    }
    ImGui::PopID();
    EndCard();
  }
}

template <typename StyleT, typename ColorT>
void MakeupBlock(Studio& studio,
                 const char* title,
                 float* intensity,
                 const StyleT* styles,
                 const char* const* style_keys,
                 int style_n,
                 StyleT* style_value,
                 const ColorT* colors,
                 const char* const* color_keys,
                 int color_n,
                 ColorT* color_value,
                 const char* style_label,
                 const char* color_label) {
  ImGui::PushID(title);
  ImGui::TextUnformatted(title);
  if (styles && style_n > 0) {
    ImGui::TextColored(kMuted, "%s", style_label);
    ChipGrid(style_n > 4 ? 4 : style_n, style_n, [&](int i, ImVec2 size) {
      if (Chip(T(style_keys[i]), *style_value == styles[i], size)) {
        *style_value = styles[i];
        studio.NotifyParamsChanged();
      }
    });
  }
  if (colors && color_n > 0) {
    ImGui::TextColored(kMuted, "%s", color_label);
    ChipGrid(color_n > 3 ? 3 : color_n, color_n, [&](int i, ImVec2 size) {
      if (Chip(T(color_keys[i]), *color_value == colors[i], size)) {
        *color_value = colors[i];
        studio.NotifyParamsChanged();
      }
    });
  }
  if (ParamSlider(T("makeup.intensity"), intensity))
    studio.NotifyParamsChanged();
  ImGui::Spacing();
  ImGui::Separator();
  ImGui::Spacing();
  ImGui::PopID();
}

void DrawMakeup(Studio& studio) {
  Params& p = studio.params();
  BeginCard("makeup");
  CardTitle(T("makeup.title"), T("makeup.fullSet"));
  const char* style_l = T("makeup.style");
  const char* color_l = T("makeup.color");

  static const LipstickColor kLipC[] = {
      LipstickColor::Rouge,       LipstickColor::RetroRed,
      LipstickColor::Peach,       LipstickColor::CoralOrange,
      LipstickColor::GentlePink,  LipstickColor::VitalityOrange};
  static const char* kLipCk[] = {
      "lipstick.rouge",        "lipstick.retroRed", "lipstick.peach",
      "lipstick.coralOrange",  "lipstick.gentlePink", "lipstick.vitalityOrange"};
  MakeupBlock(studio, T("makeup.lipstick"), &p.lipstick, static_cast<LipstickColor*>(nullptr),
              nullptr, 0, &p.lipstick_color, kLipC, kLipCk, 6, &p.lipstick_color,
              style_l, color_l);

  static const BlushStyle kBlushS[] = {
      BlushStyle::SunKissed, BlushStyle::Igari, BlushStyle::Soft,
      BlushStyle::Apple,     BlushStyle::Classic, BlushStyle::Doll,
      BlushStyle::Rose};
  static const char* kBlushSk[] = {
      "blush.sunKissed", "blush.igari", "blush.soft", "blush.apple",
      "blush.classic",   "blush.doll",  "blush.rose"};
  static const BlushColor kBlushC[] = {
      BlushColor::CoralPink, BlushColor::DustyRose, BlushColor::VividRed,
      BlushColor::Berry, BlushColor::SunsetOrange};
  static const char* kBlushCk[] = {
      "blushColor.coralPink", "blushColor.dustyRose", "blushColor.vividRed",
      "blushColor.berry", "blushColor.sunsetOrange"};
  MakeupBlock(studio, T("makeup.blush"), &p.blush, kBlushS, kBlushSk, 7,
              &p.blush_style, kBlushC, kBlushCk, 5, &p.blush_color, style_l,
              color_l);

  static const ContourStyle kConS[] = {
      ContourStyle::Natural, ContourStyle::Sculpt, ContourStyle::Glow,
      ContourStyle::Slim,    ContourStyle::Nose,   ContourStyle::Glam};
  static const char* kConSk[] = {"contour.natural", "contour.sculpt",
                                 "contour.glow",    "contour.slim",
                                 "contour.nose",    "contour.glam"};
  MakeupBlock(studio, T("makeup.contour"), &p.contour, kConS, kConSk, 6,
              &p.contour_style, static_cast<ContourStyle*>(nullptr), nullptr, 0,
              &p.contour_style, style_l, color_l);

  static const EyeShadowStyle kEsS[] = {
      EyeShadowStyle::Soft, EyeShadowStyle::Crease, EyeShadowStyle::Smoky,
      EyeShadowStyle::Halo, EyeShadowStyle::Glow,   EyeShadowStyle::Drama,
      EyeShadowStyle::Warm};
  static const char* kEsSk[] = {
      "eyeshadow.soft", "eyeshadow.crease", "eyeshadow.smoky", "eyeshadow.halo",
      "eyeshadow.glow", "eyeshadow.drama",  "eyeshadow.warm"};
  static const EyeShadowColor kEsC[] = {
      EyeShadowColor::Plum, EyeShadowColor::Brown, EyeShadowColor::Gold,
      EyeShadowColor::Pink};
  static const char* kEsCk[] = {"eyeshadowColor.plum", "eyeshadowColor.brown",
                                "eyeshadowColor.gold", "eyeshadowColor.pink"};
  MakeupBlock(studio, T("makeup.eyeshadow"), &p.eyeshadow, kEsS, kEsSk, 7,
              &p.eyeshadow_style, kEsC, kEsCk, 4, &p.eyeshadow_color, style_l,
              color_l);

  static const EyeLinerStyle kElS[] = {
      EyeLinerStyle::Classic, EyeLinerStyle::Flick, EyeLinerStyle::CatEye,
      EyeLinerStyle::Natural, EyeLinerStyle::Bold,  EyeLinerStyle::Soft};
  static const char* kElSk[] = {"eyeliner.classic", "eyeliner.flick",
                                "eyeliner.catEye",  "eyeliner.natural",
                                "eyeliner.bold",    "eyeliner.soft"};
  static const EyeLinerColor kElC[] = {
      EyeLinerColor::Burgundy, EyeLinerColor::Plum, EyeLinerColor::Chocolate,
      EyeLinerColor::Coffee, EyeLinerColor::Mauve};
  static const char* kElCk[] = {
      "eyelinerColor.burgundy", "eyelinerColor.plum", "eyelinerColor.chocolate",
      "eyelinerColor.coffee", "eyelinerColor.mauve"};
  MakeupBlock(studio, T("makeup.eyeliner"), &p.eyeliner, kElS, kElSk, 6,
              &p.eyeliner_style, kElC, kElCk, 5, &p.eyeliner_color, style_l,
              color_l);

  static const EyebrowStyle kEbS[] = {
      EyebrowStyle::Natural,   EyebrowStyle::Soft,     EyebrowStyle::Feathered,
      EyebrowStyle::Mist,      EyebrowStyle::Arched,   EyebrowStyle::Powder,
      EyebrowStyle::Wild,      EyebrowStyle::Full,     EyebrowStyle::Straight};
  static const char* kEbSk[] = {
      "eyebrow.natural", "eyebrow.soft",   "eyebrow.feathered",
      "eyebrow.mist",    "eyebrow.arched", "eyebrow.powder",
      "eyebrow.wild",    "eyebrow.full",   "eyebrow.straight"};
  static const EyebrowColor kEbC[] = {
      EyebrowColor::DarkBrown, EyebrowColor::Black, EyebrowColor::SoftBrown};
  static const char* kEbCk[] = {"eyebrowColor.darkBrown", "eyebrowColor.black",
                                "eyebrowColor.softBrown"};
  MakeupBlock(studio, T("makeup.eyebrow"), &p.eyebrow, kEbS, kEbSk, 9,
              &p.eyebrow_style, kEbC, kEbCk, 3, &p.eyebrow_color, style_l,
              color_l);

  static const EyelashStyle kLaS[] = {
      EyelashStyle::Classic, EyelashStyle::Manga,     EyelashStyle::Winged,
      EyelashStyle::Wispy,   EyelashStyle::Clustered, EyelashStyle::Doll};
  static const char* kLaSk[] = {"eyelash.classic",   "eyelash.manga",
                                "eyelash.winged",    "eyelash.wispy",
                                "eyelash.clustered", "eyelash.doll"};
  static const EyelashColor kLaC[] = {
      EyelashColor::Black, EyelashColor::Brown, EyelashColor::SoftBlack};
  static const char* kLaCk[] = {"eyelashColor.black", "eyelashColor.brown",
                                "eyelashColor.softBlack"};
  MakeupBlock(studio, T("makeup.eyelash"), &p.eyelash, kLaS, kLaSk, 6,
              &p.eyelash_style, kLaC, kLaCk, 3, &p.eyelash_color, style_l,
              color_l);

  static const PupilColor kPu[] = {
      PupilColor::Hazel, PupilColor::Ice,  PupilColor::Mocha,
      PupilColor::Olive, PupilColor::Gloss, PupilColor::Moss,
      PupilColor::Sand,  PupilColor::Glow, PupilColor::Slate};
  static const char* kPuk[] = {
      "pupil.hazel", "pupil.ice",  "pupil.mocha", "pupil.olive", "pupil.gloss",
      "pupil.moss",  "pupil.sand", "pupil.glow",  "pupil.slate"};
  MakeupBlock(studio, T("makeup.pupil"), &p.pupil, kPu, kPuk, 9, &p.pupil_color,
              static_cast<PupilColor*>(nullptr), nullptr, 0, &p.pupil_color,
              T("makeup.pupilColor"), color_l);
  EndCard();
}

void DrawFilter(Studio& studio) {
  Params& p = studio.params();
  const auto& filters = studio.Filters();
  BeginCard("filter");
  char extra[32];
  std::snprintf(extra, sizeof(extra), "%s %d%%", T("filter.intensity"),
                static_cast<int>(std::lround(p.filter_intensity * 100)));
  CardTitle(T("filter.title"), extra);
  const int n = static_cast<int>(filters.size()) + 1;
  ChipGrid(3, n, [&](int i, ImVec2 size) {
    if (i == 0) {
      if (Chip(T("filter.none"), p.filter_id.empty(), size)) {
        p.filter_id.clear();
        studio.NotifyParamsChanged();
      }
      return;
    }
    const Asset& a = filters[static_cast<size_t>(i - 1)];
    if (Chip(FilterLabel(a.id), p.filter_id == a.id, size)) {
      p.filter_id = a.id;
      studio.NotifyParamsChanged();
    }
  });
  if (ParamSlider(T("filter.intensity"), &p.filter_intensity))
    studio.NotifyParamsChanged();
  EndCard();
}

void DrawSticker(Studio& studio) {
  Params& p = studio.params();
  const auto& stickers = studio.Stickers();
  BeginCard("sticker");
  CardTitle(T("sticker.title"));
  const int n = static_cast<int>(stickers.size()) + 1;
  ChipGrid(3, n, [&](int i, ImVec2 size) {
    if (i == 0) {
      if (Chip(T("sticker.none"), p.sticker_id.empty(), size)) {
        p.sticker_id.clear();
        studio.NotifyParamsChanged();
      }
      return;
    }
    const Asset& a = stickers[static_cast<size_t>(i - 1)];
    if (Chip(StickerLabel(a.id), p.sticker_id == a.id, size)) {
      p.sticker_id = a.id;
      studio.NotifyParamsChanged();
    }
  });
  EndCard();
}

void DrawBackground(Studio& studio) {
  Params& p = studio.params();
  BeginCard("bg");
  CardTitle(T("bg.title"));
  ImGui::TextColored(kMuted, "%s", T("bg.effect"));
  const BgFill fills[] = {BgFill::Off, BgFill::Blur, BgFill::Preset};
  const char* fill_keys[] = {"bg.original", "bg.blur", "bg.preset"};
  ChipGrid(3, 3, [&](int i, ImVec2 size) {
    if (Chip(T(fill_keys[i]), p.bg_fill == fills[i], size)) {
      p.bg_fill = fills[i];
      if (p.bg_fill == BgFill::Blur && p.bg_blur <= 0.f)
        p.bg_blur = 0.5f;
      studio.NotifyParamsChanged();
    }
  });
  if (p.bg_fill == BgFill::Blur &&
      ParamSlider(T("bg.blurAmount"), &p.bg_blur)) {
    studio.NotifyParamsChanged();
  }
  ImGui::TextColored(kMuted, "%s", T("bg.cutout"));
  const char* chroma_keys[] = {"bg.portrait", "bg.green", "bg.blue", "bg.red"};
  ChipGrid(4, 4, [&](int i, ImVec2 size) {
    if (Chip(T(chroma_keys[i]), p.chroma == i, size)) {
      p.chroma = i;
      studio.NotifyParamsChanged();
    }
  });
  if (p.chroma > 0) {
    if (ParamSlider(T("bg.similarity"), &p.chroma_similarity))
      studio.NotifyParamsChanged();
    if (ParamSlider(T("bg.smoothness"), &p.chroma_smoothness))
      studio.NotifyParamsChanged();
    if (ParamSlider(T("bg.desaturation"), &p.chroma_desaturation))
      studio.NotifyParamsChanged();
  }
  EndCard();
}

void DrawInspector(Studio& studio) {
  ImGui::PushStyleColor(ImGuiCol_ChildBg, kPanel);
  ImGui::PushStyleColor(ImGuiCol_Border, kBorder);
  ImGui::BeginChild("inspector", ImVec2(kInspectorWidth, 0),
                    ImGuiChildFlags_Border);

  ImGui::BeginChild("ins_head", ImVec2(-1, 44), ImGuiChildFlags_None);
  ImGui::SetCursorPosY(12);
  ImGui::TextUnformatted(T("console.title"));
  const auto stats = studio.Stats();
  char live[48];
  std::snprintf(live, sizeof(live), "%.0f FPS  %.1f ms", stats.fps,
                stats.avg_process_time_ms);
  ImGui::SameLine(ImGui::GetWindowContentRegionMax().x -
                  ImGui::CalcTextSize(live).x);
  ImGui::TextColored(kMuted, "%s", live);
  ImGui::EndChild();

  const char* tabs[] = {"tab.skin", "tab.reshape", "tab.makeup",
                        "tab.filter", "tab.sticker", "tab.background"};
  const char* tab_icons[] = {kIconFace, kIconReshape, kIconMakeup,
                             kIconFilter, kIconSticker, kIconBackground};
  ImGui::PushStyleColor(ImGuiCol_ChildBg, Rgba(20, 22, 28));
  ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(8, 6));
  ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(4, 4));
  ImGui::BeginChild("tabs", ImVec2(-1, kTabBarHeight),
                    ImGuiChildFlags_AlwaysUseWindowPadding);
  const float tab_w =
      (ImGui::GetContentRegionAvail().x - ImGui::GetStyle().ItemSpacing.x * 5.f) /
      6.f;
  const float tab_h = ImGui::GetContentRegionAvail().y;
  for (int i = 0; i < 6; ++i) {
    if (i != 0)
      ImGui::SameLine();
    ImGui::PushID(i);
    if (IconTab(tab_icons[i], T(tabs[i]), g_tab == i, ImVec2(tab_w, tab_h)))
      g_tab = i;
    ImGui::PopID();
  }
  ImGui::EndChild();
  ImGui::PopStyleVar(2);
  ImGui::PopStyleColor();

  ImGui::BeginChild("ins_body", ImVec2(-1, -52), ImGuiChildFlags_None);
  ImGui::Dummy(ImVec2(0, 8));
  if (g_tab == 0)
    DrawSkin(studio);
  else if (g_tab == 1)
    DrawReshape(studio);
  else if (g_tab == 2)
    DrawMakeup(studio);
  else if (g_tab == 3)
    DrawFilter(studio);
  else if (g_tab == 4)
    DrawSticker(studio);
  else
    DrawBackground(studio);
  ImGui::EndChild();

  ImGui::BeginChild("ins_foot", ImVec2(-1, 0), ImGuiChildFlags_None);
  ImGui::SetCursorPosY(10);
  if (Pill(T("console.reset"), false))
    studio.ResetParams();
  ImGui::EndChild();

  ImGui::EndChild();
  ImGui::PopStyleColor(2);
}

}  // namespace

void ApplyStudioTheme() {
  ImGui::StyleColorsDark();
  ImGuiStyle& s = ImGui::GetStyle();
  s.WindowRounding = 0.f;
  s.ChildRounding = 10.f;
  s.FrameRounding = 8.f;
  s.GrabRounding = 8.f;
  s.GrabMinSize = 14.f;
  s.ScrollbarRounding = 6.f;
  s.WindowPadding = ImVec2(0, 0);
  s.FramePadding = ImVec2(12, 6);
  s.ItemSpacing = ImVec2(8, 8);
  s.ScrollbarSize = 6.f;
  s.WindowBorderSize = 0.f;
  s.ChildBorderSize = 1.f;
  s.FrameBorderSize = 0.f;
  s.ButtonTextAlign = ImVec2(0.5f, 0.5f);
  s.AntiAliasedLines = true;
  s.AntiAliasedFill = true;
  s.CircleTessellationMaxError = 0.12f;

  ImVec4* c = s.Colors;
  c[ImGuiCol_WindowBg] = kBg;
  c[ImGuiCol_ChildBg] = kPanel;
  c[ImGuiCol_Border] = kBorder;
  c[ImGuiCol_Text] = kText;
  c[ImGuiCol_TextDisabled] = kMuted;
  c[ImGuiCol_FrameBg] = Rgba(37, 40, 48);
  c[ImGuiCol_FrameBgHovered] = Rgba(50, 54, 64);
  c[ImGuiCol_FrameBgActive] = Rgba(60, 64, 76);
  c[ImGuiCol_SliderGrab] = ImVec4(1, 1, 1, 1);
  c[ImGuiCol_SliderGrabActive] = Rgba(229, 231, 235);
  c[ImGuiCol_Button] = kChip;
  c[ImGuiCol_ButtonHovered] = Rgba(40, 45, 56);
  c[ImGuiCol_ButtonActive] = Rgba(50, 55, 68);
  c[ImGuiCol_Header] = kChip;
  c[ImGuiCol_HeaderHovered] = Rgba(40, 45, 56);
  c[ImGuiCol_HeaderActive] = Rgba(50, 55, 68);
  c[ImGuiCol_ScrollbarBg] = kBg;
  c[ImGuiCol_ScrollbarGrab] = Rgba(31, 34, 41);
  c[ImGuiCol_Separator] = kBorder;
}

void LoadStudioFonts(float dpi_scale) {
  if (dpi_scale < 1.f)
    dpi_scale = 1.f;
  ImGuiIO& io = ImGui::GetIO();
  const char* candidates[] = {
#ifdef __APPLE__
      "/System/Library/Fonts/Hiragino Sans GB.ttc",
      "/System/Library/Fonts/STHeiti Light.ttc",
      "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
#elif defined(_WIN32)
      "C:\\Windows\\Fonts\\msyh.ttc",
      "C:\\Windows\\Fonts\\msyh.ttf",
      "C:\\Windows\\Fonts\\segoeui.ttf",
#else
      "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
      "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
#endif
  };
  ImFontConfig cfg;
  cfg.OversampleH = dpi_scale >= 1.5f ? 1 : 2;
  cfg.OversampleV = dpi_scale >= 1.5f ? 1 : 2;
  cfg.PixelSnapH = false;
  // 按物理像素栅格化，再用 FontGlobalScale 缩回逻辑尺寸，Retina 上才不会发糊。
  cfg.GlyphOffset = ImVec2(0.f, -1.1f * dpi_scale);
  ImFontGlyphRangesBuilder builder;
  builder.AddRanges(io.Fonts->GetGlyphRangesDefault());
  ForEachI18nText([&](const char* text) { builder.AddText(text); });
  builder.AddText("Facebetter Demo 0123456789%._-");
  // AddFontFromFileTTF 只保存指针，图集要到 NewFrame 才构建，ranges 必须活过这次调用。
  static ImVector<ImWchar> ranges;
  ranges.clear();
  builder.BuildRanges(&ranges);
  bool loaded = false;
  for (const char* path : candidates) {
    if (!io.Fonts->AddFontFromFileTTF(path, kUiFontPx * dpi_scale, &cfg,
                                      ranges.Data)) {
      continue;
    }
    ImFontConfig btn_cfg = cfg;
    btn_cfg.GlyphOffset = ImVec2(0.f, -1.0f * dpi_scale);
    g_btn_font = io.Fonts->AddFontFromFileTTF(path, kBtnFontPx * dpi_scale,
                                             &btn_cfg, ranges.Data);
    loaded = true;
    break;
  }
  if (!loaded)
    io.Fonts->AddFontDefault();
#ifdef FB_DEMO_ICON_FONT
  {
    ImFontConfig icon_cfg;
    icon_cfg.OversampleH = dpi_scale >= 1.5f ? 1 : 2;
    icon_cfg.OversampleV = dpi_scale >= 1.5f ? 1 : 2;
    icon_cfg.PixelSnapH = true;
    static const ImWchar icon_ranges[] = {
        0xE3A5, 0xE3A5, 0xE3AE, 0xE3AE, 0xE40A, 0xE40A,
        0xE65F, 0xE65F, 0xE87C, 0xE87C, 0xE92C, 0xE92C, 0};
    g_icon_font = io.Fonts->AddFontFromFileTTF(
        FB_DEMO_ICON_FONT, kIconFontPx * dpi_scale, &icon_cfg, icon_ranges);
  }
#endif
  io.FontGlobalScale = 1.f / dpi_scale;
}

void DrawStudio(Studio& studio, GLFWwindow*) {
  const ImGuiViewport* vp = ImGui::GetMainViewport();
  ImGui::SetNextWindowPos(vp->WorkPos);
  ImGui::SetNextWindowSize(vp->WorkSize);
  ImGui::Begin("studio", nullptr,
               ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
                   ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoCollapse |
                   ImGuiWindowFlags_NoBringToFrontOnFocus |
                   ImGuiWindowFlags_NoNavFocus | ImGuiWindowFlags_NoScrollbar |
                   ImGuiWindowFlags_NoScrollWithMouse);

  DrawTopBar(studio);
  ImGui::BeginChild("body", ImVec2(0, 0), ImGuiChildFlags_None,
                    ImGuiWindowFlags_NoScrollbar);
  DrawViewport(studio);
  ImGui::SameLine(0, 0);
  DrawInspector(studio);
  ImGui::EndChild();

  const std::string status = studio.Status();
  if (!status.empty()) {
    const char* text = T(status.c_str());
    ImDrawList* dl = ImGui::GetForegroundDrawList();
    const ImVec2 ts = ImGui::CalcTextSize(text);
    const ImVec2 p(vp->WorkPos.x + 24, vp->WorkPos.y + vp->WorkSize.y - 48);
    dl->AddRectFilled(p, ImVec2(p.x + ts.x + 24, p.y + 28),
                      IM_COL32(24, 26, 32, 230), 8.f);
    dl->AddRect(p, ImVec2(p.x + ts.x + 24, p.y + 28),
                IM_COL32(255, 255, 255, 24), 8.f);
    dl->AddText(ImVec2(p.x + 12, p.y + 6), IM_COL32(230, 230, 230, 255), text);
  }

  ImGui::End();
}

}  // namespace demo
