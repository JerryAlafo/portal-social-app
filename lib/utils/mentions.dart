import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Constrói TextSpan com destaque para @menções e #tags.
List<TextSpan> buildContentSpans(
  String content, {
  required TextStyle base,
  Brightness brightness = Brightness.dark,
  VoidCallback? Function(String mention)? onMention,
}) {
  final mentionColor =
      brightness == Brightness.dark ? AppColors.mentionLink : AppColors.mentionLinkLight;
  final spans = <TextSpan>[];
  final regex = RegExp(r'(?<![@#\w])[@#][\wÀ-ÿ]+');
  int last = 0;

  for (final match in regex.allMatches(content)) {
    if (match.start > last) {
      spans.add(TextSpan(text: content.substring(last, match.start)));
    }
    final token = match.group(0)!;
    final isMention = token.startsWith('@');
    spans.add(TextSpan(
      text: token,
      style: base.copyWith(
        color: isMention ? mentionColor : AppColors.pink,
        fontWeight: FontWeight.w700,
      ),
    ));
    last = match.end;
  }

  if (last < content.length) {
    spans.add(TextSpan(text: content.substring(last)));
  }

  return spans;
}
