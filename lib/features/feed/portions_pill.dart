import 'package:flutter/material.dart';
import 'package:kai_finder_lab/data/models/kai_event.dart';

class PortionsPill extends StatelessWidget {
  final KaiEvent event;

  const PortionsPill({super.key, required this.event});

  Color backgroundColor() {
    int portionsLeft = event.portionsLeft;
  if (!event.isActive) {
    return Colors.grey;
  } else if (portionsLeft > 10) {
    return Colors.green;
  } else if (portionsLeft >= 3) {
    return Colors.amber;
  } else {
    return Colors.red;
  }
  }

  String label() {
    int portionsLeft = event.portionsLeft;
  if (!event.isActive) {
    return 'Gone';
  } else if (portionsLeft > 10) {
    return 'Plenty';
  } else if (portionsLeft >= 3) {
    return 'Going fast';
  } else {
    return 'Almost gone';
  }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ), 
      child: Text(
        label(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}