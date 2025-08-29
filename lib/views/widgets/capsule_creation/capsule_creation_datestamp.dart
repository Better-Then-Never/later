import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CapsuleCreationDateStamp extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final DateTime? date;

  const CapsuleCreationDateStamp({
    super.key,
    required this.height,
    this.backgroundColor = const Color.fromARGB(255, 85, 201, 46),
    this.date,
  });

  String get formattedDate {
    final chosenDate = date ?? DateTime.now(); 
    return DateFormat('dd.MM.yyyy').format(chosenDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(25)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 50,
                fontFamily: 'Irina',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
