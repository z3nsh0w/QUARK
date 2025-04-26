import 'package:flutter/material.dart';

class SettingsButton extends StatefulWidget {
  const SettingsButton({super.key});

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(129, 110, 216, 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(212, 209, 255,1),
              spreadRadius: 2,
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBar(isBar1: true),
                const SizedBox(height: 6),
                _buildBar(isBar1: false),
                const SizedBox(height: 6),
                _buildBar(isBar1: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar({required bool isBar1}) {
    return Container(
      width: 45 * 0.5,
      height: 2,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(229, 229, 229, 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: _getLeftPosition(isBar1),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(126, 117, 255, 1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getLeftPosition(bool isBar1) {
    if (isBar1) {
      return _isHovered ? (45 * 0.1) - 3 - 4 : (45 * 0.5) - 3 - (-4);
    } else {
      return _isHovered ? (45 * 0.1) - 3 - (-4) : (45 * 0.5) - 3 - 4;
    }
  }
}

// Helper extension for RGB color creation
extension ColorExtension on Color {
  static Color fromRGBO(int r, int g, int b) {
    return Color.fromRGBO(r, g, b, 1);
  }
}