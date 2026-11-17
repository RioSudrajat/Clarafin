import 'dart:async';
import 'dart:convert';

/// Single parsed frame from an HTTP `text/event-stream` response.
class AiSseFrame {
  final String event;
  final String data;
  final String? id;

  const AiSseFrame({
    required this.event,
    required this.data,
    this.id,
  });
}

/// Incrementally decodes UTF-8 SSE byte chunks across arbitrary TCP boundaries.
Stream<AiSseFrame> parseSseByteStream(Stream<List<int>> byteStream) async* {
  var currentEvent = '';
  final dataLines = <String>[];
  String? currentId;
  var remainder = '';

  AiSseFrame? flushFrame() {
    if (currentEvent.isEmpty && dataLines.isEmpty) {
      currentId = null;
      return null;
    }
    final frame = AiSseFrame(
      event: currentEvent,
      data: dataLines.join('\n'),
      id: currentId,
    );
    currentEvent = '';
    dataLines.clear();
    currentId = null;
    return frame;
  }

  AiSseFrame? processLine(String rawLine) {
    final line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;
    if (line.isEmpty) {
      return flushFrame();
    }
    // SSE comments (such as `: keepalive`) carry no event payload.
    if (line.startsWith(':')) {
      return null;
    }

    final colonIdx = line.indexOf(':');
    final String field;
    final String value;
    if (colonIdx < 0) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colonIdx);
      final rawVal = line.substring(colonIdx + 1);
      value = rawVal.startsWith(' ') ? rawVal.substring(1) : rawVal;
    }

    switch (field) {
      case 'event':
        currentEvent = value.trim();
        break;
      case 'data':
        dataLines.add(value);
        break;
      case 'id':
        currentId = value;
        break;
      default:
        break;
    }
    return null;
  }

  await for (final textChunk in utf8.decoder.bind(byteStream)) {
    final combined = remainder + textChunk;
    var start = 0;
    while (true) {
      final nlIdx = combined.indexOf('\n', start);
      if (nlIdx < 0) {
        remainder = combined.substring(start);
        break;
      }
      final frame = processLine(combined.substring(start, nlIdx));
      if (frame != null) {
        yield frame;
      }
      start = nlIdx + 1;
    }
  }

  if (remainder.isNotEmpty) {
    final frame = processLine(remainder);
    if (frame != null) {
      yield frame;
    }
  }

  final trailing = flushFrame();
  if (trailing != null) {
    yield trailing;
  }
}
