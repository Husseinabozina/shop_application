class AppEnvironment {
  AppEnvironment._();

  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue:
        'https://shopapp-29118-default-rtdb.firebaseio.com',
  );

  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyBWyn5fCqngGVU03wvRoBVFpyAd_CxfAL0',
  );

  static String get normalizedFirebaseDatabaseUrl {
    return firebaseDatabaseUrl.endsWith('/')
        ? firebaseDatabaseUrl.substring(0, firebaseDatabaseUrl.length - 1)
        : firebaseDatabaseUrl;
  }
}
