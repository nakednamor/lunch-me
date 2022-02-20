import 'package:flutter/material.dart';

mixin PostFrameMixin<T extends StatefulWidget> on State<T> {
  void postFrame(void Function() callback) =>
      WidgetsBinding.instance?.addPostFrameCallback(
            (_) {
          // Execute callback if page is mounted
          if (mounted) callback();
        },
      );
}