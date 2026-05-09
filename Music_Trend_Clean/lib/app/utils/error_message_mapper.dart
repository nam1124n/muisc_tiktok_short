import 'dart:async';

class ErrorMessageMapper {
  static String map(
    Object error, {
    String fallbackMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.',
  }) {
    if (error is TimeoutException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      return fallbackMessage;
    }

    final message = error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|Error):\s*'), '')
        .trim();

    return message.isEmpty ? fallbackMessage : message;
  }
}
