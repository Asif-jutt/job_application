import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';

class ToastService {
  ToastService._();

  static void success(BuildContext context, String message) {
    CherryToast.success(
      title: const Text('Success', style: TextStyle(fontWeight: FontWeight.w600)),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 600),
      autoDismiss: true,
    ).show(context);
  }

  static void error(BuildContext context, String message) {
    CherryToast.error(
      title: const Text('Error', style: TextStyle(fontWeight: FontWeight.w600)),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 600),
      autoDismiss: true,
    ).show(context);
  }

  static void info(BuildContext context, String message) {
    CherryToast.info(
      title: const Text('Rozgar', style: TextStyle(fontWeight: FontWeight.w600)),
      description: Text(message),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 600),
      autoDismiss: true,
    ).show(context);
  }
}
