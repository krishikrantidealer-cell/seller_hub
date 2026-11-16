import 'dart:js_interop';

@JS('window.navigator.clipboard')
external _JSClipboard? get _clipboard;

@JS('window')
external _JSWindow get _window;

extension type _JSWindow._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener, [JSBoolean? useCapture]);
  external void removeEventListener(String type, JSFunction listener, [JSBoolean? useCapture]);
}

extension type _JSClipboardEvent._(JSObject _) implements JSObject {
  external _JSDataTransfer? get clipboardData;
}

extension type _JSDataTransfer._(JSObject _) implements JSObject {
  external String getData(String format);
}

extension type _JSClipboard._(JSObject _) implements JSObject {
  external JSPromise<JSArray<_JSClipboardItem>> read();
}

extension type _JSClipboardItem._(JSObject _) implements JSObject {
  external JSArray<JSString> get types;
  external JSPromise<_JSBlob> getType(String type);
}

extension type _JSBlob._(JSObject _) implements JSObject {
  external JSPromise<JSString> text();
}

String? _lastPastedHtml;
DateTime? _lastPastedAt;
JSFunction? _pasteListener;
int _listenerRefCount = 0;

void registerWebPasteListener() {
  _listenerRefCount++;
  if (_pasteListener != null) return;
  _pasteListener = ((_JSClipboardEvent event) {
    try {
      final html = event.clipboardData?.getData('text/html');
      if (html != null && html.trim().isNotEmpty) {
        _lastPastedHtml = html;
        _lastPastedAt = DateTime.now();
      }
    } catch (_) {}
  }).toJS;
  _window.addEventListener('paste', _pasteListener!, true.toJS);
}

void unregisterWebPasteListener() {
  if (_listenerRefCount > 0) _listenerRefCount--;
  if (_listenerRefCount == 0 && _pasteListener != null) {
    _window.removeEventListener('paste', _pasteListener!, true.toJS);
    _pasteListener = null;
  }
}

String? takeRecentPastedHtml() {
  final html = _lastPastedHtml;
  final at = _lastPastedAt;
  _lastPastedHtml = null;
  _lastPastedAt = null;
  if (html != null && at != null && DateTime.now().difference(at).inMilliseconds <= 1500) {
    return html;
  }
  return null;
}

Future<String?> readHtmlFromClipboard() async {
  final recent = takeRecentPastedHtml();
  if (recent != null) return recent;
  try {
    final clipboard = _clipboard;
    if (clipboard == null) return null;
    final items = (await clipboard.read().toDart).toDart;
    for (final item in items) {
      final types = item.types.toDart.map((e) => e.toDart).toList();
      if (types.contains('text/html')) {
        final blob = await item.getType('text/html').toDart;
        final html = (await blob.text().toDart).toDart;
        if (html.trim().isNotEmpty) {
          return html;
        }
      }
    }
  } catch (_) {
    // Gracefully fall back to plain-text / Markdown paste if browser blocks async clipboard read.
  }
  return null;
}
