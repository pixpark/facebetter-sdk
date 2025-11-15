package com.pixpark.fbexample;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

public class HomeActivity extends AppCompatActivity {

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_home);

    setupClickListeners();
  }

  private void setupClickListeners() {
    // 美颜特效大按钮 - 跳转到美颜相机界面（不自动打开面板）
    findViewById(R.id.btn_beauty_effect).setOnClickListener(v -> {
      Intent intent = new Intent(HomeActivity.this, MainActivity.class);
      // 不传递 initial_tab，让用户自己点击打开面板
      startActivity(intent);
    });

    // 功能网格按钮
    // 美颜按钮 - 跳转到美颜相机界面（美颜 Tab）
    findViewById(R.id.btn_beauty).setOnClickListener(v -> {
      navigateToCamera("beauty");
    });

    // 美型按钮 - 跳转到美颜相机界面（美型 Tab）
    findViewById(R.id.btn_reshape).setOnClickListener(v -> {
      navigateToCamera("reshape");
    });

    // 美妆按钮 - 跳转到美颜相机界面（美妆 Tab）
    findViewById(R.id.btn_makeup).setOnClickListener(v -> {
      navigateToCamera("makeup");
    });

    // 滤镜按钮 - 开发中
    findViewById(R.id.btn_filter).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "滤镜功能开发中，敬请期待 🎨", android.widget.Toast.LENGTH_SHORT).show();
    });

    // 贴纸按钮 - 开发中
    findViewById(R.id.btn_sticker).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "贴纸功能开发中，敬请期待 😊", android.widget.Toast.LENGTH_SHORT).show();
    });

    // 美体按钮 - 开发中
    findViewById(R.id.btn_body).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "美体功能开发中，敬请期待 🏃", android.widget.Toast.LENGTH_SHORT).show();
    });

    // 虚拟背景按钮 - 跳转到美颜相机界面（虚拟背景 Tab）
    findViewById(R.id.btn_virtual_bg).setOnClickListener(v -> {
      navigateToCamera("virtual_bg");
    });

    // 画质按钮 - 开发中
    findViewById(R.id.btn_quality).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "画质调整功能开发中，敬请期待 📸", android.widget.Toast.LENGTH_SHORT).show();
    });

    // 其他未完成功能按钮 - 显示开发中提示
    findViewById(R.id.btn_beauty_template).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "美颜模板功能开发中，敬请期待 ✨", android.widget.Toast.LENGTH_SHORT).show();
    });

    findViewById(R.id.btn_green_screen).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "绿幕抠图功能开发中，敬请期待 🎬", android.widget.Toast.LENGTH_SHORT).show();
    });

    findViewById(R.id.btn_gesture_detect).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "手势识别功能开发中，敬请期待 👋", android.widget.Toast.LENGTH_SHORT).show();
    });

    findViewById(R.id.btn_style).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "风格化功能开发中，敬请期待 🎭", android.widget.Toast.LENGTH_SHORT).show();
    });

    findViewById(R.id.btn_hair_color).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "染发功能开发中，敬请期待 💇", android.widget.Toast.LENGTH_SHORT).show();
    });

    findViewById(R.id.btn_settings).setOnClickListener(v -> {
      android.widget.Toast.makeText(this, "设置功能开发中，敬请期待 ⚙️", android.widget.Toast.LENGTH_SHORT).show();
    });
  }

  /**
   * 跳转到美颜相机界面
   * @param tab 要切换到的 Tab:
   *            "beauty"(美颜), "reshape"(美型), "makeup"(美妆),
   *            "filter"(滤镜), "sticker"(贴纸), "body"(美体),
   *            "virtual_bg"(虚拟背景), "quality"(画质调整)
   */
  private void navigateToCamera(String tab) {
    Intent intent = new Intent(HomeActivity.this, MainActivity.class);
    intent.putExtra("initial_tab", tab);
    startActivity(intent);
  }
}

