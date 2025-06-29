# 📄 PDF Management App

A Flutter application to manage, view, search, and delete downloaded PDF files stored in a specific folder on your Android device. Built with performance and user experience in mind.

---

## 🚀 Features

- 📁 Load and display all PDFs from `/storage/emulated/0/Download/MyPDFs`
- 🔍 Real-time search with live filtering
- 🧹 Multi-select delete functionality with confirmation dialogs
- 📷 Thumbnail preview of first page of each PDF (using `pdfrx`)
- 📤 Open PDF in external apps with `open_file` (release-tested)
- ☁️ Permissions handling using `permission_handler`

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
    flutter_lints: ^5.0.0
  dio: ^5.4.0
  path_provider: ^2.1.2
  permission_handler: ^11.3.0
  flutter_pdfview: ^1.3.1
  intl: ^0.18.1
  open_file: ^3.5.10
  screenshot: ^3.0.0
```


  
