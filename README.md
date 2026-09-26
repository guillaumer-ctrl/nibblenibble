# nibblenibble

Suivi de la diversification alimentaire de bébé, en famille. App Flutter (Android, iOS à venir) connectée à Firebase (Auth, Firestore, Crashlytics) et Google AdMob.

## Prérequis

- Flutter SDK (voir `environment.sdk` dans `pubspec.yaml` pour la version exacte)
- Un projet Firebase (Auth + Cloud Firestore activés) — `android/app/google-services.json` (déjà présent dans ce repo) le lie au projet Firebase `nibblenibble`
- Pour un build **release** Android uniquement : un keystore de signature (voir ci-dessous)

## Lancer en développement

```
flutter pub get
flutter run
```

En debug, les publicités AdMob utilisent automatiquement les IDs de test de Google (jamais les vraies unités publicitaires) — voir `lib/widgets/banner_ad_widget.dart`.

## Configuration requise pour builder en release (Android)

Le build release lit `android/key.properties` (non versionné, voir `android/.gitignore`) pour signer l'APK/AAB avec le vrai keystore. Fichier attendu, à la racine de `android/` :

```properties
storePassword=<mot de passe du keystore>
keyPassword=<mot de passe de la clé>
keyAlias=<alias de la clé>
storeFile=<chemin absolu vers le fichier .jks>
```

⚠️ Si ce fichier est absent, `android/app/build.gradle.kts` **ne fait pas échouer le build** : il retombe silencieusement sur la signature debug. Toujours vérifier sa présence avant de builder pour la publication.

```
flutter analyze
flutter test
flutter build appbundle --release   # App Bundle pour le Play Store
```

## Variables/fichiers d'environnement

| Fichier | Rôle | Suivi par git ? |
|---|---|---|
| `android/app/google-services.json` | Config client Firebase (Android) | Oui — config publique, pas un secret |
| `android/key.properties` | Mots de passe du keystore de signature release | Non (gitignored) |
| Keystore `.jks` référencé par `key.properties` | Clé de signature release | Non (gitignored) |
| `ios/Runner/GoogleService-Info.plist` | Config client Firebase (iOS) | À ajouter quand le projet iOS sera configuré dans Firebase/AdMob — voir `TODO.md` |

Aucune variable d'environnement `.env` : la config native (Firebase, signature) passe entièrement par les fichiers ci-dessus, lus directement par Gradle/CocoaPods.

## Tests

```
flutter test
```

## CI

`.github/workflows/ci.yml` exécute `flutter analyze` + `flutter test` sur chaque push et pull request vers `main`.

## Suivi pré-lancement

Voir `TODO.md` à la racine du repo pour la liste vivante des tâches avant/après publication sur les stores.
