const kUrlPrefix = "https://english.libmuy.com/app-backend";
final kBaseDate = DateTime(2024, 1, 1);
const kHistoryCount = 30;
const kHistorySaveIntervalSec = 3;
const kFavoriteListMaxSentenceNumber = 300;
const kSentencePageSize = kFavoriteListMaxSentenceNumber;
const kMaxAudioCacheCount = 5;
const kMaxSentenceCacheCount = 5;

const kRegStrEmailCheck = r'^[^@]+@[^@]+\.[^@]+';
const kRegStrPasswordCheck = r'^[^@]+@[^@]+\.[^@]+';

const kPageTopPadding = 16.0;

const kFontSizeMin = 15.0;
const kFontSizeMax = 25.0;
const kFontSizeDefault = 18.0;


String? kEmailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(kRegStrEmailCheck).hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

String? kPassowrdlValidator(String? value) {
//  const kReg = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{4,16}$';
  const kReg = r'^[A-Za-z\d@$!%*?&]{4,16}$';
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }
  if (value.length < 4 || value.length > 16) {
    return 'Password must be between 4 and 16 characters';
  }
  if (!RegExp(kReg).hasMatch(value)) {
//    return 'Password must include letters, numbers, and may include special characters.';
    return 'Password can be letters, numbers, and may include special characters.';
  }
  return null;
}

String? kUserIdlValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your User ID';
  }
  if (value.length < 3 || value.length > 32) {
    return 'User ID must be between 3 and 32 characters';
  }
  if (!RegExp(r'^[a-zA-Z0-9_]{3,32}$').hasMatch(value)) {
    return 'User ID can only contain letters, numbers, and underscores.';
  }
  return null;
}
