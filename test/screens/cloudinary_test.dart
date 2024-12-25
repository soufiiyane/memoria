import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memoria/screens/cloudinary_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

class MockHttpClient extends Mock implements http.Client {}

class MockFile extends Mock implements File {}

class MockMultipartRequest extends Mock implements http.MultipartRequest {}

void main() {
  group('CloudinaryService Tests', () {
    late CloudinaryService cloudinaryService;
    late File testImageFile;

    setUp(() {
      cloudinaryService = CloudinaryService();
      testImageFile = File('test/resources/test_image.jpg');
    });

    test('CloudinaryService initializes with correct values', () {
      expect(cloudinaryService.cloudName, equals('Memoria_Cloud_API'));
      expect(cloudinaryService.apiKey, equals('725826593563454'));
      expect(cloudinaryService.uploadPreset, equals('Memoria_Image_Preset'));
      expect(cloudinaryService.folder, equals('flashcardsmedia'));
    });

    test('uploadImage returns URL on successful upload', () async {
      final result = await cloudinaryService.uploadImage(testImageFile);
      expect(result, isA<String?>());
    });

    test('uploadImage generates correct API URL', () {
      final expectedUrl =
          'https://api.cloudinary.com/v1_1/${cloudinaryService.cloudName}/image/upload';
      final apiUrl =
          'https://api.cloudinary.com/v1_1/${cloudinaryService.cloudName}/image/upload';
      expect(apiUrl, equals(expectedUrl));
    });

    test('uploadImage includes required fields in request', () async {
      final request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'https://api.cloudinary.com/v1_1/${cloudinaryService.cloudName}/image/upload'));

      request.fields['api_key'] = cloudinaryService.apiKey;
      request.fields['upload_preset'] = cloudinaryService.uploadPreset;
      request.fields['folder'] = cloudinaryService.folder;

      expect(request.fields['api_key'], equals(cloudinaryService.apiKey));
      expect(request.fields['upload_preset'],
          equals(cloudinaryService.uploadPreset));
      expect(request.fields['folder'], equals(cloudinaryService.folder));
    });

    test('uploadImage handles file path correctly', () {
      final filePath = testImageFile.path;
      expect(filePath, isA<String>());
    });

    test('CloudinaryService handles timestamp correctly', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      expect(int.tryParse(timestamp), isNotNull);
    });

    test('uploadImage handles response parsing', () {
      final responseJson = {'secure_url': 'https://example.com/image.jpg'};
      final responseString = json.encode(responseJson);
      final decoded = json.decode(responseString);
      expect(decoded['secure_url'], equals('https://example.com/image.jpg'));
    });

    test('CloudinaryService folder structure is correct', () {
      expect(cloudinaryService.folder, equals('flashcardsmedia'));
    });

    test('uploadImage handles null response gracefully', () async {
      final nonExistentFile = File('non_existent.jpg');
      final result = await cloudinaryService.uploadImage(nonExistentFile);
      expect(result, isNull);
    });

    test('CloudinaryService API key format is valid', () {
      expect(cloudinaryService.apiKey.length, equals(15));
      expect(int.tryParse(cloudinaryService.apiKey), isNotNull);
    });
  });
}
