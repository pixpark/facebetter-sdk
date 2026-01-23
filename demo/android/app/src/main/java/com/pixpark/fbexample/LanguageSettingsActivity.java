package com.pixpark.fbexample;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

public class LanguageSettingsActivity extends AppCompatActivity {
  private ListView languageListView;
  private String[] languageOptions;
  private String[] languageCodes;
  private String currentLanguage;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // Apply language settings (must be before setContentView)
    LanguageHelper.applyLanguage(this);
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_language_settings);

    // Setup Toolbar
    Toolbar toolbar = findViewById(R.id.toolbar);
    setSupportActionBar(toolbar);
    if (getSupportActionBar() != null) {
      getSupportActionBar().setDisplayHomeAsUpEnabled(true);
      getSupportActionBar().setTitle(getString(R.string.language_settings));
    }
    toolbar.setNavigationOnClickListener(v -> finish());

    // Initialize language options
    languageOptions = new String[] {
        getString(R.string.language_auto),
        getString(R.string.language_english),
        getString(R.string.language_chinese)
    };
    languageCodes = new String[] {
        LanguageHelper.LANGUAGE_AUTO,
        LanguageHelper.LANGUAGE_EN,
        LanguageHelper.LANGUAGE_ZH
    };

    currentLanguage = LanguageHelper.getLanguage(this);

    // Setup list
    languageListView = findViewById(R.id.language_list);
    ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_single_choice, languageOptions);
    languageListView.setAdapter(adapter);
    languageListView.setChoiceMode(ListView.CHOICE_MODE_SINGLE);

    // Set currently selected language
    int selectedIndex = 0;
    for (int i = 0; i < languageCodes.length; i++) {
      if (languageCodes[i].equals(currentLanguage)) {
        selectedIndex = i;
        break;
      }
    }
    languageListView.setItemChecked(selectedIndex, true);

    // Setup click event
    languageListView.setOnItemClickListener((parent, view, position, id) -> {
      String selectedLanguageCode = languageCodes[position];
      if (!selectedLanguageCode.equals(currentLanguage)) {
        // Save language settings
        LanguageHelper.setLanguage(this, selectedLanguageCode);
        currentLanguage = selectedLanguageCode;

        // Reapply language settings and restart Activity to apply new language
        recreate();
      }
    });
  }
}
