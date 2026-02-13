package net.pixpark.fbexample;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Log;
import android.widget.Toast;
import net.pixpark.facebetter.ImageFrame;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** Saves ImageFrame to file and gallery; callbacks may run on background thread. */
public final class CaptureFrameSaver {
  private static final String TAG = "CaptureFrameSaver";
  private static final String FILE_PREFIX = "FBExample_";
  private static final String FILE_SUFFIX = ".jpg";
  private static final int JPEG_QUALITY = 90;

  public interface SaveResultListener {
    void onSuccess();

    void onFailure();
  }

  /** Writes frame to temp file then copies to MediaStore on background thread. */
  public static void save(ImageFrame frame, Context context, SaveResultListener listener) {
    if (frame == null || context == null || listener == null) {
      if (listener != null) listener.onFailure();
      return;
    }

    String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date());
    String fileName = FILE_PREFIX + timeStamp + FILE_SUFFIX;
    File tempFile = new File(context.getCacheDir(), fileName);
    int result = frame.toFile(tempFile.getAbsolutePath(), JPEG_QUALITY);
    if (result != 0 || !tempFile.exists()) {
      Log.e(TAG, "ImageFrame.toFile failed or file not created, result=" + result);
      listener.onFailure();
      return;
    }

    String tempPath = tempFile.getAbsolutePath();
    new Thread(() -> {
      boolean ok = addFileToGallery(context, tempPath, fileName);
      if (!tempFile.delete()) {
        tempFile.deleteOnExit();
      }
      if (ok) {
        listener.onSuccess();
      } else {
        listener.onFailure();
      }
    }).start();
  }

  private static boolean addFileToGallery(Context context, String tempFilePath, String displayName) {
    File tempFile = new File(tempFilePath);
    if (!tempFile.exists()) {
      return false;
    }
    ContentResolver resolver = context.getContentResolver();
    ContentValues values = new ContentValues();
    values.put(MediaStore.Images.Media.DISPLAY_NAME, displayName);
    values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
    Uri uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
    if (uri == null) {
      Log.e(TAG, "Failed to create image URI");
      return false;
    }
    try (FileInputStream fis = new FileInputStream(tempFile);
         OutputStream os = resolver.openOutputStream(uri)) {
      if (os != null) {
        byte[] buf = new byte[8192];
        int len;
        while ((len = fis.read(buf)) > 0) {
          os.write(buf, 0, len);
        }
        os.flush();
      }
      return true;
    } catch (IOException e) {
      Log.e(TAG, "Error copying image to gallery", e);
      return false;
    }
  }

  /** Show save success/failure toast (call from UI thread, e.g. in listener). */
  public static void showSaveResultToast(Context context, boolean success) {
    if (context == null) return;
    int resId = success ? R.string.image_saved_to_gallery : R.string.failed_to_save_image;
    Toast.makeText(context, context.getString(resId), Toast.LENGTH_SHORT).show();
  }

  private CaptureFrameSaver() {}
}
