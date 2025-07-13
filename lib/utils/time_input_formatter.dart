// lib/utils/time_input_formatter.dart
import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // If user is deleting or has already typed a colon, do nothing.
    if (newValue.text.length < oldValue.text.length ||
        newValue.text.contains(':')) {
      return newValue;
    }

    final String newText = newValue.text.replaceAll(':', '');
    if (newText.length > 4) {
      return oldValue;
    }

    String formattedText = newText;

    // When 3 or 4 digits are present, insert a colon.
    if (newText.length >= 3) {
      formattedText =
      '${newText.substring(0, newText.length - 2)}:${newText.substring(newText.length - 2)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}