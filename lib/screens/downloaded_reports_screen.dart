import 'dart:io';
import 'package:flutter/material.dart';
import '../services/pdfViewPage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';





class DownloadedReportsScreen extends StatefulWidget {
  const DownloadedReportsScreen({super.key});

  @override
  State<DownloadedReportsScreen> createState() => _DownloadedReportsScreenState();
}

class _DownloadedReportsScreenState extends State<DownloadedReportsScreen> {
  List<FileSystemEntity> pdfFiles = [];// List to hold downloaded PDF files
  Set<String> selectedFiles = {};
  bool selectionMode = false;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  List<FileSystemEntity> currentPdfFiles = [];





  Future<void> _loadDownloadedPdfs() async {
    //loading PDFs from the local storage
    final dir = Directory('/storage/emulated/0/Download/MyPDFs');
    print(dir);

    final folder = Directory('${dir!.path}');

    if (await folder.exists()) {
      final files = folder
          .listSync()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      setState(() {
        pdfFiles = files;
        currentPdfFiles = files; // Initialize currentPdfFiles with all PDFs
      });
    }
  }

  // Function to delete selected files
  void _deleteSelectedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Selected Files"),
        content: Text("Are you sure you want to delete ${selectedFiles.length} file(s)?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var path in selectedFiles) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        selectedFiles.clear(); // Clear selected files after deletion
        selectionMode = false; // Exit selection mode
        _loadDownloadedPdfs(); // refresh list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selected files deleted")),
      );
    } else {
      // Optional toast when user cancels
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deletion cancelled")),
      );
    }
  }

  // Function to search PDFs based on user input
  void searchPDFs(String query) {
    final lowerQuery = query.trim().toLowerCase();

    final filtered = pdfFiles.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();

    setState(() {
      currentPdfFiles = filtered; // Update the displayed list with search results
    });
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStoragePermissions();
    });
    _loadDownloadedPdfs();  // Load downloaded PDFs when the screen is initialized
  }


  Future<void> _requestStoragePermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return;
      }

      final result = await Permission.manageExternalStorage.request();

    if (result.isPermanentlyDenied) {
      openAppSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission required. Enable from settings.")),
          );
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: selectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              selectionMode = false;
              selectedFiles.clear();
            });
          },
        )
            : isSearching
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isSearching = false;
              searchController.clear();
              searchPDFs('');
            });
          },
        )
            : null,

        title: selectionMode
            ? Text('${selectedFiles.length} selected')
            : isSearching  //if mode is searching, convert the AppBar to a search bar
            ? TextField(

          controller: searchController,
          focusNode: searchFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: searchPDFs,
          onSubmitted: searchPDFs,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(

            hintText: 'Search PDFs...',
            border: InputBorder.none,
          ),
        )
            : const Text('Downloaded PDFs'), // Default Title of the AppBar

        actions: selectionMode
            ? [
          IconButton (
            icon: const Icon(Icons.delete),
            onPressed:  _deleteSelectedFiles,
          ),
        ]
            : [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  searchController.clear();
                  isSearching = false;
                  currentPdfFiles = pdfFiles; // Reset to all PDFs
                  searchPDFs('');
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = true;
                  searchFocusNode.requestFocus();
                });
              },
            ),
        ],
      ),

      body: currentPdfFiles.isEmpty
          ? const Center(child: Text('No PDFs found.')) // If no PDFs are found, display a message
          : ListView.builder( // Build the list of downloaded PDFs
        itemCount: currentPdfFiles.length,
          itemBuilder: (context, index) {
            final file = currentPdfFiles[index];

            return FutureBuilder<FileStat>(
              future: FileStat.stat(file.path),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const ListTile(title: Text("Loading..."));

                final stat = snapshot.data!;
                final sizeInBytes = stat.size;
                final fileSize = sizeInBytes < 1024 * 1024 //if size is less than 1 MB, display in KB, else in MB
                    ? "${(sizeInBytes / 1024).toStringAsFixed(2)} KB"
                    : "${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB";
                final timestamp = stat.modified;
                final formattedDate = DateFormat.yMMMd().add_jm().format(timestamp); // Format the date and time

                return ListTile(
                  selected: selectedFiles.contains(file.path), // Highlight selected files
                  tileColor: selectedFiles.contains(file.path)
                      ? Colors.blueAccent
                      : null,
                  leading: const Icon(Icons.picture_as_pdf),

                  title: Text(file.path.split('/').last),
                  subtitle: Text(
                    "Size: $fileSize\nDownloaded: ${formattedDate}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  onTap: (){
                    if (selectionMode) {
                      setState(() {
                        if (selectedFiles.contains(file.path)) {
                          selectedFiles.remove(file.path);
                          if( selectedFiles.isEmpty) {
                            setState(() {
                            selectionMode = false;
                              });
                              }

                        } else {
                          selectedFiles.add(file.path);
                        }
                      }
                      );
                    }
                       else {
                      openPdfWithSystemApp(file.path); // Open the PDF file using the system PDF app
                    }
                  },
                  onLongPress:() {

                setState(() {
                selectionMode = true;// Enable selection mode on long press
                selectedFiles.add(file.path);
                });
                },
                );
              },
            );
          }
      ),
    );
  }

}
