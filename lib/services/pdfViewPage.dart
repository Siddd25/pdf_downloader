

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';




void openPdfWithSystemApp(String path) async {
  final file = File(path);

  if (!await file.exists()) {
    print("File does not exist: $path");
    return;
  }



  final result = await OpenFile.open(path); // Open the PDF file using the system's default app



  if (result.type == ResultType.noAppToOpen) {
    // Optional: inform user
    debugPrint("No app found to open PDF.");
  } else if (result.type != ResultType.done) {
    debugPrint("Failed to open file: ${result.message}");
  }
}