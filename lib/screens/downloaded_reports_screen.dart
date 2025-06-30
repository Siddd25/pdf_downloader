import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/pdf_file_model.dart';
import '../services/pdfViewPage.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';




class DownloadedReportsScreen extends StatefulWidget {
  const DownloadedReportsScreen({super.key});

  @override
  State<DownloadedReportsScreen> createState() => _DownloadedReportsScreenState();
}

class _DownloadedReportsScreenState extends State<DownloadedReportsScreen> {
  //List<FileSystemEntity> pdfFiles = [];// List to hold downloaded PDF files
 // Set<String> selectedFiles = {};
  //bool selectionMode = false;
  //bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
 // List<FileSystemEntity> currentPdfFiles = [];

  late UiStateModel uiState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    uiState = Provider.of<UiStateModel>(context, listen: false);
  }




  Future<void> _loadDownloadedPdfs() async { //function to load downloaded PDFs


    final dir = Directory('/storage/emulated/0/Download/MyPDFs');
    print(dir);

    final folder = Directory('${dir!.path}');

    if (await folder.exists()) {
      final files = folder
          .listSync()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      uiState.updatePdfFiles(files);
      uiState.updateCurrentPdfFiles(files);// Update the model with the list of PDF files
    }
  }

  // Function to delete selected files
  void _deleteSelectedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Selected Files"),
        content: Text("Are you sure you want to delete ${uiState.selectedFileCount} file(s)?"),
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
      List<String> selectedFiles = uiState.selectedFiles;
      for (var path in selectedFiles) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      uiState.clearSelection();
      uiState.disableSelectionMode();
      setState(() {
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

    final filtered = uiState.pdfFiles.where((file) {
      final name = file.path.split('/').last.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();

    uiState.updateCurrentPdfFiles(filtered);
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStoragePermissions();
      uiState.disableSelectionMode();
      uiState.clearSelection(); // Clear any previous selections
      uiState.setSearchMode(false);
      searchController.clear();
    });
    _loadDownloadedPdfs(); // Load downloaded PDFs when the screen is initialized
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
    final uiState = context.watch<UiStateModel>(); // Get the current state of the PDF model

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: uiState.isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            uiState.disableSelectionMode(); // Disable selection mode
            uiState.clearSelection(); // Clear selected files
          },
        )
            : uiState.isSearching
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            uiState.disableSelectionMode();
            uiState.setSearchMode(false);
            setState(() {
              searchController.clear();

            });
          },
        )
            : null,

        title: uiState.isSelectionMode
            ? Text('${uiState.selectedFiles.length} selected')
            : uiState.isSearching  //if mode is searching, convert the AppBar to a search bar
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

        actions: uiState.isSelectionMode
            ? [
          IconButton (
            icon: const Icon(Icons.delete),
            onPressed:  (){
              _deleteSelectedFiles();

            },
          ),
        ]
            : [
          if (uiState.isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                uiState.setSearchMode(false);
                uiState.updateCurrentPdfFiles(uiState.pdfFiles);
                setState(() {
                  searchController.clear();
                  searchPDFs('');
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                uiState.setSearchMode(true);
                setState(() {
                  searchFocusNode.requestFocus();
                });
              },
            ),
        ],
      ),

      body: uiState.currentPdfFiles.isEmpty
          ? const Center(child: Text('No PDFs found.')) // If no PDFs are found, display a message
          : ListView.builder( // Build the list of downloaded PDFs
          itemCount: uiState.currentPdfFiles.length,
          itemBuilder: (context, index) {
            final file = uiState.currentPdfFiles[index];

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
                  //selected: selectedFiles.contains(file.path),
                  selected: uiState.isFileSelected(file.path),
                  tileColor: uiState.isFileSelected(file.path)
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
                    if (uiState.isSelectionMode) {
                      if (uiState.isFileSelected(file.path)) {
                        uiState.deselectFile(file.path);
                      } else {
                        uiState.selectFile(file.path);
                      }

                      if (uiState.selectedFileCount == 0) {
                        uiState.disableSelectionMode();
                      }
                    }
                    else {
                      openPdfWithSystemApp(file.path);
                    }
                  },
                  onLongPress:() {
                    uiState.enableSelectionMode();
                    uiState.selectFile(file.path);

                  },
                );
              },
            );
          }
      ),
    );
  }

}
