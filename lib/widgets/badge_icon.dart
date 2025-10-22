import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const BadgeIcon({super.key, required this.icon, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -2, top: -2,
            child: Container(
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.red, borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text('$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
