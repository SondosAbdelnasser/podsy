import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get huggingFaceApiKey => dotenv.env['HUGGING_FACE_API_KEY']!;
  static String get assemblyAiKey => dotenv.env['ASSEMBLY_API_KEY']!;
} 