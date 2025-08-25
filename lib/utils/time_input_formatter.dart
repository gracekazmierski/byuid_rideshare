// lib/utils/time_input_formatter.dart
import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 4) return oldValue;

    String hourString = '';
    String minuteString = '';
    String formattedText = '';

    // This logic handles all cases based on the number of digits typed.
    switch (digitsOnly.length) {
      case 0:
        // Empty case
        break;
      case 1:
        // e.g., "9" -> displays "9"
        hourString = digitsOnly;
        formattedText = hourString;
        break;
      case 2:
        // e.g., "12" or "90" (as a prefix for 9:00). Treat as a valid intermediate step.
        hourString = digitsOnly;
        formattedText = hourString;
        break;
      case 3:
        // e.g., "100" becomes "1:00", "900" becomes "9:00"
        hourString = digitsOnly.substring(0, 1);
        minuteString = digitsOnly.substring(1);
        formattedText = '$hourString:$minuteString';
        break;
      case 4:
        // e.g., "1230" becomes "12:30"
        hourString = digitsOnly.substring(0, 2);
        minuteString = digitsOnly.substring(2);
        formattedText = '$hourString:$minuteString';
        break;
    }

    // --- Final Validation Logic ---
    if (hourString.isNotEmpty) {
      final hour = int.parse(hourString);
      if (hour > 12 || hour < 1) {
        // THE FIX: We ONLY reject an invalid hour (like 90) if it's NOT a
        // 2-digit intermediate step. If it is 2 digits, we let it pass
        // so the user can type the third digit. The form's main validator
        // will catch it if the user stops at an invalid 2-digit number.
        if (digitsOnly.length != 2) {
          return oldValue;
        }
      }
    }

    if (minuteString.isNotEmpty) {
      final minute = int.parse(minuteString);
      if (minute > 59) {
        return oldValue;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
