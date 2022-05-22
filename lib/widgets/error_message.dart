import 'package:flutter/material.dart';

Widget errorMessage(String message) {
  return Card(
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
