import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cohouse_match/models/user.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  // It's best practice to load the API key from a secure location
  // (like environment variables) rather than hardcoding it in your app.
  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  Future<Map<String, dynamic>?> getMatchScore(
      UserData currentUser, UserData potentialMatch) async {
    final prompt = '''
Given the following two user profiles, provide a compatibility score from 0 to 100 and a detailed explanation in JSON format. The explanation should highlight key compatibility factors based on lifestyle, personality, budget, and location.

User 1 (Current User):
Name: ${currentUser.name ?? 'Not specified'}
Bio: ${currentUser.bio ?? 'Not specified'}
Personality Tags: ${currentUser.personalityTags?.join(', ') ?? 'None'}
Lifestyle Details: ${currentUser.lifestyleDetails?.join(', ') ?? 'None'}
Budget: ${currentUser.budget?.toString() ?? 'Not specified'}
Location: ${currentUser.location ?? 'Not specified'}
Gender: ${currentUser.gender ?? 'Not specified'}
Age: ${currentUser.age?.toString() ?? 'Not specified'}

User 2 (Potential Match):
Name: ${potentialMatch.name ?? 'Not specified'}
Bio: ${potentialMatch.bio ?? 'Not specified'}
Personality Tags: ${potentialMatch.personalityTags?.join(', ') ?? 'None'}
Lifestyle Details: ${potentialMatch.lifestyleDetails?.join(', ') ?? 'None'}
Budget: ${potentialMatch.budget?.toString() ?? 'Not specified'}
Location: ${potentialMatch.location ?? 'Not specified'}
Gender: ${potentialMatch.gender ?? 'Not specified'}
Age: ${potentialMatch.age?.toString() ?? 'Not specified'}

Provide the response as a JSON object with two keys: "score" (integer 0-100) and "explanation" (string).
Example:
{
  "score": 75,
  "explanation": "Both users share similar interests in outdoor activities and have compatible budgets. However, their personality tags suggest different social preferences."
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) {
        print('Gemini returned null response.');
        return null;
      }

      // Attempt to parse the JSON response
      final jsonString = text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1);
      final Map<String, dynamic> result = json.decode(jsonString);

      if (result.containsKey('score') && result.containsKey('explanation')) {
        // Attempt to parse the explanation string as a nested JSON
        try {
          final nestedExplanation = json.decode(result['explanation']);
          if (nestedExplanation is Map<String, dynamic> && nestedExplanation.containsKey('summary')) {
            result['explanation'] = nestedExplanation['summary'];
          } else if (nestedExplanation is Map<String, dynamic> && nestedExplanation.containsKey('Overall Assessment')) {
            result['explanation'] = nestedExplanation['Overall Assessment'];
          } else {
            print('Nested explanation JSON does not contain "summary" or "Overall Assessment" key.');
          }
        } catch (e) {
          print('Error parsing nested explanation JSON: $e');
          // Keep the original explanation string if parsing fails
        }
        return result;
      } else {
        print('Invalid JSON response from Gemini: $text');
        return null;
      }
    } catch (e) {
      print('Error getting match score from Gemini: $e');
      return null;
    }
  }
}