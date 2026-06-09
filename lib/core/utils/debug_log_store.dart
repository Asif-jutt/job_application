/// In-memory ring buffer for viewing logs in the Admin diagnostics screen.
class DebugLogStore {
  DebugLogStore._();
  static final DebugLogStore instance = DebugLogStore._();

  static const int _maxEntries = 100;
  final List<LogEntry> _entries = [];

  void add(LogEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
  }

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void clear() => _entries.clear();
}

class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
  });

  final String level;
  final String message;
  final DateTime timestamp;
  final String? tag;
}
