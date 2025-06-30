import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cohouse_match/models/user.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  // It's best practice to load the API key from a secure location
  // (like environment variables) rather than hardcoding it in your app.
  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }

  Future<String?> getMatchScore(
      UserData currentUser, UserData potentialMatch) async {
    final prompt = '''
Given the following two user profiles, provide a compatibility score from 0 to 100 and a brief explanation. Focus on lifestyle, personality, and budget.

User 1 (Current User):
Name: ${currentUser.name ?? 'Not specified'}
Bio: ${currentUser.bio ?? 'Not specified'}
Personality Tags: ${currentUser.personalityTags?.join(', ') ?? 'None'}
Lifestyle Details: ${currentUser.lifestyleDetails?.join(', ') ?? 'None'}
Budget: ${currentUser.budget?.toString() ?? 'Not specified'}
Location: ${currentUser.location ?? 'Not specified'}

User 2 (Potential Match):
Name: ${potentialMatch.name ?? 'Not specified'}
Bio: ${potentialMatch.bio ?? 'Not specified'}
Personality Tags: ${potentialMatch.personalityTags?.join(', ') ?? 'None'}
Lifestyle Details: ${potentialMatch.lifestyleDetails?.join(', ') ?? 'None'}
Budget: ${potentialMatch.budget?.toString() ?? 'Not specified'}
Location: ${potentialMatch.location ?? 'Not specified'}

Compatibility Score (0-100) and Explanation:
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error getting match score from Gemini: $e');
      return null;
    }
  }
}