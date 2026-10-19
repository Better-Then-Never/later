import android.hardware.input.InputManager;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.lang.reflect.Method;

/**
 * Real two-finger touches for the map harness (docs/map/PERFORMANCE.md),
 * injected into Android's input system as the system's own `input` command
 * does, so the app gets them exactly as it gets a hand's.
 *
 * <pre>
 * adb shell CLASSPATH=/data/local/tmp/pinch.jar app_process /system/bin Pinch \
 *     cx cy msPerSegment d0 d1 [d2 ...]
 * </pre>
 *
 * Two fingers one above the other around (cx, cy) in screen pixels, their
 * distance going d0 → d1 → ..., each segment in msPerSegment, a move every
 * 8 ms, then both lift. Several gestures: separate them with "/" and a pause
 * in ms, e.g. {@code 140 520 / 350 520 140}. A two-finger tap is a gesture
 * that does not move: {@code cx cy 80 300 300}.
 *
 * <pre>
 * ... Pinch tap x y count gapMs     # one finger: count taps, gapMs apart
 * </pre>
 */
public final class Pinch {
  private static Object im;
  private static Method inject;

  public static void main(String[] args) throws Exception {
    im = InputManager.class.getDeclaredMethod("getInstance").invoke(null);
    inject = InputManager.class.getMethod("injectInputEvent", InputEvent.class, int.class);
    if (args[0].equals("tap")) {
      float x = Float.parseFloat(args[1]);
      float y = Float.parseFloat(args[2]);
      int count = Integer.parseInt(args[3]);
      long gap = Long.parseLong(args[4]);
      for (int i = 0; i < count; i++) {
        if (i > 0) SystemClock.sleep(gap);
        long down = SystemClock.uptimeMillis();
        send(down, down, MotionEvent.ACTION_DOWN, 1, x, y, 0);
        SystemClock.sleep(50);
        send(down, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, 1, x, y, 0);
      }
      return;
    }
    float cx = Float.parseFloat(args[0]);
    float cy = Float.parseFloat(args[1]);
    int ms = Integer.parseInt(args[2]);
    java.util.List<Float> distances = new java.util.ArrayList<>();
    for (int i = 3; i < args.length; i++) {
      if (args[i].equals("/")) {
        gesture(cx, cy, ms, distances);
        distances.clear();
        SystemClock.sleep(Long.parseLong(args[++i]));
      } else {
        distances.add(Float.parseFloat(args[i]));
      }
    }
    if (!distances.isEmpty()) gesture(cx, cy, ms, distances);
  }

  private static void gesture(float cx, float cy, int ms, java.util.List<Float> d) throws Exception {
    final int stepMs = 8;
    int steps = Math.max(1, ms / stepMs);
    long down = SystemClock.uptimeMillis();
    long next = down;
    float dist = d.get(0);
    send(down, down, MotionEvent.ACTION_DOWN, 1, cx, cy, dist);
    send(down, SystemClock.uptimeMillis(),
        MotionEvent.ACTION_POINTER_DOWN | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, cx, cy, dist);
    for (int seg = 0; seg + 1 < d.size(); seg++) {
      for (int s = 1; s <= steps; s++) {
        next += stepMs;
        long wait = next - SystemClock.uptimeMillis();
        if (wait > 0) SystemClock.sleep(wait);
        dist = d.get(seg) + (d.get(seg + 1) - d.get(seg)) * s / steps;
        send(down, SystemClock.uptimeMillis(), MotionEvent.ACTION_MOVE, 2, cx, cy, dist);
      }
    }
    send(down, SystemClock.uptimeMillis(),
        MotionEvent.ACTION_POINTER_UP | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, cx, cy, dist);
    send(down, SystemClock.uptimeMillis(), MotionEvent.ACTION_UP, 1, cx, cy, dist);
  }

  private static void send(long down, long time, int action, int count, float cx, float cy, float dist)
      throws Exception {
    MotionEvent.PointerProperties[] props = new MotionEvent.PointerProperties[count];
    MotionEvent.PointerCoords[] coords = new MotionEvent.PointerCoords[count];
    for (int i = 0; i < count; i++) {
      props[i] = new MotionEvent.PointerProperties();
      props[i].id = i;
      props[i].toolType = MotionEvent.TOOL_TYPE_FINGER;
      coords[i] = new MotionEvent.PointerCoords();
      coords[i].x = cx;
      coords[i].y = cy + (i == 0 ? -dist / 2 : dist / 2);
      coords[i].pressure = 1;
      coords[i].size = 0.05f;
    }
    MotionEvent ev = MotionEvent.obtain(down, time, action, count, props, coords,
        0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
    // 0: INJECT_INPUT_EVENT_MODE_ASYNC.
    inject.invoke(im, ev, 0);
    ev.recycle();
  }
}
