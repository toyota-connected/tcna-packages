enum OarsRatingValue { unknown, none, mild, moderate, intense }

class ContentRatingOarsOneDotZero {
  final OarsRatingValue drugsAlcohol;
  final OarsRatingValue drugsNarcotics;
  final OarsRatingValue drugsTobacco;
  final OarsRatingValue languageDiscrimination;
  final OarsRatingValue languageHumor;
  final OarsRatingValue languageProfanity;
  final OarsRatingValue moneyGambling;
  final OarsRatingValue moneyPurchasing;
  final OarsRatingValue sexNudity;
  final OarsRatingValue sexThemes;
  final OarsRatingValue socialAudio;
  final OarsRatingValue socialChat;
  final OarsRatingValue socialContacts;
  final OarsRatingValue socialInfo;
  final OarsRatingValue socialLocation;
  final OarsRatingValue violenceBloodshed;
  final OarsRatingValue violenceCartoon;
  final OarsRatingValue violenceFantasy;
  final OarsRatingValue violenceRealistic;
  final OarsRatingValue violenceSexual;

  ContentRatingOarsOneDotZero({
    required this.drugsAlcohol,
    required this.drugsNarcotics,
    required this.drugsTobacco,
    required this.languageDiscrimination,
    required this.languageHumor,
    required this.languageProfanity,
    required this.moneyGambling,
    required this.moneyPurchasing,
    required this.sexNudity,
    required this.sexThemes,
    required this.socialAudio,
    required this.socialChat,
    required this.socialContacts,
    required this.socialInfo,
    required this.socialLocation,
    required this.violenceBloodshed,
    required this.violenceCartoon,
    required this.violenceFantasy,
    required this.violenceRealistic,
    required this.violenceSexual,
  });

  factory ContentRatingOarsOneDotZero.fromJson(Map<String?, dynamic> json) {
    OarsRatingValue parseRating(String? rating) {
      return OarsRatingValue.values.firstWhere(
        (e) => e.toString() == "OarsRatingValue.$rating",
        orElse: () => OarsRatingValue.unknown,
      );
    }

    return ContentRatingOarsOneDotZero(
      drugsAlcohol: parseRating(json['drugs-alcohol'] as String?),
      drugsNarcotics: parseRating(json['drugs-narcotics'] as String?),
      drugsTobacco: parseRating(json['drugs-tobacco'] as String?),
      languageDiscrimination: parseRating(json['language-discrimination'] as String?),
      languageHumor: parseRating(json['language-humor'] as String?),
      languageProfanity: parseRating(json['language-profanity'] as String?),
      moneyGambling: parseRating(json['money-gambling'] as String?),
      moneyPurchasing: parseRating(json['money-purchasing'] as String?),
      sexNudity: parseRating(json['sex-nudity'] as String?),
      sexThemes: parseRating(json['sex-themes'] as String?),
      socialAudio: parseRating(json['social-audio'] as String?),
      socialChat: parseRating(json['social-chat'] as String?),
      socialContacts: parseRating(json['social-contacts'] as String?),
      socialInfo: parseRating(json['social-info'] as String?),
      socialLocation: parseRating(json['social-location'] as String?),
      violenceBloodshed: parseRating(json['violence-bloodshed'] as String?),
      violenceCartoon: parseRating(json['violence-cartoon'] as String?),
      violenceFantasy: parseRating(json['violence-fantasy'] as String?),
      violenceRealistic: parseRating(json['violence-realistic'] as String?),
      violenceSexual: parseRating(json['violence-sexual'] as String?),
    );
  }

  void printRatings(String type) {
    print("[Content Ratings]");
    print("\ttype:  $type");
    print("\tdrugs-alcohol: ${drugsAlcohol.toString().split('.').last}");
    print("\tdrugs-narcotics: ${drugsNarcotics.toString().split('.').last}");
    print("\tdrugs-tobacco: ${drugsTobacco.toString().split('.').last}");
    print("\tlanguage-discrimination: ${languageDiscrimination.toString().split('.').last}");
    print("\tlanguage-humor: ${languageHumor.toString().split('.').last}");
    print("\tlanguage-profanity: ${languageProfanity.toString().split('.').last}");
    print("\tmoney-gambling: ${moneyGambling.toString().split('.').last}");
    print("\tmoney-purchasing: ${moneyPurchasing.toString().split('.').last}");
    print("\tsex-nudity: ${sexNudity.toString().split('.').last}");
    print("\tsex-themes: ${sexThemes.toString().split('.').last}");
    print("\tsocial-audio: ${socialAudio.toString().split('.').last}");
    print("\tsocial-chat: ${socialChat.toString().split('.').last}");
    print("\tsocial-contacts: ${socialContacts.toString().split('.').last}");
    print("\tsocial-info: ${socialInfo.toString().split('.').last}");
    print("\tsocial-location: ${socialLocation.toString().split('.').last}");
    print("\tviolence-bloodshed: ${violenceBloodshed.toString().split('.').last}");
    print("\tviolence-cartoon: ${violenceCartoon.toString().split('.').last}");
    print("\tviolence-fantasy: ${violenceFantasy.toString().split('.').last}");
    print("\tviolence-realistic: ${violenceRealistic.toString().split('.').last}");
    print("\tviolence-sexual: ${violenceSexual.toString().split('.').last}");
  }
}

