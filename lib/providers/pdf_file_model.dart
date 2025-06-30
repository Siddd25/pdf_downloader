

import 'dart:io';

import 'package:flutter/material.dart';

class UiStateModel with ChangeNotifier {
  //all variables associated with uiState
  bool _selectionMode = false;
  bool _isSearching = false;
  List<String> _selectedFiles = [];
  List<FileSystemEntity> pdfFiles = [];
  List<FileSystemEntity> currentPdfFiles = [];


  //getter functions
  bool get isSelectionMode => _selectionMode;
  bool get isSearching => _isSearching;
  bool get hasSelection => _selectedFiles.isNotEmpty;
  int get selectedFileCount => _selectedFiles.length;
  List<String> get selectedFiles => _selectedFiles;


  void enableSelectionMode() {
    _selectionMode = true;
    notifyListeners();
  }

  void disableSelectionMode() {
    _selectionMode = false;
    notifyListeners();
  }

  void setSearchMode(bool value) {
    _isSearching = value;
    notifyListeners();
  }


  void selectFile(String file) {
    if (!_selectedFiles.contains(file)) {
      _selectedFiles.add(file);
      notifyListeners();
    }
  }

  void deselectFile(String file) {
    _selectedFiles.remove(file);
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }

  bool isFileSelected(String file) {
    return _selectedFiles.contains(file);
  }

  void updatePdfFiles(List<FileSystemEntity> files) {
    pdfFiles = files;
    notifyListeners();

  }

  void updateCurrentPdfFiles(List<FileSystemEntity> files) {
    currentPdfFiles = files;
    notifyListeners();
  }



}