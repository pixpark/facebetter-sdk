//! Facebetter Demo Tauri 壳：仅加载 ../react 的构建产物，无业务逻辑。

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .build(tauri::generate_context!())
        .expect("error while building Tauri application")
        .run(|_app_handle, _event| {});
}
