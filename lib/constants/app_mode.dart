/// Which environment this build talks to. Flip [current] to switch which
/// Firestore dataset the app reads/writes (see [FireSotreCollection]) and
/// whether the DEV badge shows on the login screen.
class AppMode {
  static const dev = "DEV";
  static const prod = "PROD";

  static const current = dev;

  static bool get isProd => current == prod;
}
