import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "Memoria_Cloud_API";
  final String apiKey = "725826593563454";
  final String apiSecret = "2P22bQhMC2WelHzxTbh473Rg59w";
  final String uploadPreset = "Memoria_Image_Preset";
  final String folder = "flashcardsmedia";

  Future<String?> uploadImage(File imageFile) async {
    final String apiUrl =
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString()
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['secure_url'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        print('Response body: ${await response.stream.bytesToString()}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
