import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "demo-api-key",
      appId: "demo-app-id",
      messagingSenderId: "demo-sender-id",
      projectId: "demo-project-id",
    );
  }
}
