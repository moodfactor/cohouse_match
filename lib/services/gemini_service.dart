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
Analyze the compatibility between these two cohousing profiles for living together and provide detailed analysis in JSON format.

**User 1:**
- **Name:** ${currentUser.name ?? 'N/A'}
- **Bio:** ${currentUser.bio ?? 'N/A'}
- **Personality:** ${currentUser.personalityTags?.join(', ') ?? 'N/A'}
- **Lifestyle:** ${currentUser.lifestyleDetails?.join(', ') ?? 'N/A'}
- **Budget:** \$${currentUser.budget?.toString() ?? 'N/A'}/month
- **Location:** ${currentUser.location ?? 'N/A'}
- **Age:** ${currentUser.age?.toString() ?? 'N/A'}

**User 2:**
- **Name:** ${potentialMatch.name ?? 'N/A'}
- **Bio:** ${potentialMatch.bio ?? 'N/A'}
- **Personality:** ${potentialMatch.personalityTags?.join(', ') ?? 'N/A'}
- **Lifestyle:** ${potentialMatch.lifestyleDetails?.join(', ') ?? 'N/A'}
- **Budget:** \$${potentialMatch.budget?.toString() ?? 'N/A'}/month
- **Location:** ${potentialMatch.location ?? 'N/A'}
- **Age:** ${potentialMatch.age?.toString() ?? 'N/A'}

Analyze compatibility for cohousing and return JSON with:
- `"score"`: Overall compatibility (0-100)
- `"summary"`: Brief compatibility summary (max 150 chars)
- `"strengths"`: Array of 2-3 compatibility strengths
- `"concerns"`: Array of 1-2 potential concerns
- `"budgetMatch"`: Budget compatibility score (0-100)
- `"lifestyleMatch"`: Lifestyle compatibility score (0-100)
- `"personalityMatch"`: Personality compatibility score (0-100)

**Example:**
```json
{
  "score": 82,
  "summary": "Strong match with aligned budgets and complementary personalities",
  "strengths": ["Similar budget ranges", "Complementary social styles", "Shared lifestyle values"],
  "concerns": ["Different sleep schedules"],
  "budgetMatch": 95,
  "lifestyleMatch": 78,
  "personalityMatch": 85
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
      dynamic result;
      try {
        result = json.decode(text);
      } catch (e) {
        print('Error decoding JSON response: $e');
        print('Raw response: $text');
        return null;
      }

      // Ensure result is a Map
      if (result is! Map<String, dynamic>) {
        print('Invalid response type: ${result.runtimeType}');
        print('Raw response: $text');
        return null;
      }

      // Validate required fields
      final requiredFields = ['score', 'summary', 'strengths', 'concerns'];
      if (requiredFields.every((field) => result.containsKey(field))) {
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