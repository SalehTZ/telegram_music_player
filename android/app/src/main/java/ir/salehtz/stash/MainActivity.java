package ir.salehtz.stash;

import android.Manifest;
import android.app.PendingIntent;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.provider.Settings;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.ryanheise.audioservice.AudioServiceActivity;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * The media library and file access behind lib/src/data/library/device_music_library.dart.
 */
public class MainActivity extends AudioServiceActivity {
    private static final int REQUEST_PERMISSION = 1;
    private static final int REQUEST_WRITE = 2;

    // A few threads, so covers keep loading while a song is saved
    private final ExecutorService worker = Executors.newFixedThreadPool(3);
    private final Handler main = new Handler(Looper.getMainLooper());
    private MethodChannel channel;
    private MethodChannel.Result permissionResult;
    private MethodChannel.Result writeResult;

    // Songs shared to Stash, until the Dart side takes them
    private final List<String> imported = new ArrayList<>();
    private int importFailures = 0;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine engine) {
        super.configureFlutterEngine(engine);
        channel = new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "ir.salehtz.stash/files");
        channel.setMethodCallHandler(this::onMethodCall);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState == null) importShared(getIntent());
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        importShared(intent);
    }

    private void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "hasPermission":
                result.success(hasPermission());
                break;
            case "requestPermission":
                if (hasPermission()) {
                    result.success("granted");
                } else {
                    permissionResult = result;
                    ActivityCompat.requestPermissions(this, readPermissions(), REQUEST_PERMISSION);
                }
                break;
            case "openSettings":
                startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", getPackageName(), null)));
                result.success(null);
                break;
            case "songs":
                inBackground(result, this::querySongs);
                break;
            case "artwork":
                Number id = call.argument("id");
                inBackground(result, () -> artwork(id.longValue(), call.argument("path"), call.argument("size")));
                break;
            case "requestWriteAccess":
                requestWriteAccess(call.argument("uris"), result);
                break;
            case "writeFile":
                writeFile(call.argument("uri"), call.argument("path"), call.argument("source"),
                        Boolean.TRUE.equals(call.argument("truncate")), result);
                break;
            case "takeImported":
                Map<String, Object> taken = new HashMap<>();
                taken.put("saved", new ArrayList<>(imported));
                taken.put("failed", importFailures);
                imported.clear();
                importFailures = 0;
                result.success(taken);
                break;
            default:
                result.notImplemented();
        }
    }

    // ---- Permission

    private String[] readPermissions() {
        if (Build.VERSION.SDK_INT >= 33) return new String[]{Manifest.permission.READ_MEDIA_AUDIO};
        // Android 10 changes other apps' files through the old storage model, which needs WRITE
        if (Build.VERSION.SDK_INT <= 29) {
            return new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE};
        }
        return new String[]{Manifest.permission.READ_EXTERNAL_STORAGE};
    }

    private boolean hasPermission() {
        for (String permission : readPermissions()) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) return false;
        }
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_PERMISSION || permissionResult == null) return;
        String answer;
        if (hasPermission()) {
            answer = "granted";
        } else {
            // Without a rationale to show, Android won't ask again
            answer = ActivityCompat.shouldShowRequestPermissionRationale(this, readPermissions()[0]) ? "denied" : "blocked";
        }
        permissionResult.success(answer);
        permissionResult = null;
    }

    // ---- Library

    private List<Map<String, Object>> querySongs() {
        String[] columns = {
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.DATE_ADDED,
                MediaStore.Audio.Media.SIZE,
        };
        List<Map<String, Object>> songs = new ArrayList<>();
        try (Cursor cursor = getContentResolver().query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, columns,
                MediaStore.Audio.Media.IS_MUSIC + " != 0", null,
                MediaStore.Audio.Media.DATE_ADDED + " DESC")) {
            while (cursor != null && cursor.moveToNext()) {
                long id = cursor.getLong(0);
                Map<String, Object> song = new HashMap<>();
                song.put("id", id);
                song.put("title", cursor.getString(1));
                song.put("artist", cursor.getString(2));
                song.put("album", cursor.getString(3));
                song.put("path", cursor.getString(4));
                song.put("duration", cursor.getLong(5));
                song.put("added", cursor.getLong(6));
                song.put("size", cursor.getLong(7));
                song.put("uri", ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id).toString());
                songs.add(song);
            }
        }
        return songs;
    }

    /** The embedded cover as JPEG, or null when the song has none. */
    private byte[] artwork(long id, String path, int size) throws IOException {
        Bitmap bitmap;
        if (Build.VERSION.SDK_INT >= 29) {
            Uri uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id);
            try {
                bitmap = getContentResolver().loadThumbnail(uri, new Size(size, size), null);
            } catch (IOException noCover) {
                return null;
            }
        } else {
            MediaMetadataRetriever retriever = new MediaMetadataRetriever();
            try {
                retriever.setDataSource(path);
                byte[] picture = retriever.getEmbeddedPicture();
                if (picture == null) return null;
                bitmap = android.graphics.BitmapFactory.decodeByteArray(picture, 0, picture.length);
            } catch (RuntimeException unreadable) {
                return null;
            } finally {
                retriever.release();
            }
            if (bitmap == null) return null;
            int side = Math.min(size, Math.max(bitmap.getWidth(), 1));
            bitmap = Bitmap.createScaledBitmap(bitmap, side, side * bitmap.getHeight() / Math.max(bitmap.getWidth(), 1), true);
        }
        ByteArrayOutputStream jpeg = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, jpeg);
        return jpeg.toByteArray();
    }

    // ---- Writing tags

    /** Android 11 and later ask once for all the files; before that the permission covers it. */
    private void requestWriteAccess(List<String> uris, MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < 30 || uris == null || uris.isEmpty()) {
            result.success(true);
            return;
        }
        List<Uri> parsed = new ArrayList<>();
        for (String uri : uris) parsed.add(Uri.parse(uri));
        PendingIntent request = MediaStore.createWriteRequest(getContentResolver(), parsed);
        try {
            writeResult = result;
            startIntentSenderForResult(request.getIntentSender(), REQUEST_WRITE, null, 0, 0, 0);
        } catch (IntentSender.SendIntentException e) {
            writeResult = null;
            result.error("write_request", e.getMessage(), null);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_WRITE || writeResult == null) return;
        writeResult.success(resultCode == RESULT_OK);
        writeResult = null;
    }

    /**
     * Copies the file at [source] into the song. When [truncate] is false only
     * the start of the song is overwritten, which is how the tag is changed
     * without touching the audio.
     */
    private void writeFile(String uri, String path, String source, boolean truncate, MethodChannel.Result result) {
        worker.execute(() -> {
            try {
                File from = new File(source);
                File target = new File(path);
                if (truncate && target.getParentFile() != null
                        && target.getParentFile().getUsableSpace() < from.length() * 2) {
                    throw new IOException("Not enough free space to save the file");
                }
                try (ParcelFileDescriptor fd = getContentResolver().openFileDescriptor(Uri.parse(uri), truncate ? "wt" : "rw");
                     InputStream in = new FileInputStream(from);
                     OutputStream out = new FileOutputStream(fd.getFileDescriptor())) {
                    copy(in, out);
                }
                // Let the library read the new tags before the Dart side asks
                // for them, but don't wait forever for a scan that never ends
                AtomicBoolean answered = new AtomicBoolean(false);
                Runnable done = () -> {
                    if (!answered.getAndSet(true)) result.success(null);
                };
                MediaScannerConnection.scanFile(this, new String[]{path}, null,
                        (scanned, scannedUri) -> main.post(done));
                main.postDelayed(done, 10_000);
            } catch (Exception e) {
                main.post(() -> result.error("write", e.getMessage(), null));
            }
        });
    }

    // ---- Songs shared to Stash

    @SuppressWarnings("deprecation")
    private void importShared(Intent intent) {
        if (intent == null || intent.getAction() == null) return;
        List<Uri> uris = new ArrayList<>();
        if (Intent.ACTION_SEND.equals(intent.getAction())) {
            Uri uri = intent.getParcelableExtra(Intent.EXTRA_STREAM);
            if (uri != null) uris.add(uri);
        } else if (Intent.ACTION_SEND_MULTIPLE.equals(intent.getAction())) {
            ArrayList<Uri> shared = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
            if (shared != null) uris.addAll(shared);
        } else {
            return;
        }
        // Don't save the same songs again when the activity is recreated
        intent.setAction(null);
        worker.execute(() -> {
            List<String> saved = new ArrayList<>();
            int failed = 0;
            for (Uri uri : uris) {
                try {
                    saved.add(saveToMusic(uri));
                } catch (Exception e) {
                    failed++;
                }
            }
            int failures = failed;
            main.post(() -> {
                imported.addAll(saved);
                importFailures += failures;
                if (channel != null) channel.invokeMethod("imported", null);
            });
        });
    }

    /** Copies a shared file into Music/Stash and returns its name. */
    private String saveToMusic(Uri shared) throws IOException {
        ContentResolver resolver = getContentResolver();
        String name = displayName(shared);
        String mime = resolver.getType(shared);
        if (mime == null || !mime.startsWith("audio/")) mime = "audio/mpeg";

        if (Build.VERSION.SDK_INT >= 29) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Audio.Media.DISPLAY_NAME, name);
            values.put(MediaStore.Audio.Media.MIME_TYPE, mime);
            values.put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/Stash");
            values.put(MediaStore.Audio.Media.IS_PENDING, 1);
            Uri target = resolver.insert(MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY), values);
            if (target == null) throw new IOException("The media library refused the file");
            try (InputStream in = resolver.openInputStream(shared);
                 OutputStream out = resolver.openOutputStream(target)) {
                if (in == null || out == null) throw new IOException("Can't open the shared file");
                copy(in, out);
            } catch (IOException e) {
                resolver.delete(target, null, null);
                throw e;
            }
            values.clear();
            values.put(MediaStore.Audio.Media.IS_PENDING, 0);
            resolver.update(target, values, null, null);
            return name;
        }

        File folder = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Stash");
        if (!folder.isDirectory() && !folder.mkdirs()) throw new IOException("Can't create Music/Stash");
        File target = new File(folder, name);
        for (int i = 1; target.exists(); i++) target = new File(folder, numbered(name, i));
        try (InputStream in = resolver.openInputStream(shared);
             OutputStream out = new FileOutputStream(target)) {
            if (in == null) throw new IOException("Can't open the shared file");
            copy(in, out);
        }
        MediaScannerConnection.scanFile(this, new String[]{target.getPath()}, null, null);
        return target.getName();
    }

    private String displayName(Uri uri) {
        String name = null;
        try (Cursor cursor = getContentResolver().query(uri, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) name = cursor.getString(0);
        } catch (RuntimeException ignored) {
            // Some apps share URIs that can't be queried
        }
        if (name == null) name = uri.getLastPathSegment();
        if (name == null || name.isEmpty()) name = "Shared song.mp3";
        return name.replace('/', '_');
    }

    private static String numbered(String name, int i) {
        int dot = name.lastIndexOf('.');
        return dot <= 0 ? name + " (" + i + ")" : name.substring(0, dot) + " (" + i + ")" + name.substring(dot);
    }

    // ---- Helpers

    private interface Work {
        Object run() throws Exception;
    }

    private void inBackground(MethodChannel.Result result, Work work) {
        worker.execute(() -> {
            try {
                Object value = work.run();
                main.post(() -> result.success(value));
            } catch (Exception e) {
                main.post(() -> result.error("library", e.getMessage(), null));
            }
        });
    }

    private static void copy(InputStream in, OutputStream out) throws IOException {
        byte[] buffer = new byte[64 * 1024];
        for (int read; (read = in.read(buffer)) != -1; ) out.write(buffer, 0, read);
    }
}
