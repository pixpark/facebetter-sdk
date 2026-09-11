#pragma once

#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <string>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <commdlg.h>
#include <shellapi.h>
#include <windows.h>
#else
#include <array>
#endif

// Native file dialogs and URL open. GLFW has neither; keep this header-only so
// the demo stays a handful of files.

inline std::string DefaultExportName() {
  const std::time_t now = std::time(nullptr);
  std::tm local{};
#ifdef _WIN32
  localtime_s(&local, &now);
#else
  localtime_r(&now, &local);
#endif
  char buf[40];
  std::snprintf(buf, sizeof(buf), "fb_%04d%02d%02d_%02d%02d%02d.png",
                local.tm_year + 1900, local.tm_mon + 1, local.tm_mday,
                local.tm_hour, local.tm_min, local.tm_sec);
  return buf;
}

#ifdef _WIN32

inline std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty())
    return {};
  const int n = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  std::wstring out(static_cast<size_t>(n), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, out.data(), n);
  if (!out.empty() && out.back() == L'\0')
    out.pop_back();
  return out;
}

inline std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty())
    return {};
  const int n =
      WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
  std::string out(static_cast<size_t>(n), '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, out.data(), n, nullptr, nullptr);
  if (!out.empty() && out.back() == '\0')
    out.pop_back();
  return out;
}

inline std::string OpenImageDialog() {
  wchar_t file[MAX_PATH] = {};
  OPENFILENAMEW ofn{};
  ofn.lStructSize = sizeof(ofn);
  ofn.lpstrFilter =
      L"Images\0*.png;*.jpg;*.jpeg;*.bmp;*.webp;*.tif;*.tiff\0All\0*.*\0";
  ofn.lpstrFile = file;
  ofn.nMaxFile = MAX_PATH;
  ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_EXPLORER;
  if (!GetOpenFileNameW(&ofn))
    return {};
  return WideToUtf8(file);
}

inline std::string SavePngDialog() {
  std::wstring name = Utf8ToWide(DefaultExportName());
  wchar_t file[MAX_PATH] = {};
  wcsncpy_s(file, name.c_str(), _TRUNCATE);
  OPENFILENAMEW ofn{};
  ofn.lStructSize = sizeof(ofn);
  ofn.lpstrFilter = L"PNG\0*.png\0";
  ofn.lpstrFile = file;
  ofn.nMaxFile = MAX_PATH;
  ofn.lpstrDefExt = L"png";
  ofn.Flags = OFN_OVERWRITEPROMPT | OFN_EXPLORER;
  if (!GetSaveFileNameW(&ofn))
    return {};
  return WideToUtf8(file);
}

inline void OpenUrl(const std::string& url) {
  ShellExecuteW(nullptr, L"open", Utf8ToWide(url).c_str(), nullptr, nullptr,
                SW_SHOWNORMAL);
}

#else

inline std::string TrimCopy(std::string s) {
  while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' '))
    s.pop_back();
  return s;
}

inline std::string RunPipe(const std::string& cmd) {
  FILE* pipe = popen(cmd.c_str(), "r");
  if (!pipe)
    return {};
  std::string out;
  std::array<char, 512> buf{};
  while (fgets(buf.data(), static_cast<int>(buf.size()), pipe))
    out += buf.data();
  pclose(pipe);
  return TrimCopy(out);
}

#ifdef __APPLE__

inline std::string OpenImageDialog() {
  return RunPipe(
      "osascript -e "
      "'try\nPOSIX path of (choose file of type {\"public.image\"} "
      "with prompt \"Open Image\")\nend try'");
}

inline std::string SavePngDialog() {
  const std::string name = DefaultExportName();
  const std::string cmd =
      "osascript -e 'try\nPOSIX path of (choose file name with prompt "
      "\"Export\" default name \"" +
      name + "\")\nend try'";
  std::string path = RunPipe(cmd);
  if (!path.empty() && path.size() < 4)
    return {};
  if (!path.empty() && path.find(".png") == std::string::npos &&
      path.find(".PNG") == std::string::npos) {
    path += ".png";
  }
  return path;
}

inline void OpenUrl(const std::string& url) {
  const std::string cmd = "open \"" + url + "\"";
  std::system(cmd.c_str());
}

#else

inline std::string OpenImageDialog() {
  std::string path = RunPipe(
      "zenity --file-selection --title='Open Image' "
      "--file-filter='Images | *.png *.jpg *.jpeg *.bmp *.webp *.tif' "
      "2>/dev/null");
  if (path.empty()) {
    path = RunPipe(
        "kdialog --getopenfilename . "
        "'*.png *.jpg *.jpeg *.bmp *.webp' 2>/dev/null");
  }
  return path;
}

inline std::string SavePngDialog() {
  const std::string name = DefaultExportName();
  std::string path = RunPipe(
      "zenity --file-selection --save --confirm-overwrite --title='Export' "
      "--filename='" +
      name + "' 2>/dev/null");
  if (path.empty()) {
    path = RunPipe("kdialog --getsavefilename '" + name + "' '*.png' 2>/dev/null");
  }
  if (!path.empty() && path.find(".png") == std::string::npos &&
      path.find(".PNG") == std::string::npos) {
    path += ".png";
  }
  return path;
}

inline void OpenUrl(const std::string& url) {
  const std::string cmd = "xdg-open \"" + url + "\" >/dev/null 2>&1 &";
  std::system(cmd.c_str());
}

#endif
#endif
