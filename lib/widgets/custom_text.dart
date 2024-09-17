import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String title;
  final Color color;
  const CustomText({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
        title,
        style: TextStyle(
        color:color,
        fontSize: 18,
        fontWeight: FontWeight.w700
    ),);
  }
}
