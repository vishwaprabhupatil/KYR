import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/document_model.dart';
import '../services/analysis_service.dart';
import '../services/gemini_service.dart';
import '../services/health_service.dart';
import '../services/upload_service.dart';

class DocumentProvider extends ChangeNotifier {
  final UploadService _uploadService = UploadService();
  final AnalysisService _analysisService = AnalysisService();
  final HealthService _healthService = HealthService();
  final GeminiService _geminiService = GeminiService();

  File? selectedFile;
  String selectedLanguage = AppStrings.supportedLanguages.first;
  bool useLocalGemini = false;

  DocumentModel? document;
  DocumentAnalysis analysis = DocumentAnalysis.empty();

  bool isPicking = false;
  bool isUploading = false;
  bool isAnalyzing = false;
  String analysisStageLabel = 'Preparing…';
  double? analysisProgress;
  bool isPinging = false;
  String? errorMessage;
  String? lastPingResult;

  bool get hasDocument => document != null;
  bool get geminiConfigured => _geminiService.isConfigured;

  Future<void> pickFromCamera() async {
    errorMessage = null;
    isPicking = true;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (shot == null) return;
      selectedFile = File(shot.path);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isPicking = false;
      notifyListeners();
    }
  }

  Future<void> pickFromUpload() async {
    errorMessage = null;
    isPicking = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) {
        throw const FormatException('Could not read selected file path.');
      }
      selectedFile = File(path);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isPicking = false;
      notifyListeners();
    }
  }

  // Back-compat: older UI calls `pickFile()`.
  Future<void> pickFile() => pickFromUpload();

  Future<void> pingBackend() async {
    errorMessage = null;
    lastPingResult = null;
    isPinging = true;
    notifyListeners();
    try {
      final status = await _healthService.ping();
      lastPingResult = status == 200
          ? 'Backend reachable (HTTP $status).'
          : 'Backend responded (HTTP $status).';
    } catch (e) {
      errorMessage = 'Backend not reachable: $e';
    } finally {
      isPinging = false;
      notifyListeners();
    }
  }

  void setLanguage(String language) {
    selectedLanguage = language;
    notifyListeners();
  }

  void setUseLocalGemini(bool value) {
    useLocalGemini = value;
    notifyListeners();
  }

  Future<bool> uploadAndAnalyze() async {
    errorMessage = null;
    analysisStageLabel = 'Preparing…';
    analysisProgress = 0;
    final file = selectedFile;
    if (file == null) {
      errorMessage = 'Please select a document first.';
      notifyListeners();
      return false;
    }

    isUploading = true;
    isAnalyzing = true;
    notifyListeners();

    try {
      if (useLocalGemini) {
        analysisStageLabel = 'Reading image…';
        analysisProgress = 0.2;
        notifyListeners();
        final ext = file.path.split('.').last.toLowerCase();
        final isImage = ext == 'png' || ext == 'jpg' || ext == 'jpeg';
        if (!isImage) {
          throw const FormatException(
            'Local Gemini test currently supports only images (PNG/JPG/JPEG).',
          );
        }
        if (!_geminiService.isConfigured) {
          throw const FormatException(
            'Missing GEMINI_API_KEY. Run with --dart-define=GEMINI_API_KEY=YOUR_KEY',
          );
        }
        document = DocumentModel(
          id: 'local-gemini',
          fileName: file.path.split(Platform.pathSeparator).last,
          language: selectedLanguage,
        );
        analysisStageLabel = 'Analyzing with Gemini…';
        analysisProgress = 0.55;
        notifyListeners();
        analysis = await _geminiService.analyzeImage(
          imageFile: file,
          language: selectedLanguage,
        );
        analysisStageLabel = 'Done';
        analysisProgress = 1;
        return true;
      }

      analysisStageLabel = 'Uploading…';
      analysisProgress = 0.25;
      notifyListeners();
      final docId = await _uploadService.uploadDocument(
        file: file,
        language: selectedLanguage,
      );
      document = DocumentModel(
        id: docId,
        fileName: file.path.split(Platform.pathSeparator).last,
        language: selectedLanguage,
      );

      analysisStageLabel = 'Analyzing document…';
      analysisProgress = 0.55;
      notifyListeners();
      await _analysisService.runOcr(documentId: docId);

      analysisStageLabel = 'Detecting risky clauses…';
      analysisProgress = 0.78;
      notifyListeners();
      analysis = await _analysisService.analyze(
        documentId: docId,
        language: selectedLanguage,
      );
      analysisStageLabel = 'Done';
      analysisProgress = 1;
      return true;
    } catch (e) {
      errorMessage = _formatError(e);
      return false;
    } finally {
      isUploading = false;
      isAnalyzing = false;
      analysisProgress = null;
      notifyListeners();
    }
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String? detail;
      if (data is Map) {
        detail = (data['detail'] ?? data['message'] ?? data['error'])?.toString();
      } else if (data is String) {
        detail = data;
      }
      if (status != null && detail != null && detail.isNotEmpty) {
        return 'HTTP $status: $detail';
      }
      if (status != null) return 'HTTP $status: ${e.message ?? e.type.name}';
      return e.message ?? e.type.name;
    }
    return e.toString();
  }

  void reset() {
    selectedFile = null;
    document = null;
    analysis = DocumentAnalysis.empty();
    errorMessage = null;
    lastPingResult = null;
    isPicking = false;
    isUploading = false;
    isAnalyzing = false;
    analysisStageLabel = 'Preparing…';
    analysisProgress = null;
    isPinging = false;
    notifyListeners();
  }

  void setFromHistory({
    required String documentId,
    required String fileName,
    required String language,
    required DocumentAnalysis analysis,
  }) {
    document = DocumentModel(id: documentId, fileName: fileName, language: language);
    this.analysis = analysis;
    errorMessage = null;
    notifyListeners();
  }
}
