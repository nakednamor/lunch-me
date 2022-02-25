import 'package:flutter/material.dart';

Widget errorMessage(String message) {
  return Card(
    child: Padding(
      child: Center(
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      ),
      padding: const EdgeInsets.all(8.0),
    ),
    color: Colors.white,
    margin: EdgeInsets.zero,
  );
}
