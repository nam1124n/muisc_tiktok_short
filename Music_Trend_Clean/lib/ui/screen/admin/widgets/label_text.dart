import 'package:flutter/material.dart';

class LabelText extends StatelessWidget {
  final String text;
  const LabelText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: Color(0xFF374151),
      ),
    );
  }
}
