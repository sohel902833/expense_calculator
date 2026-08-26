/// Which environment this build talks to -- switches which Firestore
/// dataset the app reads/writes (see [FireSotreCollection]) and whether the
/// DEV badge shows on the login screen.
///
/// Controlled at build time via `--dart-define=APP_MODE=PROD`, not by
/// editing this file -- `flutter run`/local builds default to DEV
/// unmodified, and `scripts/build_release.sh` passes PROD explicitly. Never
/// hardcode `prod` here; that would make every local debug build talk to
/// production data.
class AppMode {
  static const dev = "DEV";
  static const prod = "PROD";

  static const current = String.fromEnvironment(
    'APP_MODE',
    defaultValue: dev,
  );

  static bool get isProd => current == prod;
}
