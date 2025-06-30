import 'package:flutter/material.dart';
import 'package:pdf_management/screens/downloaded_reports_screen.dart';
import 'package:pdf_management/services/pdf_download_service.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatelessWidget {

  final TextEditingController url = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Downloader'),
        centerTitle: true,
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Paste URL to download pdf',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: url,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Enter PDF URL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: "Download PDF",
                    onPressed: () async{
                      String inputUrl = url.text.trim();
                      String fileName = inputUrl.split('/').last;

                      if (inputUrl.isNotEmpty) {
                        print('Downloading from URL: $inputUrl');
                        await downloadAndSavePdf(inputUrl, fileName, context);

                      } else {
                        print('Please enter a valid URL');
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextButton(onPressed: (){
              url.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL cleared')),
              );
            }, child: const Text('Clear'),),

            ElevatedButton( //Button to view downloaded PDFs
              onPressed: () {
                url.clear();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadedReportsScreen()),
                );

              },
              child: const Text('View Available PDFs'),
            ),

          ],
        ),
      ),
    );
  }
}
