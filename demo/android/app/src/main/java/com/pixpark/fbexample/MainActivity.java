package com.pixpark.fbexample;

import android.content.Intent;
import android.os.Bundle;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
  private String currentLanguage;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // Apply language settings (must be before setContentView)
    LanguageHelper.applyLanguage(this);
    super.onCreate(savedInstanceState);
    EdgeToEdge.enable(this);
    setContentView(R.layout.activity_home);

    // Save current language
    currentLanguage = LanguageHelper.getLanguage(this);

    setupClickListeners();
  }

  @Override
  protected void onResume() {
    super.onResume();
    // Check if language has changed
    String newLanguage = LanguageHelper.getLanguage(this);
    if (currentLanguage != null && !currentLanguage.equals(newLanguage)) {
      // Language changed, recreate Activity to apply new language
      currentLanguage = newLanguage;
      recreate();
    }
  }

  private void setupClickListeners() {
    // Beauty Effect button - Navigate to beauty camera (without auto-opening panel)
    findViewById(R.id.btn_beauty_effect).setOnClickListener(v -> {
      Intent intent = new Intent(MainActivity.this, BeautyActivity.class);
      // Don't pass initial_tab, let user click to open panel
      startActivity(intent);
    });

    // Feature grid buttons
    // Beauty button - Navigate to beauty camera (Beauty Tab)
    findViewById(R.id.btn_beauty).setOnClickListener(v -> { navigateToCamera("beauty"); });

    // Reshape button - Navigate to beauty camera (Reshape Tab)
    findViewById(R.id.btn_reshape).setOnClickListener(v -> { navigateToCamera("reshape"); });

    // Makeup button - Navigate to beauty camera (Makeup Tab)
    findViewById(R.id.btn_makeup).setOnClickListener(v -> { navigateToCamera("makeup"); });

    // Filter button - Navigate to beauty camera (Filter Tab)
    findViewById(R.id.btn_filter).setOnClickListener(v -> { navigateToCamera("filter"); });

    // Sticker button - Navigate to beauty camera (Sticker Tab)
    findViewById(R.id.btn_sticker).setOnClickListener(v -> { navigateToCamera("sticker"); });

    // Body button - Under development
    findViewById(R.id.btn_body).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.body_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    // Virtual Background button - Navigate to beauty camera (Virtual Background Tab)
    findViewById(R.id.btn_virtual_bg).setOnClickListener(v -> { navigateToCamera("virtual_bg"); });

    // Quality button - Under development
    findViewById(R.id.btn_quality).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.quality_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    // Other incomplete feature buttons - Show under development message
    findViewById(R.id.btn_beauty_template).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.beauty_template_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    findViewById(R.id.btn_green_screen).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.green_screen_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    findViewById(R.id.btn_gesture_detect).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.gesture_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    findViewById(R.id.btn_style).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.style_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    findViewById(R.id.btn_hair_color).setOnClickListener(v -> {
      android.widget.Toast
          .makeText(this, getString(R.string.hair_color_under_development), android.widget.Toast.LENGTH_SHORT)
          .show();
    });

    findViewById(R.id.btn_settings).setOnClickListener(v -> {
      // Open language settings page
      try {
        Intent intent = new Intent(MainActivity.this, LanguageSettingsActivity.class);
        startActivity(intent);
      } catch (Exception e) {
        android.util.Log.e("MainActivity", "Failed to open LanguageSettingsActivity", e);
        android.widget.Toast.makeText(this, "Failed to open settings: " + e.getMessage(), 
            android.widget.Toast.LENGTH_SHORT).show();
      }
    });

    // External Texture button - Navigate to external texture demo
    findViewById(R.id.btn_external_texture).setOnClickListener(v -> {
      Intent intent = new Intent(MainActivity.this, ExternalTextureActivity.class);
      startActivity(intent);
    });
  }

  /**
   * Navigate to beauty camera interface
   * @param tab Tab to switch to:
   *            "beauty", "reshape", "makeup",
   *            "filter", "sticker", "body",
   *            "virtual_bg", "quality"
   */
  private void navigateToCamera(String tab) {
    Intent intent = new Intent(MainActivity.this, BeautyActivity.class);
    intent.putExtra("initial_tab", tab);
    startActivity(intent);
  }
}
