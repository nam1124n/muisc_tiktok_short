import 'dart:async';

class ErrorMessageMapper {
  static const sessionExpiredMessage =
      'Phiên đăng nhập đã hết hạn hoặc không còn hợp lệ. Vui lòng đăng nhập lại.';
  static const accountDisabledMessage =
      'Tài khoản này đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.';
  static const accountNotFoundMessage =
      'Tài khoản này không còn tồn tại. Vui lòng đăng nhập lại.';

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
