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
    // Updated prompt for clarity and to enforce JSON output.
    final prompt = '''
Analyze the compatibility between these two user profiles and provide a response in JSON format.

**User 1 (Current User):**
- **Name:** ${currentUser.name ?? 'N/A'}
- **Bio:** ${currentUser.bio ?? 'N/A'}
- **Personality Tags:** ${currentUser.personalityTags?.join(', ') ?? 'N/A'}
- **Lifestyle Details:** ${currentUser.lifestyleDetails?.join(', ') ?? 'N/A'}
- **Budget:** ${currentUser.budget?.toString() ?? 'N/A'}
- **Location:** ${currentUser.location ?? 'N/A'}
- **Gender:** ${currentUser.gender ?? 'N/A'}
- **Age:** ${currentUser.age?.toString() ?? 'N/A'}

**User 2 (Potential Match):**
- **Name:** ${potentialMatch.name ?? 'N/A'}
- **Bio:** ${potentialMatch.bio ?? 'N/A'}
- **Personality Tags:** ${potentialMatch.personalityTags?.join(', ') ?? 'N/A'}
- **Lifestyle Details:** ${potentialMatch.lifestyleDetails?.join(', ') ?? 'N/A'}
- **Budget:** ${potentialMatch.budget?.toString() ?? 'N/A'}
- **Location:** ${potentialMatch.location ?? 'N/A'}
- **Gender:** ${potentialMatch.gender ?? 'N/A'}
- **Age:** ${potentialMatch.age?.toString() ?? 'N/A'}

**Instructions:**
Return a single, valid JSON object with two keys:
1.  `"score"`: An integer between 0 and 100 representing the compatibility.
2.  `"explanation"`: A concise, single-line string (under 200 characters) that summarizes the key reasons for the score. Do not include newlines or other control characters in the explanation string.

**Example Response:**
```json
{
  "score": 75,
  "explanation": "Good compatibility in lifestyle and budget, but potential differences in social energy."
}
```
''';

    try {
      final content = [Content.text(prompt)];
      // Enforce JSON output from the model
      final generationConfig = GenerationConfig(
        responseMimeType: 'application/json',
      );
      final response = await _model.generateContent(
        content,
        generationConfig: generationConfig,
      );
      final text = response.text;

      if (text == null) {
        print('Gemini returned a null response.');
        return null;
      }

      // The model is now configured to return JSON, so direct parsing is safer.
      // No need to manually find '{' and '}'
      final Map<String, dynamic> result = json.decode(text);

      if (result.containsKey('score') && result.containsKey('explanation')) {
        return result;
      } else {
        print('Invalid JSON response from Gemini. Missing keys: $text');
        return null;
      }
    } catch (e) {
      print('Error getting match score from Gemini: $e');
      // It's helpful to see the raw response when debugging.
      if (e is FormatException && e.source != null) {
        print('Raw Gemini response was: ${e.source}');
      }
      return null;
    }
  }
}