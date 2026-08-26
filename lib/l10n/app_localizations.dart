import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Guardian'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @aiDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'AI Diagnosis'**
  String get aiDiagnosis;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @weatherAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Weather Advisory'**
  String get weatherAdvisory;

  /// No description provided for @farmExpenses.
  ///
  /// In en, this message translates to:
  /// **'Farm Expenses'**
  String get farmExpenses;

  /// No description provided for @cropAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Crop Advisory'**
  String get cropAdvisory;

  /// No description provided for @emergencyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get emergencyAlerts;

  /// No description provided for @marketPrices.
  ///
  /// In en, this message translates to:
  /// **'Market Prices'**
  String get marketPrices;

  /// No description provided for @governmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// No description provided for @satelliteMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Satellite Monitoring'**
  String get satelliteMonitoring;

  /// No description provided for @diagnoseCrop.
  ///
  /// In en, this message translates to:
  /// **'Diagnose Crop'**
  String get diagnoseCrop;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload crop image'**
  String get tapToUpload;

  /// No description provided for @describeCropIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe crop issue (optional)'**
  String get describeCropIssue;

  /// No description provided for @speakInstead.
  ///
  /// In en, this message translates to:
  /// **'Speak instead of typing'**
  String get speakInstead;

  /// No description provided for @onDevice.
  ///
  /// In en, this message translates to:
  /// **'ON-DEVICE'**
  String get onDevice;

  /// No description provided for @confident.
  ///
  /// In en, this message translates to:
  /// **'confident'**
  String get confident;

  /// No description provided for @detectedOffline.
  ///
  /// In en, this message translates to:
  /// **'Detected offline in under a second, with no internet connection.'**
  String get detectedOffline;

  /// No description provided for @notFullySure.
  ///
  /// In en, this message translates to:
  /// **'I am not fully sure about this one. Connect to the internet and ask the expert model for a detailed answer.'**
  String get notFullySure;

  /// No description provided for @askExpertModel.
  ///
  /// In en, this message translates to:
  /// **'Ask expert model'**
  String get askExpertModel;

  /// No description provided for @askingExpertModel.
  ///
  /// In en, this message translates to:
  /// **'Asking expert model...'**
  String get askingExpertModel;

  /// No description provided for @wasThisCorrect.
  ///
  /// In en, this message translates to:
  /// **'Was this correct?'**
  String get wasThisCorrect;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you. This helps improve the model for every farmer.'**
  String get thankYouFeedback;

  /// No description provided for @whatIsItActually.
  ///
  /// In en, this message translates to:
  /// **'What is it actually?'**
  String get whatIsItActually;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @todaysPrice.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PRICE'**
  String get todaysPrice;

  /// No description provided for @perKg.
  ///
  /// In en, this message translates to:
  /// **'/ kg'**
  String get perKg;

  /// No description provided for @perQuintal.
  ///
  /// In en, this message translates to:
  /// **'per quintal (100 kg)'**
  String get perQuintal;

  /// No description provided for @inSevenDays.
  ///
  /// In en, this message translates to:
  /// **'in 7 days'**
  String get inSevenDays;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select crop'**
  String get selectCrop;

  /// No description provided for @allCrops.
  ///
  /// In en, this message translates to:
  /// **'All crops'**
  String get allCrops;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rain (3h)'**
  String get rainfall;

  /// No description provided for @irrigationAdvice.
  ///
  /// In en, this message translates to:
  /// **'Irrigation advice'**
  String get irrigationAdvice;

  /// No description provided for @diseaseRiskWeather.
  ///
  /// In en, this message translates to:
  /// **'Disease risk from current weather'**
  String get diseaseRiskWeather;

  /// No description provided for @noDiseaseRisk.
  ///
  /// In en, this message translates to:
  /// **'No weather-linked disease risk right now. Keep monitoring your crop.'**
  String get noDiseaseRisk;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SPENT'**
  String get totalSpent;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @whereMoneyWent.
  ///
  /// In en, this message translates to:
  /// **'Where the money went'**
  String get whereMoneyWent;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded yet'**
  String get noExpensesYet;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @fertiliser.
  ///
  /// In en, this message translates to:
  /// **'Fertiliser'**
  String get fertiliser;

  /// No description provided for @pesticide.
  ///
  /// In en, this message translates to:
  /// **'Pesticide'**
  String get pesticide;

  /// No description provided for @labour.
  ///
  /// In en, this message translates to:
  /// **'Labour'**
  String get labour;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @soil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soil;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @watchOutFor.
  ///
  /// In en, this message translates to:
  /// **'Watch out for'**
  String get watchOutFor;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'ANSWER'**
  String get answer;

  /// No description provided for @officialSources.
  ///
  /// In en, this message translates to:
  /// **'Official sources'**
  String get officialSources;

  /// No description provided for @askAboutScheme.
  ///
  /// In en, this message translates to:
  /// **'Ask about any farmer scheme...'**
  String get askAboutScheme;

  /// No description provided for @noAlertsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No alerts right now'**
  String get noAlertsRightNow;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get kannada;

  /// No description provided for @diagnoses.
  ///
  /// In en, this message translates to:
  /// **'Diagnoses'**
  String get diagnoses;

  /// No description provided for @farmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get farmers;

  /// No description provided for @modelAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Model accuracy'**
  String get modelAccuracy;

  /// No description provided for @farmerRated.
  ///
  /// In en, this message translates to:
  /// **'Farmer rated'**
  String get farmerRated;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Showing saved data.'**
  String get noConnection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
