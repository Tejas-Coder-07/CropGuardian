// Crop Guardian - human error messages
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Firebase error codes are written for developers. A farmer who sees
// "FirebaseAuthException: [firebase_auth/invalid-credential]" learns nothing
// and assumes the app is broken. Every message here says what happened and
// what to do next.

class FriendlyError {
  static String from(Object error) {
    final raw = error.toString().toLowerCase();

    // Network first - it is the most common cause in the field.
    if (raw.contains('network') ||
        raw.contains('socket') ||
        raw.contains('timeout') ||
        raw.contains('unreachable') ||
        raw.contains('failed host lookup')) {
      return 'No internet connection. Check your mobile data and try again.';
    }

    if (raw.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (raw.contains('wrong-password') ||
        raw.contains('invalid-credential') ||
        raw.contains('invalid-login')) {
      return 'Email or password is incorrect. Please check and try again.';
    }
    if (raw.contains('invalid-email')) {
      return 'That email address does not look right. Please check it.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email. Try logging in.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too short. Use at least six characters.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (raw.contains('user-disabled')) {
      return 'This account has been disabled. Contact support for help.';
    }
    if (raw.contains('requires-recent-login')) {
      return 'Please log out and log in again to make this change.';
    }

    // Phone auth
    if (raw.contains('invalid-phone-number')) {
      return 'That phone number does not look right. Include the country code.';
    }
    if (raw.contains('invalid-verification-code')) {
      return 'That code is incorrect. Please check the SMS and try again.';
    }
    if (raw.contains('session-expired') || raw.contains('code-expired')) {
      return 'The code has expired. Please request a new one.';
    }
    if (raw.contains('quota-exceeded')) {
      return 'Too many SMS requests today. Please try email login instead.';
    }

    // Firestore
    if (raw.contains('permission-denied')) {
      return 'You do not have permission to do that.';
    }
    if (raw.contains('unavailable')) {
      return 'Service is temporarily unavailable. Please try again shortly.';
    }
    if (raw.contains('not-found')) {
      return 'That item no longer exists. It may have been removed.';
    }

    // Storage and uploads
    if (raw.contains('cloudinary') || raw.contains('upload')) {
      return 'Could not upload the photo. Check your connection and retry.';
    }

    // Anything unrecognised - still say something useful.
    return 'Something went wrong. Please try again in a moment.';
  }
}