class ContentRatingOarsOneDotOne {
  final OarsRatingValue drugsAlcohol;
  final OarsRatingValue drugsNarcotics;
  final OarsRatingValue drugsTobacco;
  final OarsRatingValue languageDiscrimination;
  final OarsRatingValue languageHumor;
  final OarsRatingValue languageProfanity;
  final OarsRatingValue moneyGambling;
  final OarsRatingValue moneyPurchasing;
  final OarsRatingValue sexNudity;
  final OarsRatingValue sexThemes;
  final OarsRatingValue socialAudio;
  final OarsRatingValue socialChat;
  final OarsRatingValue socialContacts;
  final OarsRatingValue socialInfo;
  final OarsRatingValue socialLocation;
  final OarsRatingValue violenceBloodshed;
  final OarsRatingValue violenceCartoon;
  final OarsRatingValue violenceDesecration;
  final OarsRatingValue violenceFantasy;
  final OarsRatingValue violenceRealistic;
  final OarsRatingValue violenceSexual;
  final OarsRatingValue violenceSlavery;

  ContentRatingOarsOneDotOne({
    required this.drugsAlcohol,
    required this.drugsNarcotics,
    required this.drugsTobacco,
    required this.languageDiscrimination,
    required this.languageHumor,
    required this.languageProfanity,
    required this.moneyGambling,
    required this.moneyPurchasing,
    required this.sexNudity,
    required this.sexThemes,
    required this.socialAudio,
    required this.socialChat,
    required this.socialContacts,
    required this.socialInfo,
    required this.socialLocation,
    required this.violenceBloodshed,
    required this.violenceCartoon,
    required this.violenceDesecration,
    required this.violenceFantasy,
    required this.violenceRealistic,
    required this.violenceSexual,
    required this.violenceSlavery,
  });

  factory ContentRatingOarsOneDotOne.fromJson(Map<String?, dynamic> json) {
    OarsRatingValue parseRating(String? rating) {
      return OarsRatingValue.values.firstWhere(
        (e) => e.toString() == "OarsRatingValue.$rating",
        orElse: () => OarsRatingValue.unknown,
      );
    }

    return ContentRatingOarsOneDotOne(
      drugsAlcohol: parseRating(json['drugs-alcohol'] as String?),
      drugsNarcotics: parseRating(json['drugs-narcotics'] as String?),
      drugsTobacco: parseRating(json['drugs-tobacco'] as String?),
      languageDiscrimination: parseRating(json['language-discrimination'] as String?),
      languageHumor: parseRating(json['language-humor'] as String?),
      languageProfanity: parseRating(json['language-profanity'] as String?),
      moneyGambling: parseRating(json['money-gambling'] as String?),
      moneyPurchasing: parseRating(json['money-purchasing'] as String?),
      sexNudity: parseRating(json['sex-nudity'] as String?),
      sexThemes: parseRating(json['sex-themes'] as String?),
      socialAudio: parseRating(json['social-audio'] as String?),
      socialChat: parseRating(json['social-chat'] as String?),
      socialContacts: parseRating(json['social-contacts'] as String?),
      socialInfo: parseRating(json['social-info'] as String?),
      socialLocation: parseRating(json['social-location'] as String?),
      violenceBloodshed: parseRating(json['violence-bloodshed'] as String?),
      violenceCartoon: parseRating(json['violence-cartoon'] as String?),
      violenceDesecration: parseRating(json['violence-desecration'] as String?),
      violenceFantasy: parseRating(json['violence-fantasy'] as String?),
      violenceRealistic: parseRating(json['violence-realistic'] as String?),
      violenceSexual: parseRating(json['violence-sexual'] as String?),
      violenceSlavery: parseRating(json['violence-slavery'] as String?),
    );
  }

  void printRatings(String type) {
    print("[Content Ratings]");
    print("\ttype:  $type");
    print("\tdrugs-alcohol: ${drugsAlcohol.toString().split('.').last}");
    print("\tdrugs-narcotics: ${drugsNarcotics.toString().split('.').last}");
    print("\tdrugs-tobacco: ${drugsTobacco.toString().split('.').last}");
    print("\tlanguage-discrimination: ${languageDiscrimination.toString().split('.').last}");
    print("\tlanguage-humor: ${languageHumor.toString().split('.').last}");
    print("\tlanguage-profanity: ${languageProfanity.toString().split('.').last}");
    print("\tmoney-gambling: ${moneyGambling.toString().split('.').last}");
    print("\tmoney-purchasing: ${moneyPurchasing.toString().split('.').last}");
    print("\tsex-nudity: ${sexNudity.toString().split('.').last}");
    print("\tsex-themes: ${sexThemes.toString().split('.').last}");
    print("\tsocial-audio: ${socialAudio.toString().split('.').last}");
    print("\tsocial-chat: ${socialChat.toString().split('.').last}");
    print("\tsocial-contacts: ${socialContacts.toString().split('.').last}");
    print("\tsocial-info: ${socialInfo.toString().split('.').last}");
    print("\tsocial-location: ${socialLocation.toString().split('.').last}");
    print("\tviolence-bloodshed: ${violenceBloodshed.toString().split('.').last}");
    print("\tviolence-cartoon: ${violenceCartoon.toString().split('.').last}");
    print("\tviolence-fantasy: ${violenceFantasy.toString().split('.').last}");
    print("\tviolence-desecration: ${violenceDesecration.toString().split('.').last}");
    print("\tviolence-realistic: ${violenceRealistic.toString().split('.').last}");
    print("\tviolence-sexual: ${violenceSexual.toString().split('.').last}");
    print("\tviolence-slavery: ${violenceSlavery.toString().split('.').last}");
  }
}