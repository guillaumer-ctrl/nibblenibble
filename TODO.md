# nibblenibble — To-do avant publication

Liste vivante : dis-moi quoi ajouter/cocher/supprimer et je la tiens à jour.

## Bloquant (Play Store)
- [ ] Formulaire "Data safety" (Play Console) — à faire par toi (compte Play Console)
- [x] Captures d'écran de la fiche Play Store — 15 visuels (5 écrans × FR/EN/ES, 810×1440, téléphone + titre) dans `graphics/marketing/`
- [x] Description courte (80 car.) et longue (4000 car.) de la fiche Play Store, en FR/EN/ES — `graphics/store-listing.md`
- [ ] Classification du contenu + fiche Play Store (upload description/captures, Data safety, Ads) — à faire par toi dans Play Console
- [ ] `contact@nibblenibble.app` : les emails arrivent bien mais partent en spam (réputation de domaine neuf) — marqué "non spam" + DMARC ajouté, à revérifier dans quelques jours que ça se stabilise

## Qualité / robustesse
- [ ] Règle Firestore : un membre lecture-seule peut modifier une réaction sans que la règle vérifie que le `foodId` à chaque index reste identique (seule la taille du tableau est vérifiée) — inexploitable via l'UI normale ; corriger proprement nécessiterait une Cloud Function (donc passer au plan Blaze), documenté dans firestore.rules en attendant
- [ ] `deleteBaby` laisse volontairement des notes orphelines et des `babyIds` obsolètes chez les autres membres — compromis assumé (pas de Cloud Functions sur le plan Spark), à garder en tête

