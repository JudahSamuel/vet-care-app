import 'package:flutter/material.dart';

// A simple class to hold the style for each character
class CharStyle {
  double scale;
  FontWeight fontWeight;
  CharStyle({this.scale = 1.0, this.fontWeight = FontWeight.w100});
}

class VariableProximityText extends StatefulWidget {
  final String text;
  final double fontSize;
  final double radius;

  const VariableProximityText({
    Key? key,
    required this.text,
    this.fontSize = 64.0,
    this.radius = 120.0,
  }) : super(key: key);

  @override
  _VariableProximityTextState createState() => _VariableProximityTextState();
}

class _VariableProximityTextState extends State<VariableProximityText> {
  late List<GlobalKey> _charKeys;
  late List<CharStyle> _charStyles;
  Offset _pointerPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _charKeys = List.generate(widget.text.length, (_) => GlobalKey());
    _charStyles = List.generate(widget.text.length, (_) => CharStyle());
  }

  void _updateStyles(Offset pointerPosition) {
    if (!mounted) return;

    setState(() {
      _pointerPosition = pointerPosition;
      for (int i = 0; i < _charKeys.length; i++) {
        final key = _charKeys[i];
        if (key.currentContext != null) {
          final renderBox = key.currentContext!.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final charCenter = Offset(
              position.dx + renderBox.size.width / 2,
              position.dy + renderBox.size.height / 2);

          final distance = (charCenter - _pointerPosition).distance;
          final proximity = (1.0 - (distance / widget.radius)).clamp(0.0, 1.0);

          final scale = 1.0 + proximity * 0.5;
          final fontWeight = FontWeight.lerp(FontWeight.w100, FontWeight.w900, proximity)!;

          _charStyles[i] = CharStyle(scale: scale, fontWeight: fontWeight);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector handles touch and drag events on mobile
    return GestureDetector(
      onPanUpdate: (details) => _updateStyles(details.globalPosition),
      onPanEnd: (_) => _updateStyles(Offset.zero), // Reset on release
      // MouseRegion handles hover events on web/desktop
      child: MouseRegion(
        onHover: (event) => _updateStyles(event.position),
        onExit: (_) => _updateStyles(Offset.zero), // Reset on exit
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (i) {
            final char = widget.text[i];
            final style = _charStyles[i];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(style.scale),
              transformAlignment: Alignment.center,
              child: Text(
                char == ' ' ? '\u00A0' : char,
                key: _charKeys[i],
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: style.fontWeight,
                  color: Colors.white,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}