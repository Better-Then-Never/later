import java.lang.reflect.Method;

/**
 * Prints the animator scale the window manager gives apps (what Android's
 * animators, and with them MapLibre's tap zooms and zoom coast, run at):
 *
 * <pre>
 * adb shell CLASSPATH=/data/local/tmp/pinch.jar app_process /system/bin AnimScale
 * </pre>
 *
 * The settings can read "unset" while it is 0: `settings delete` after
 * `settings put global animator_duration_scale 0` leaves 0 in memory;
 * restore with `settings put global animator_duration_scale 1.0`.
 */
public final class AnimScale {
  public static void main(String[] args) throws Exception {
    Class<?> global = Class.forName("android.view.WindowManagerGlobal");
    Object wm = global.getMethod("getWindowManagerService").invoke(null);
    Method current = wm.getClass().getMethod("getCurrentAnimatorScale");
    System.out.println("currentAnimatorScale=" + current.invoke(wm));
    for (int i = 0; i < 3; i++) {
      try {
        Method m = wm.getClass().getMethod("getAnimationScale", int.class);
        System.out.println("animationScale[" + i + "]=" + m.invoke(wm, i));
      } catch (Exception e) {
        System.out.println("animationScale[" + i + "] n/a " + e);
      }
    }
  }
}
