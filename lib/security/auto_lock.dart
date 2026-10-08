/// Tracks when the app has handed the screen to the system on purpose (a
/// file dialog), so leaving the foreground for it doesn't lock the app.
class AutoLock {
  int _external = 0;

  bool get suspended => _external > 0;

  Future<T> whileExternal<T>(Future<T> Function() action) async {
    _external++;
    try {
      return await action();
    } finally {
      _external--;
    }
  }
}