## Améliorations produit (non bloquantes)
- [ ] Landing page `nibblenibble.app` : `index.html` a été supprimé (contenu obsolète — mentionnait des fonctionnalités retirées). Seules `privacy-policy.html` et `terms-of-service.html` restent en ligne (utilisées par l'app). À refaire de zéro si une vraie landing page est souhaitée plus tard.
- [ ] Pagination des repas passés (actuellement plafonné à 400 repas les plus récents pour borner le coût Firestore — largement suffisant à court terme, mais une vraie pagination/scroll infini serait plus propre à terme)

## iOS (décision prise : oui, on sort sur iOS)
- [x] Dossier `ios/` généré, config de base préparée (permissions, icônes, localisation FR/EN)
- [ ] Avoir accès à un Mac (Xcode ne tourne que sur macOS) — bloquant pour tout le reste ci-dessous
- [ ] Compte Apple Developer Program (99$/an)
- [ ] Créer l'app iOS dans Firebase console → télécharger `GoogleService-Info.plist` → l'ajouter au projet Xcode
- [ ] Créer l'app iOS dans AdMob → remplacer l'App ID de test dans `ios/Runner/Info.plist` (`GADApplicationIdentifier`) et l'ad unit bannière dans `banner_ad_widget.dart`
- [ ] Ajouter l'URL scheme Google Sign-In dans Info.plist (le `REVERSED_CLIENT_ID`, vient du `GoogleService-Info.plist`)
- [ ] Premier build/test réel sur Xcode (simulateur ou appareil)
- [ ] Fiche App Store Connect (description, captures d'écran, classification)

## Fait récemment
- [x] Publicités AdMob en place avec de vrais IDs : bannières (Accueil/Stats), App Open, Interstitiel (export PDF)
- [x] Feature graphics Play Store (1024×500) en FR/EN/ES, flatten 24-bit RGB (pas d'alpha)
- [x] 15 visuels marketing pour la fiche Play/App Store (5 écrans × FR/EN/ES) — `graphics/marketing/`
- [x] Champ "Date de début de diversification" rendu éditable (avec bouton effacer) sur le profil bébé — corrige les cas où la date déduite automatiquement était fausse
- [x] Âge en mois et nombre de jours de diversification retirés de l'écran profil bébé (redondants avec l'Accueil/Stats)
- [x] Note sur le repas entier (en plus de la note par aliment) — champ "Note sur le repas (optionnel)" dans le formulaire d'ajout/modif
- [x] Corrigé : la liste d'aliments dans "Ajouter un repas" gardait toujours l'ordre alphabétique français, peu importe la langue de l'app — trie maintenant sur le nom affiché dans la langue active
- [x] Corrigé : un premier repas loggé comme "à venir" pouvait mettre la date de diversification dans le futur (jours négatifs) — ne considère plus que les repas passés
- [x] Vitesse des animations de célébration (création compte/bébé) ralentie (600ms → 950ms, délai auto-avance 2200ms → 2600ms)
- [x] Audit pré-lancement : minification/obfuscation R8 réactivées en release (le bug WorkManager qui forçait à les désactiver venait de `flutter_local_notifications`, retiré avec la fonctionnalité notifications) + `proguard-rules.pro` ajouté
- [x] Audit pré-lancement : flux `watchMeals` plafonné à 400 repas (le plus récents) pour borner le coût Firestore/mémoire sur la durée
- [x] Audit pré-lancement : landing page (`index.html`) supprimée + CGU/politique de confidentialité nettoyées des mentions de fonctionnalités retirées (notifications, export CSV)
- [x] Corrigé : l'export CSV était vulnérable à l'injection de formule (un aliment/note commençant par `=`, `+`, `-` ou `@` s'exécuterait comme une formule Excel à l'ouverture) — neutralisé
- [x] Accessibilité : `Tooltip`/labels ajoutés sur tous les boutons icône-seule (supprimer un repas, modifier la note, annuler une invitation, menu "⋮", enregistrer le prénom)
- [x] Détection de doublon pour les aliments personnalisés (insensible aux accents/majuscules) — sélectionne l'existant au lieu d'en recréer un
- [x] Tests automatisés étendus (16 → 26) avec `fake_cloud_firestore` : repositories repas, aliments personnalisés, création/suppression en cascade d'un profil bébé
- [x] Thème explicitement figé en clair (`themeMode: ThemeMode.light`), documenté plutôt qu'implicite
- [x] Export CSV des repas passés, en plus du PDF (bouton "Exporter en CSV" dans Compte → Exporter mes données)
- [x] États d'erreur retravaillés : message convivial + bouton "Réessayer" partout (au lieu du texte d'exception brut) sur Accueil, Repas, Famille, Stats, et l'écran de connexion
- [x] Stats : chaque réaction (Aimé/Mitigé/Pas aimé) est dépliable pour voir la liste des aliments concernés
- [x] Règles Firestore publiées sur Firebase Console (customFoods + invitations débloqués)
- [x] Corrigé : l'inscription via Google forçait l'onboarding ("créer mon profil bébé") même pour un compte existant, avec risque de doublon de profil bébé
- [x] `acceptInvitation` rendu atomique (batch Firestore) — plus de risque de membre créé sans que l'invitation passe à "accepted"
- [x] `deleteBaby` supprime aussi les invitations orphelines (les règles l'autorisaient déjà, il manquait juste le code)
- [x] Suppression d'un repas depuis l'Accueil a maintenant l'undo (comme l'onglet Repas) — logique mutualisée dans un seul helper
- [x] Carte "invitation en attente" ne relit plus Firestore à chaque rebuild
- [x] Undo d'un repas restauré respecte la préférence "Rappels de repas"
- [x] Geste "appui long" redondant retiré du sélecteur de bébé
- [x] Retour d'erreur (snackbar) sur les actions famille : changer un rôle, retirer un membre, annuler une invitation, éditer la note de famille
- [x] Export PDF enrichi (infos bébé, résumé avec compteurs par réaction, points colorés, pied de page paginé)
- [x] Filtre/recherche sur les repas passés (par aliment ou note, insensible aux accents)
- [x] Crashlytics intégré
- [x] Indicateur hors-ligne (bandeau en haut de l'app)
- [x] Tests automatisés étendus (1 → 16 tests)
- [x] Message de consentement RGPD publié dans la console AdMob (couleurs + logo nibblenibble, bouton Refuser activé pour toute l'UE)
- [x] SDK de consentement RGPD/UMP intégré (formulaire au démarrage + "Préférences publicitaires" dans Compte)
- [x] Compte développeur Google Play actif
- [x] Bouton "Signaler un bug" (formulaire en app)
- [x] Undo après suppression d'un repas
- [x] Confirmation renforcée (taper le prénom) pour supprimer un profil bébé
- [x] Permission notifications non re-demandée si déjà accordée
