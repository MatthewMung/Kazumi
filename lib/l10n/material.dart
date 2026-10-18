/// Presentation adapters keep existing constant UI declarations and leave model
/// values untouched. Inputs and technical output can explicitly opt out.
library;

import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart' hide Text, SelectableText;
import 'dart:ui' as ui;
import 'chinese_script.dart';

export 'package:flutter/material.dart' hide Text, SelectableText;
export 'chinese_script.dart';

InlineSpan convertChineseSpan(InlineSpan span, ChineseScript script) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text == null ? null : script.display(span.text!),
    children: span.children
        ?.map((child) => convertChineseSpan(child, script))
        .toList(),
    style: span.style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel == null
        ? null
        : script.display(span.semanticsLabel!),
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.convert = true,
  }) : textSpan = null;

  const Text.rich(
    this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.convert = true,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final ui.TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final bool convert;

  @override
  Widget build(BuildContext context) {
    final script = ChineseScriptScope.of(context);
    final span = textSpan ?? TextSpan(text: data);
    return material.Text.rich(
      convert ? convertChineseSpan(span, script) : span,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: convert && semanticsLabel != null
          ? script.display(semanticsLabel!)
          : semanticsLabel,
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

class SelectableText extends StatelessWidget {
  const SelectableText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.textScaler,
    this.minLines,
    this.maxLines,
    this.scrollPhysics,
    this.scrollBehavior,
    this.selectionHeightStyle,
    this.textWidthBasis,
    this.convert = true,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final int? minLines;
  final int? maxLines;
  final ScrollPhysics? scrollPhysics;
  final ScrollBehavior? scrollBehavior;
  final ui.BoxHeightStyle? selectionHeightStyle;
  final TextWidthBasis? textWidthBasis;
  final bool convert;

  @override
  Widget build(BuildContext context) {
    final script = ChineseScriptScope.of(context);
    return material.SelectableText(
      convert ? script.display(data) : data,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      minLines: minLines,
      maxLines: maxLines,
      scrollPhysics: scrollPhysics,
      scrollBehavior: scrollBehavior,
      selectionHeightStyle: selectionHeightStyle,
      textWidthBasis: textWidthBasis,
    );
  }
}
