import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadAndSavePdf(String url, String fileName, BuildContext context) async {
  try {
    // Request permission for Android 10+
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied || await Permission.manageExternalStorage.isDenied) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied')),
          );
          return;
        }
      }
    }

    //  Save to public Download folder
    final saveDir = Directory('/storage/emulated/0/Download/MyPDFs');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    final filePath = '${saveDir.path}/$fileName';

    double progress = 0.0; // Initialize progress
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Use GlobalKey to update SnackBar
    final GlobalKey<State<StatefulWidget>> progressKey = GlobalKey();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: const Duration(hours: 1),
        content: StatefulBuilder(
          key: progressKey,
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Downloading..."),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text('${(progress * 100).toStringAsFixed(0)}%'), // Display percentage
              ],
            );
          },
        ),
      ),
    );

    final dio = Dio();

    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          progress = received / total; // Calculate progress
          // Refresh the SnackBar
          scaffoldMessenger.clearSnackBars();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              duration: const Duration(hours: 1),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Downloading..."),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text('${(progress * 100).toStringAsFixed(0)}%'), // Display percentage
                ],
              ),
            ),
          );
        }
      },
    );

    // Optional short delay
    await Future.delayed(const Duration(milliseconds: 500));

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Downloaded to: $filePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
