import 'package:flutter/widgets.dart';

/// Hand-written FR/EN strings — no ARB/codegen, just a lookup keyed by the
/// app's current locale. `AppStrings.of(context)` reads it from
/// `Localizations.localeOf(context)`, which MaterialApp keeps in sync with
/// `localeProvider` (see providers/locale_provider.dart).
class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get _fr => locale.languageCode == 'fr';
  bool get _es => locale.languageCode == 'es';
  bool get isFrench => _fr;
  bool get isSpanish => _es;

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  String _t(String fr, String en, [String? es]) =>
      _fr ? fr : (_es ? (es ?? en) : en);

  /// For DateFormat/showDatePicker/showTimePicker, which take an intl
  /// locale string rather than a Flutter Locale.
  String get intlLocale => _fr ? 'fr_FR' : (_es ? 'es_ES' : 'en_US');
  Locale get datePickerLocale => _fr
      ? const Locale('fr', 'FR')
      : (_es ? const Locale('es', 'ES') : const Locale('en', 'US'));

  // DateFormat patterns — French embeds "à" as a literal, which has no
  // place in an English pattern.
  String get dateTimePattern => _fr
      ? "EEEE d MMMM 'à' HH:mm"
      : (_es ? "EEEE d 'de' MMMM, HH:mm" : 'EEEE, MMMM d, h:mm a');
  String get longDateTimePattern => _fr
      ? "EEEE d MMMM yyyy 'à' HH:mm"
      : (_es
            ? "EEEE d 'de' MMMM 'de' yyyy, HH:mm"
            : 'EEEE, MMMM d yyyy, h:mm a');
  String get dateOnlyPattern => _fr
      ? 'd MMMM yyyy'
      : (_es ? "d 'de' MMMM 'de' yyyy" : 'MMMM d, yyyy');
  String get shortDateTimePattern =>
      _fr ? "d MMM 'à' HH:mm" : (_es ? 'd MMM, HH:mm' : 'MMM d, h:mm a');

  // --- Common -----------------------------------------------------------
  String get cancel => _t('Annuler', 'Cancel', 'Cancelar');
  String get save => _t('Enregistrer', 'Save', 'Guardar');
  String get delete => _t('Supprimer', 'Delete', 'Eliminar');
  String get or => _t('ou', 'or', 'o');
  String get required => _t('Requis', 'Required', 'Obligatorio');
  String get errorPrefix => _t('Erreur : ', 'Error: ', 'Error: ');
  String get genericErrorMessage => _t(
    'Une erreur est survenue.',
    'Something went wrong.',
    'Ha ocurrido un error.',
  );
  String get retry => _t('Réessayer', 'Retry', 'Reintentar');
  String get genericSaveError => _t(
    'Impossible d\'enregistrer pour l\'instant.',
    'Unable to save right now.',
    'No se puede guardar en este momento.',
  );

  // --- Welcome / Auth -----------------------------------------------------
  String get welcomeTagline => _t(
    'Accompagnez la diversification de bébé et partagez chaque découverte '
        'en toute sérénité.',
    'Support your baby\'s food diversification journey and share every '
        'discovery with peace of mind.',
    'Acompaña la diversificación alimentaria de tu bebé y comparte cada '
        'descubrimiento con total tranquilidad.',
  );
  String get getStarted => _t('Commencer', 'Get started', 'Empezar');
  String get alreadyHaveAccount => _t(
    'J\'ai déjà un compte',
    'I already have an account',
    'Ya tengo una cuenta',
  );
  String get signIn => _t('Connexion', 'Sign in', 'Iniciar sesión');
  String get createAccount =>
      _t('Créer un compte', 'Create an account', 'Crear una cuenta');
  String get email => _t('Email', 'Email', 'Correo electrónico');
  String get password => _t('Mot de passe', 'Password', 'Contraseña');
  String get invalidEmail =>
      _t('Email invalide', 'Invalid email', 'Correo electrónico inválido');
  String get forgotPassword => _t(
    'Mot de passe oublié ?',
    'Forgot password?',
    '¿Olvidaste tu contraseña?',
  );
  String get signInButton =>
      _t('Se connecter', 'Sign in', 'Iniciar sesión');
  String get continueWithGoogle => _t(
    'Continuer avec Google',
    'Continue with Google',
    'Continuar con Google',
  );
  String get enterEmailForReset => _t(
    'Renseigne ton email ci-dessus pour recevoir le lien.',
    'Enter your email above to receive the link.',
    'Escribe tu correo electrónico arriba para recibir el enlace.',
  );
  String resetEmailSent(String email) => _t(
    'Email de réinitialisation envoyé à $email.',
    'Password reset email sent to $email.',
    'Correo de restablecimiento enviado a $email.',
  );
  String get resetEmailFailed => _t(
    'Impossible d\'envoyer l\'email pour le moment.',
    'Unable to send the email right now.',
    'No se puede enviar el correo en este momento.',
  );
  String get firstName => _t('Prénom', 'First name', 'Nombre');
  String get minSixChars => _t(
    '6 caractères minimum',
    'At least 6 characters',
    'Al menos 6 caracteres',
  );
  String get createMyAccount =>
      _t('Créer mon compte', 'Create my account', 'Crear mi cuenta');
  String get noAccountYet => _t(
    'Pas encore de compte ? ',
    'No account yet? ',
    '¿Aún no tienes cuenta? ',
  );
  String get createAccountLink =>
      _t('Créer un compte', 'Create an account', 'Crear una cuenta');
  String get alreadyHaveAccountLink => _t(
    'Déjà un compte ? ',
    'Already have an account? ',
    '¿Ya tienes una cuenta? ',
  );
  String get signInLink => _t('Se connecter', 'Sign in', 'Iniciar sesión');
  String get signInCancelled => _t(
    'Connexion annulée.',
    'Sign-in cancelled.',
    'Inicio de sesión cancelado.',
  );
  String get googleSignInUnavailable => _t(
    'Connexion Google indisponible pour l\'instant.',
    'Google sign-in unavailable right now.',
    'El inicio de sesión con Google no está disponible en este momento.',
  );
  String get googleSignInFailed => _t(
    'Connexion Google impossible pour le moment, réessaie.',
    'Google sign-in isn\'t working right now, try again.',
    'El inicio de sesión con Google no funciona en este momento, inténtalo de nuevo.',
  );

  // Firebase Auth error codes.
  String get authEmailAlreadyInUse => _t(
    'Un compte existe déjà avec cet email.',
    'An account already exists with this email.',
    'Ya existe una cuenta con este correo electrónico.',
  );
  String get authInvalidEmail => _t(
    'Adresse email invalide.',
    'Invalid email address.',
    'Dirección de correo electrónico inválida.',
  );
  String get authWeakPassword => _t(
    'Mot de passe trop court (6 caractères minimum).',
    'Password too short (6 characters minimum).',
    'Contraseña demasiado corta (mínimo 6 caracteres).',
  );
  String get authWrongCredentials => _t(
    'Email ou mot de passe incorrect.',
    'Incorrect email or password.',
    'Correo electrónico o contraseña incorrectos.',
  );
  String get authUserDisabled => _t(
    'Ce compte a été désactivé.',
    'This account has been disabled.',
    'Esta cuenta ha sido deshabilitada.',
  );
  String get authTooManyRequests => _t(
    'Trop de tentatives, réessaie plus tard.',
    'Too many attempts, try again later.',
    'Demasiados intentos, inténtalo de nuevo más tarde.',
  );
  String get authNetworkError => _t(
    'Problème de connexion réseau.',
    'Network connection problem.',
    'Problema de conexión de red.',
  );
  String get authGenericError => _t(
    'Une erreur est survenue, réessaie.',
    'Something went wrong, try again.',
    'Ha ocurrido un error, inténtalo de nuevo.',
  );

  /// Maps a Firebase Auth error code (or one of this app's synthetic
  /// google-sign-in-* codes) to a displayable, localized message.
  String authErrorMessage(String code) => switch (code) {
    'email-already-in-use' => authEmailAlreadyInUse,
    'invalid-email' => authInvalidEmail,
    'weak-password' => authWeakPassword,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => authWrongCredentials,
    'user-disabled' => authUserDisabled,
    'too-many-requests' => authTooManyRequests,
    'network-request-failed' => authNetworkError,
    'requires-recent-login' => authRequiresRecentLogin,
    'google-sign-in-unavailable' => googleSignInUnavailable,
    'google-sign-in-cancelled' => signInCancelled,
    'google-sign-in-failed' => googleSignInFailed,
    _ => authGenericError,
  };

  String get authRequiresRecentLogin => _t(
    'Reconnecte-toi puis réessaie tout de suite après — Firebase exige '
        'une connexion récente pour supprimer un compte.',
    'Sign in again and retry right away — Firebase requires a recent '
        'sign-in to delete an account.',
    'Vuelve a iniciar sesión e inténtalo de nuevo justo después — Firebase '
        'requiere un inicio de sesión reciente para eliminar una cuenta.',
  );

  // --- Onboarding choice --------------------------------------------------
  String get welcome => _t('Bienvenue', 'Welcome', 'Bienvenido');
  String get gettingStarted =>
      _t('Pour commencer', 'Getting started', 'Para empezar');
  String get onboardingChoiceQuestion => _t(
    'Tu crées le profil de ton bébé, ou quelqu\'un t\'a déjà invité·e à '
        'suivre le sien ?',
    'Are you creating your baby\'s profile, or has someone already '
        'invited you to follow theirs?',
    '¿Vas a crear el perfil de tu bebé, o alguien ya te invitó a seguir '
        'el suyo?',
  );
  String get addMyBabyProfile => _t(
    'Ajouter le profil de mon bébé',
    'Add my baby\'s profile',
    'Añadir el perfil de mi bebé',
  );
  String get iReceivedAnInvitation => _t(
    'J\'ai reçu une invitation',
    'I received an invitation',
    'He recibido una invitación',
  );
  String seeMyInvitation(int count) => _t(
    'Voir mon invitation ($count)',
    'See my invitation ($count)',
    'Ver mi invitación ($count)',
  );

  // --- Account created / profile created celebration -----------------------
  String get accountCreatedTitle => _t('Bienvenue !', 'Welcome!', '¡Bienvenido!');
  String get accountCreatedSubtitle => _t(
    'Ton compte est maintenant prêt. Passons à la création du profil de '
        'bébé.',
    'Your account is now ready. Let\'s move on to creating your baby\'s '
        'profile.',
    'Tu cuenta ya está lista. Pasemos a crear el perfil de tu bebé.',
  );
  String get profileCreatedTitle => _t(
    'Profil créé avec succès !',
    'Profile created successfully!',
    '¡Perfil creado con éxito!',
  );
  String get profileCreatedSubtitle => _t(
    'Le profil de bébé a bien été enregistré. Vous pouvez dès à présent '
        'suivre sa diversification alimentaire pas à pas !',
    'Your baby\'s profile has been saved. You can now follow their food '
        'diversification journey step by step!',
    'El perfil del bebé se ha guardado correctamente. Ya puedes seguir su '
        'diversificación alimentaria paso a paso.',
  );

  // --- Invitations screen ---------------------------------------------------
  String get invitationsReceived => _t(
    'Invitations reçues',
    'Received invitations',
    'Invitaciones recibidas',
  );
  String invitationCardSubtitle(String babyName) => _t(
    'Vous avez été invité·e à suivre la diversification alimentaire de '
        '$babyName.',
    'You\'ve been invited to follow $babyName\'s food diversification '
        'journey.',
    'Has sido invitado·a a seguir la diversificación alimentaria de '
        '$babyName.',
  );
  String get noInvitationsFound => _t(
    'Aucune invitation en attente pour l\'instant.',
    'No pending invitations right now.',
    'No hay invitaciones pendientes por el momento.',
  );
  String get backToBabyCreation => _t(
    'Revenir à la création du profil de bébé',
    'Back to creating a baby profile',
    'Volver a la creación del perfil del bebé',
  );

  // --- Add baby -----------------------------------------------------------
  String get addBaby => _t('Ajouter un bébé', 'Add a baby', 'Añadir un bebé');
  String get birthDate =>
      _t('Date de naissance', 'Date of birth', 'Fecha de nacimiento');
  String get chooseADate =>
      _t('Choisir une date', 'Choose a date', 'Elegir una fecha');
  String get chooseBirthDate => _t(
    'Choisis une date de naissance.',
    'Choose a date of birth.',
    'Elige una fecha de nacimiento.',
  );
  String get createProfile =>
      _t('Créer le profil', 'Create profile', 'Crear perfil');
  String get continueLabel => _t('Continuer', 'Continue', 'Continuar');
  String get createProfileFailed => _t(
    'Impossible de créer le profil pour l\'instant.',
    'Unable to create the profile right now.',
    'No se puede crear el perfil en este momento.',
  );

  // --- Family / invitations -----------------------------------------------
  String get family => _t('Famille', 'Family', 'Familia');
  String get addBabyToManageFamily => _t(
    'Ajoute un profil bébé pour gérer la famille.',
    'Add a baby profile to manage the family.',
    'Añade un perfil de bebé para gestionar la familia.',
  );
  String inviteFamilyIntro(String babyName) => _t(
    'Invite les proches qui suivent la diversification de $babyName — tu '
        'pourras toujours le faire plus tard depuis Compte > Famille.',
    'Invite the people who\'ll follow $babyName\'s food journey — you '
        'can always do this later from Account > Family.',
    'Invita a las personas cercanas que seguirán la diversificación de '
        '$babyName — siempre podrás hacerlo más tarde desde Cuenta > Familia.',
  );
  String get inviteALovedOne =>
      _t('Inviter un proche', 'Invite someone', 'Invitar a alguien');
  String get roleExplainer => _t(
    'Lecture seule : consulte les repas et ajoute les réactions du bébé. '
        'Administrateur : gère aussi les repas et la famille.',
    'Read-only: view meals and add the baby\'s reactions. Admin: also '
        'manages meals and the family.',
    'Solo lectura: consulta las comidas y añade las reacciones del bebé. '
        'Administrador: también gestiona las comidas y la familia.',
  );
  String get readOnly => _t('Lecture seule', 'Read-only', 'Solo lectura');
  String get admin => _t('Administrateur', 'Admin', 'Administrador');
  String get invite => _t('Inviter', 'Invite', 'Invitar');
  String invitationSentTo(String email) => _t(
    'Invitation envoyée à $email.',
    'Invitation sent to $email.',
    'Invitación enviada a $email.',
  );
  String get invitationSendFailed => _t(
    'Impossible d\'envoyer l\'invitation.',
    'Unable to send the invitation.',
    'No se puede enviar la invitación.',
  );
  String get invalidEmailAddress => _t(
    'Adresse email invalide.',
    'Invalid email address.',
    'Dirección de correo electrónico inválida.',
  );
  String get pendingInvitations => _t(
    'Invitations en attente',
    'Pending invitations',
    'Invitaciones pendientes',
  );
  String get pending => _t('En attente', 'Pending', 'Pendiente');
  String get familyMembers =>
      _t('Membres de la famille', 'Family members', 'Miembros de la familia');
  String get me => _t('(moi)', '(me)', '(yo)');
  String get fallbackDisplayName => _t('Moi', 'Me', 'Yo');
  String get switchToReadOnly => _t(
    'Passer en lecture seule',
    'Switch to read-only',
    'Cambiar a solo lectura',
  );
  String get switchToAdmin => _t(
    'Passer administrateur',
    'Switch to admin',
    'Cambiar a administrador',
  );
  String get remove => _t('Retirer', 'Remove', 'Quitar');
  String removeMemberTitle(String name) =>
      _t('Retirer $name ?', 'Remove $name?', '¿Quitar a $name?');
  String removeMemberMessage(String name) => _t(
    '$name perdra l\'accès à ce profil bébé.',
    '$name will lose access to this baby profile.',
    '$name perderá el acceso a este perfil de bebé.',
  );
  String get finish => _t('Terminer', 'Finish', 'Finalizar');
  String get updateRoleFailed => _t(
    'Impossible de modifier ce rôle pour l\'instant.',
    'Unable to change this role right now.',
    'No se puede cambiar este rol en este momento.',
  );
  String get removeMemberFailed => _t(
    'Impossible de retirer ce membre pour l\'instant.',
    'Unable to remove this member right now.',
    'No se puede quitar a este miembro en este momento.',
  );
  String get cancelInvitationFailed => _t(
    'Impossible d\'annuler cette invitation pour l\'instant.',
    'Unable to cancel this invitation right now.',
    'No se puede cancelar esta invitación en este momento.',
  );
  String get addNoteFailed => _t(
    'Impossible d\'enregistrer la note pour l\'instant.',
    'Unable to save the note right now.',
    'No se puede guardar la nota en este momento.',
  );
  String get processInvitationFailed => _t(
    'Impossible de traiter l\'invitation pour l\'instant.',
    'Unable to process the invitation right now.',
    'No se puede procesar la invitación en este momento.',
  );
  String get decline => _t('Refuser', 'Decline', 'Rechazar');
  String get accept => _t('Accepter', 'Accept', 'Aceptar');
  String get invitationAccepted => _t(
    'Invitation acceptée.',
    'Invitation accepted.',
    'Invitación aceptada.',
  );
  String joinBabyProfile(String babyName) => _t(
    'Rejoindre le profil de $babyName',
    'Join $babyName\'s profile',
    'Unirte al perfil de $babyName',
  );
  String get aBabyProfile => _t('un profil bébé', 'a baby profile', 'un perfil de bebé');

  // --- Home ---------------------------------------------------------------
  String hello(String name) =>
      _t('Bonjour $name', 'Hello $name', 'Hola $name');
  String babyAgeSummary(String name, int months) => _t(
    '$name a $months mois',
    '$name is $months months old',
    '$name tiene $months meses',
  );
  String diversificationDaysSuffix(int days) => _t(
    ' · $days jours de diversification',
    ' · $days days into diversification',
    ' · $days días de diversificación',
  );
  String get addMeal => _t('Ajouter un repas', 'Add a meal', 'Añadir una comida');
  String get addShort => _t('Ajouter', 'Add', 'Añadir');
  String get upcomingMeals =>
      _t('Prochains repas', 'Upcoming meals', 'Próximas comidas');
  String get noBabyYetTitle => _t(
    'Aucun profil bébé pour le moment.',
    'No baby profile yet.',
    'Aún no hay ningún perfil de bebé.',
  );
  String get noBabyYetSubtitle => _t(
    'Crée le profil de ton bébé pour commencer à suivre sa '
        'diversification.',
    'Create your baby\'s profile to start tracking their food journey.',
    'Crea el perfil de tu bebé para empezar a seguir su diversificación '
        'alimentaria.',
  );
  String get profileOfThisBaby => _t(
    'Profil de ce bébé',
    'This baby\'s profile',
    'Perfil de este bebé',
  );
  String get deleteMealTitle => _t(
    'Supprimer ce repas ?',
    'Delete this meal?',
    '¿Eliminar esta comida?',
  );
  String get deleteMealMessage => _t(
    'Cette action est définitive et supprimera les aliments et réactions '
        'associés.',
    'This is permanent and will delete the associated foods and '
        'reactions.',
    'Esta acción es definitiva y eliminará los alimentos y reacciones '
        'asociados.',
  );
  String get mealDeletedUndo =>
      _t('Repas supprimé.', 'Meal deleted.', 'Comida eliminada.');
  String get undo => _t('Annuler', 'Undo', 'Deshacer');
  String get mealRestoreFailed => _t(
    'Impossible de restaurer ce repas.',
    'Unable to restore this meal.',
    'No se puede restaurar esta comida.',
  );
  String get signOut => _t('Se déconnecter', 'Sign out', 'Cerrar sesión');
  String get offlineBanner => _t(
    'Hors ligne — certaines actions seront synchronisées plus tard.',
    'Offline — some actions will sync later.',
    'Sin conexión — algunas acciones se sincronizarán más tarde.',
  );

  // --- Nav ------------------------------------------------------------
  String get navHome => _t('Accueil', 'Home', 'Inicio');
  String get navMeals => _t('Repas', 'Meals', 'Comidas');
  String get navStats => _t('Stats', 'Stats', 'Estadísticas');
  String get navAccount => _t('Compte', 'Account', 'Cuenta');

  // --- Meals list -----------------------------------------------------
  String get upcoming => _t('À venir', 'Upcoming', 'Próximas');
  String get past => _t('Passés', 'Past', 'Pasadas');
  String get noUpcomingMeals => _t(
    'Aucun repas à venir planifié.',
    'No upcoming meals planned.',
    'No hay comidas próximas planificadas.',
  );
  String get noMealsRecorded => _t(
    'Aucun repas enregistré pour le moment.',
    'No meals recorded yet.',
    'Aún no hay comidas registradas.',
  );
  String get searchPastMealsHint => _t(
    'Rechercher un aliment ou une note…',
    'Search a food or note…',
    'Buscar un alimento o una nota…',
  );
  String get noMealsMatchSearch => _t(
    'Aucun repas ne correspond à la recherche.',
    'No meals match your search.',
    'Ninguna comida coincide con la búsqueda.',
  );

  // --- Meal form --------------------------------------------------------
  String get addMealTitle => _t('Ajouter un repas', 'Add a meal', 'Añadir una comida');
  String get editMealTitle =>
      _t('Modifier le repas', 'Edit meal', 'Editar comida');
  String get dateAndTime => _t('Date et heure', 'Date & time', 'Fecha y hora');
  String get chooseDateAndTime => _t(
    'Choisir la date et l\'heure',
    'Choose the date & time',
    'Elegir la fecha y hora',
  );
  String get chooseDateAndTimeFirst => _t(
    'Choisis d\'abord la date et l\'heure du repas.',
    'Choose the meal\'s date & time first.',
    'Elige primero la fecha y hora de la comida.',
  );
  String get pastMealHint => _t(
    'Repas passé — les réactions sont modifiables ci-dessous',
    'Past meal — reactions can be edited below',
    'Comida pasada — las reacciones se pueden editar abajo',
  );
  String get upcomingMealHint => _t(
    'Repas à venir — pas de réaction à renseigner pour l\'instant',
    'Upcoming meal — no reaction to record yet',
    'Comida próxima — aún no hay reacción que registrar',
  );
  String get searchAFood =>
      _t('Rechercher un aliment', 'Search for a food', 'Buscar un alimento');
  String get addAtLeastOneFood => _t(
    'Ajoute au moins un aliment.',
    'Add at least one food.',
    'Añade al menos un alimento.',
  );
  String get mealUpdated =>
      _t('Repas mis à jour.', 'Meal updated.', 'Comida actualizada.');
  String get mealAdded =>
      _t('Repas ajouté.', 'Meal added.', 'Comida añadida.');
  String get saveMealFailed => _t(
    'Impossible d\'enregistrer le repas pour l\'instant.',
    'Unable to save the meal right now.',
    'No se puede guardar la comida en este momento.',
  );
  String addCustomFoodPrompt(String name) => _t(
    'Ajouter « $name » comme nouvel aliment',
    'Add "$name" as a new food',
    'Añadir "$name" como nuevo alimento',
  );
  String addCustomFoodTitle(String name) => _t(
    'Catégorie de « $name »',
    'Category for "$name"',
    'Categoría de "$name"',
  );
  String get addCustomFoodFailed => _t(
    'Impossible d\'ajouter cet aliment pour l\'instant.',
    'Unable to add this food right now.',
    'No se puede añadir este alimento en este momento.',
  );
  String customFoodAlreadyExists(String name) => _t(
    '« $name » existe déjà — sélectionné.',
    '"$name" already exists — selected it.',
    '"$name" ya existe — seleccionado.',
  );
  String get theirReaction => _t('Sa réaction', 'Their reaction', 'Su reacción');
  String get noteOptional =>
      _t('Note (optionnel)', 'Note (optional)', 'Nota (opcional)');
  String saveWithCount(int count) => _t(
    'Enregistrer ($count)',
    'Save ($count)',
    'Guardar ($count)',
  );
  String get saveReactions => _t(
    'Enregistrer les réactions',
    'Save reactions',
    'Guardar reacciones',
  );
  String previousReactionLabel(String reaction) => _t(
    'La dernière fois : $reaction',
    'Last time: $reaction',
    'La última vez: $reaction',
  );
  String usedTimesCount(int count) => count == 1
      ? _t('Déjà utilisé 1 fois', 'Already used 1 time', 'Ya usado 1 vez')
      : _t(
          'Déjà utilisé $count fois',
          'Already used $count times',
          'Ya usado $count veces',
        );

  // --- Stats --------------------------------------------------------------
  String get statistics => _t('Statistiques', 'Statistics', 'Estadísticas');
  String get foodsTried =>
      _t('aliments essayés', 'foods tried', 'alimentos probados');
  String get diversificationDaysLabel => _t(
    'jours de diversification',
    'days into diversification',
    'días de diversificación',
  );
  String get reactions => _t('Réactions', 'Reactions', 'Reacciones');
  String get noReactionsYet => _t(
    'Pas encore de réactions enregistrées.',
    'No reactions recorded yet.',
    'Aún no hay reacciones registradas.',
  );
  String get foodsTriedSectionTitle =>
      _t('Aliments essayés', 'Foods tried', 'Alimentos probados');
  String get nothingToShowYet => _t(
    'Rien à afficher pour le moment.',
    'Nothing to show yet.',
    'Nada que mostrar por el momento.',
  );

  // --- Account ------------------------------------------------------------
  String get myAccount => _t('Mon compte', 'My account', 'Mi cuenta');
  String get myProfile => _t('Mon profil', 'My profile', 'Mi perfil');
  String get nameUpdated =>
      _t('Nom mis à jour.', 'Name updated.', 'Nombre actualizado.');
  String get firstNameHelper => _t(
    'Le prénom affiché aux autres membres de la famille.',
    'The name shown to your other family members.',
    'El nombre que verán los demás miembros de la familia.',
  );
  String get accountFamilyDataSection =>
      _t('Famille & données', 'Family & data', 'Familia y datos');
  String get accountPreferencesSection =>
      _t('Préférences', 'Preferences', 'Preferencias');
  String get accountSupportLegalSection =>
      _t('Assistance & légal', 'Support & legal', 'Soporte y legal');
  String get notifications =>
      _t('Notifications', 'Notifications', 'Notificaciones');
  String get exportAsPdf =>
      _t('Exporter en PDF', 'Export as PDF', 'Exportar como PDF');
  String get exportData =>
      _t('Exporter mes données', 'Export my data', 'Exportar mis datos');
  String get importData =>
      _t('Importer mes données', 'Import my data', 'Importar mis datos');
  String get exportDataNote => _t(
    'La sauvegarde contient tout l\'historique : repas, aliments et réactions.',
    'The backup contains the full history: meals, foods and reactions.',
    'La copia de seguridad contiene todo el historial: comidas, alimentos y reacciones.',
  );
  String get importDataNote => _t(
    'L\'import remplace les données actuelles de l\'appareil. Pensez à exporter une sauvegarde avant de continuer.',
    'Importing replaces the data currently on this device. Consider exporting a backup first.',
    'Importar reemplaza los datos actuales del dispositivo. Considera exportar una copia de seguridad antes de continuar.',
  );
  String get theme => _t('Thème', 'Theme', 'Tema');
  String get themeLight => _t('Clair', 'Light', 'Claro');
  String get themeDark => _t('Sombre', 'Dark', 'Oscuro');
  String get themeSystem => _t('Système', 'System', 'Sistema');
  String get language => _t('Langue', 'Language', 'Idioma');
  String get privacyPolicy => _t(
    'Politique de confidentialité',
    'Privacy policy',
    'Política de privacidad',
  );
  String get termsOfService => _t(
    'Conditions d\'utilisation',
    'Terms of service',
    'Términos del servicio',
  );
  String get openLinkFailed => _t(
    'Impossible d\'ouvrir ce lien pour le moment.',
    'Unable to open this link right now.',
    'No se puede abrir este enlace en este momento.',
  );
  String get adPreferences => _t(
    'Préférences publicitaires',
    'Ad preferences',
    'Preferencias de anuncios',
  );
  String get reportBug =>
      _t('Signaler un bug', 'Report a bug', 'Reportar un error');
  String get bugReportSubject => _t(
    'Signalement de bug - nibblenibble',
    'Bug report - nibblenibble',
    'Reporte de error - nibblenibble',
  );
  String get bugReportBodyIntro => _t(
    'Décris le problème rencontré (ce que tu as fait, ce qui s\'est passé, '
        'ce que tu attendais).',
    'Describe the issue (what you did, what happened, what you expected).',
    'Describe el problema que encontraste (qué hiciste, qué pasó, qué '
        'esperabas).',
  );
  String get bugReportEmailLabel =>
      _t('Ton email', 'Your email', 'Tu correo electrónico');
  String get bugReportDescriptionLabel =>
      _t('Description', 'Description', 'Descripción');
  String get bugReportDescriptionHint => _t(
    'Ce que tu as fait, ce qui s\'est passé, ce que tu attendais...',
    'What you did, what happened, what you expected...',
    'Qué hiciste, qué pasó, qué esperabas...',
  );
  String get bugReportEmptyDescription => _t(
    'Décris le problème avant d\'envoyer.',
    'Describe the issue before sending.',
    'Describe el problema antes de enviar.',
  );
  String get bugReportSend => _t('Envoyer', 'Send', 'Enviar');
  String get deleteMyAccount => _t(
    'Supprimer mon compte',
    'Delete my account',
    'Eliminar mi cuenta',
  );
  String get deleteAccountFailed => _t(
    'Impossible de supprimer le compte pour le moment.',
    'Unable to delete the account right now.',
    'No se puede eliminar la cuenta en este momento.',
  );
  String get deleteAccountTitle => _t(
    'Supprimer ton compte ?',
    'Delete your account?',
    '¿Eliminar tu cuenta?',
  );
  String get deleteAccountMessage => _t(
    'Cette action est définitive. Tu perdras l\'accès à tous les '
        'profils bébé associés à ce compte.',
    'This is permanent. You\'ll lose access to every baby profile tied '
        'to this account.',
    'Esta acción es definitiva. Perderás el acceso a todos los perfiles '
        'de bebé asociados a esta cuenta.',
  );
  String get cannotDeleteAccountTitle => _t(
    'Impossible de supprimer le compte',
    'Can\'t delete the account',
    'No se puede eliminar la cuenta',
  );
  String cannotDeleteAccountMessage(String babyName) => _t(
    'Tu es le seul administrateur de "$babyName". Supprime ce profil ou '
        'transmets les droits admin à quelqu\'un d\'autre (dans Famille) '
        'avant de supprimer ton compte.',
    'You\'re the only admin of "$babyName". Delete that profile or '
        'hand admin rights to someone else (in Family) before deleting '
        'your account.',
    'Eres el único administrador de "$babyName". Elimina ese perfil o '
        'cede los derechos de administrador a otra persona (en Familia) '
        'antes de eliminar tu cuenta.',
  );
  String get understood => _t('Compris', 'Got it', 'Entendido');

  // --- Baby profile ---------------------------------------------------
  String get babyProfile => _t('Profil bébé', 'Baby profile', 'Perfil del bebé');
  String get sex => _t('Sexe', 'Sex', 'Sexo');
  String get months => _t('mois', 'months', 'meses');
  String get profileUpdated =>
      _t('Profil mis à jour.', 'Profile updated.', 'Perfil actualizado.');
  String get profileUpdateFailed => _t(
    'Impossible de mettre à jour le profil.',
    'Unable to update the profile.',
    'No se puede actualizar el perfil.',
  );
  String get deleteThisBaby =>
      _t('Supprimer ce bébé', 'Delete this baby', 'Eliminar este bebé');
  String deleteBabyTitle(String name) =>
      _t('Supprimer $name ?', 'Delete $name?', '¿Eliminar a $name?');
  String get deleteBabyMessage => _t(
    'Cette action est définitive : tous les repas et notes associés à ce '
        'profil seront perdus, et la famille entière perdra son accès.',
    'This is permanent: every meal and note tied to this profile will '
        'be lost, and the whole family will lose access.',
    'Esta acción es definitiva: se perderán todas las comidas y notas '
        'asociadas a este perfil, y toda la familia perderá el acceso.',
  );
  String get deleteBabyFailed => _t(
    'Impossible de supprimer ce profil pour le moment.',
    'Unable to delete this profile right now.',
    'No se puede eliminar este perfil en este momento.',
  );
  String typeToConfirmHint(String name) => _t(
    'Pour confirmer, tape "$name" ci-dessous :',
    'To confirm, type "$name" below:',
    'Para confirmar, escribe "$name" abajo:',
  );

  // --- Export PDF -----------------------------------------------------
  String get generatePdfIntro => _t(
    'Génère un récapitulatif des repas passés à partager avec le '
        'pédiatre.',
    'Generate a summary of past meals to share with the pediatrician.',
    'Genera un resumen de las comidas pasadas para compartir con el '
        'pediatra.',
  );
  String get generatePdf =>
      _t('Générer le PDF', 'Generate PDF', 'Generar PDF');
  String get generating => _t('Génération…', 'Generating…', 'Generando…');
  String get generatePdfFailed => _t(
    'Impossible de générer le PDF pour l\'instant.',
    'Unable to generate the PDF right now.',
    'No se puede generar el PDF en este momento.',
  );
  String get exportAsCsv =>
      _t('Exporter en CSV', 'Export as CSV', 'Exportar como CSV');
  String get generatingCsv => _t('Génération…', 'Generating…', 'Generando…');
  String get generateCsvFailed => _t(
    'Impossible de générer le CSV pour l\'instant.',
    'Unable to generate the CSV right now.',
    'No se puede generar el CSV en este momento.',
  );
  String get csvIntro => _t(
    'Exporte les données brutes des repas passés — utile pour une sauvegarde ou pour les ouvrir dans un tableur.',
    'Export the raw data of past meals — useful for a backup or to open in a spreadsheet.',
    'Exporta los datos en bruto de las comidas pasadas — útil para una copia de seguridad o para abrirlos en una hoja de cálculo.',
  );
  String get csvHeaderDate => _t('Date', 'Date', 'Fecha');
  String get csvHeaderFood => _t('Aliment', 'Food', 'Alimento');
  String get csvHeaderCategory => _t('Catégorie', 'Category', 'Categoría');
  String get csvHeaderReaction => _t('Réaction', 'Reaction', 'Reacción');
  String get csvHeaderNote => _t('Note', 'Note', 'Nota');
  String get exportAsJson => _t(
    'Exporter en sauvegarde (JSON)',
    'Export as backup (JSON)',
    'Exportar como copia de seguridad (JSON)',
  );
  String get generatingJson => _t('Génération…', 'Generating…', 'Generando…');
  String get generateJsonFailed => _t(
    'Impossible de générer la sauvegarde pour l\'instant.',
    'Unable to generate the backup right now.',
    'No se puede generar la copia de seguridad en este momento.',
  );
  String get jsonBackupIntro => _t(
    'Exporte une sauvegarde complète (profil, repas, notes) que vous '
        'pourrez réimporter plus tard, par exemple après une réinstallation.',
    'Export a full backup (profile, meals, notes) that you can import '
        'again later, e.g. after reinstalling the app.',
    'Exporta una copia de seguridad completa (perfil, comidas, notas) '
        'que podrás volver a importar más tarde, por ejemplo tras '
        'reinstalar la app.',
  );

  // --- Import data ---------------------------------------------------
  String get dataScreenTitle => _t('Données', 'Data', 'Datos');
  String get jsonImportIntro => _t(
    'Importe une sauvegarde JSON générée par "Exporter en sauvegarde". '
        'Un nouveau profil bébé sera créé avec ces données.',
    'Import a JSON backup generated by "Export as backup". A new baby '
        'profile will be created with this data.',
    'Importa una copia de seguridad JSON generada por "Exportar como '
        'copia de seguridad". Se creará un nuevo perfil de bebé con estos '
        'datos.',
  );
  String get csvImportIntro => _t(
    'Importe un CSV de repas généré par "Exporter en CSV" — les repas sont '
        'ajoutés au bébé actuellement sélectionné.',
    'Import a meals CSV generated by "Export as CSV" — meals are added to '
        'the currently selected baby.',
    'Importa un CSV de comidas generado por "Exportar como CSV" — las '
        'comidas se añaden al bebé actualmente seleccionado.',
  );
  String get chooseJsonFileToImport => _t(
    'Choisir un fichier JSON',
    'Choose a JSON file',
    'Elegir un archivo JSON',
  );
  String get chooseCsvFileToImport => _t(
    'Choisir un fichier CSV',
    'Choose a CSV file',
    'Elegir un archivo CSV',
  );
  String get importing => _t('Import…', 'Importing…', 'Importando…');
  String get importInvalidFile => _t(
    'Ce fichier n\'est pas une sauvegarde nibblenibble valide.',
    'This file isn\'t a valid nibblenibble backup.',
    'Este archivo no es una copia de seguridad válida de nibblenibble.',
  );
  String get importConfirmTitle =>
      _t('Confirmer l\'import', 'Confirm import', 'Confirmar importación');
  String importConfirmBody(String babyName, int mealsCount, int notesCount) =>
      _t(
        'Un nouveau profil "$babyName" sera créé avec $mealsCount repas et '
            '$notesCount note(s). Continuer ?',
        'A new "$babyName" profile will be created with $mealsCount meals and '
            '$notesCount note(s). Continue?',
        'Se creará un nuevo perfil "$babyName" con $mealsCount comidas y '
            '$notesCount nota(s). ¿Continuar?',
      );
  String importCsvConfirmBody(
    String babyName,
    int mealsCount,
    int skippedRows,
  ) => _t(
    '$mealsCount repas seront ajoutés à "$babyName".'
        '${skippedRows > 0 ? ' $skippedRows ligne(s) ignorée(s) (aliment non reconnu).' : ''} '
        'Continuer ?',
    '$mealsCount meals will be added to "$babyName".'
        '${skippedRows > 0 ? ' $skippedRows row(s) skipped (unrecognized food).' : ''} '
        'Continue?',
    '$mealsCount comidas se añadirán a "$babyName".'
        '${skippedRows > 0 ? ' $skippedRows fila(s) ignorada(s) (alimento no reconocido).' : ''} '
        '¿Continuar?',
  );
  String get importAction => _t('Importer', 'Import', 'Importar');
  String importSuccess(String babyName) => _t(
    'Import réussi : le profil "$babyName" a été créé.',
    'Import successful: the "$babyName" profile was created.',
    'Importación exitosa: se creó el perfil "$babyName".',
  );
  String importCsvSuccess(String babyName, int count) => _t(
    '$count repas importé(s) dans "$babyName".',
    '$count meal(s) imported into "$babyName".',
    '$count comida(s) importada(s) en "$babyName".',
  );
  String get importFailed => _t(
    'L\'import a échoué. Réessayez.',
    'Import failed. Please try again.',
    'La importación falló. Inténtalo de nuevo.',
  );
  String get pdfJournalTitle => _t(
    'Journal de diversification alimentaire',
    'Food diversification journal',
    'Diario de diversificación alimentaria',
  );
  String pdfGeneratedOn(String date) =>
      _t('Généré le $date', 'Generated on $date', 'Generado el $date');
  String get pdfNoMeals => _t(
    'Aucun repas enregistré pour le moment.',
    'No meals recorded yet.',
    'Aún no hay comidas registradas.',
  );
  String get pdfNotRecorded =>
      _t('Non renseigné', 'Not recorded', 'No registrado');
  String get pdfAge => _t('Âge', 'Age', 'Edad');
  String get pdfDiversificationDuration => _t(
    'Diversification depuis',
    'Diversifying since',
    'Diversificación desde',
  );
  String pdfDiversificationDays(int days) =>
      _t('$days jours', '$days days', '$days días');
  String get pdfSummaryTitle => _t('Résumé', 'Summary', 'Resumen');
  String pdfSummaryMeals(int count) => _t(
    '$count repas enregistrés',
    '$count meals recorded',
    '$count comidas registradas',
  );
  String pdfSummaryFoodsTried(int count) => _t(
    '$count aliments différents essayés',
    '$count different foods tried',
    '$count alimentos diferentes probados',
  );

  // --- Notifications settings ------------------------------------------
  String get mealReminders => _t(
    'Rappels de repas à venir',
    'Upcoming meal reminders',
    'Recordatorios de próximas comidas',
  );
  String get mealRemindersSubtitle => _t(
    'Un rappel 30 minutes avant un repas planifié.',
    'A reminder 30 minutes before a planned meal.',
    'Un recordatorio 30 minutos antes de una comida planificada.',
  );
  String get weeklySummary =>
      _t('Résumé hebdomadaire', 'Weekly summary', 'Resumen semanal');
  String get mealReminderNotifTitle =>
      _t('Repas à venir', 'Upcoming meal', 'Próxima comida');
  String mealReminderNotifBody(String babyName) => _t(
    'Un repas est prévu bientôt pour $babyName.',
    'A meal for $babyName is coming up soon.',
    'Una comida para $babyName está por llegar.',
  );
  String get weeklySummaryNotifTitle =>
      _t('Résumé de la semaine', 'Weekly summary', 'Resumen semanal');
  String get weeklySummaryNotifBody => _t(
    'Le récapitulatif des repas de la semaine est prêt dans Stats.',
    'This week\'s meal summary is ready in Stats.',
    'El resumen de comidas de la semana está listo en Estadísticas.',
  );
  String get weeklySummarySubtitle => _t(
    'Chaque dimanche à 18h, un rappel pour consulter les stats de la '
        'semaine.',
    'Every Sunday at 6pm, a reminder to check the week\'s stats.',
    'Cada domingo a las 18h, un recordatorio para consultar las '
        'estadísticas de la semana.',
  );
  String get enableNotificationsTitle => _t(
    'Activer les notifications ?',
    'Enable notifications?',
    '¿Activar las notificaciones?',
  );
  String get enableNotificationsBody => _t(
    'Recevez un rappel avant chaque repas planifié et un résumé '
        'hebdomadaire de la diversification.',
    'Get a reminder before each planned meal and a weekly diversification '
        'summary.',
    'Recibe un recordatorio antes de cada comida planificada y un resumen '
        'semanal de la diversificación.',
  );
  String get notNow => _t('Plus tard', 'Not now', 'Ahora no');
  String get enable => _t('Activer', 'Enable', 'Activar');

  // --- Language ---------------------------------------------------------
  String get french => _t('Français', 'French', 'Francés');
  String get english => _t('Anglais', 'English', 'Inglés');
  String get spanish => _t('Espagnol', 'Spanish', 'Español');

  // --- Pending invitations card / notes ---------------------------------
  String get pendingInvitation => _t(
    'Invitation en attente',
    'Pending invitation',
    'Invitación pendiente',
  );
  String get familyNote =>
      _t('Note de la famille', 'Family note', 'Nota de la familia');
  String get history => _t('Historique', 'History', 'Historial');
  String get noteHint => _t(
    'Ex. : on essaie les épinards cette semaine…',
    'E.g.: trying spinach this week…',
    'Ej.: esta semana probamos las espinacas…',
  );
  String get noteHistoryTitle =>
      _t('Historique des notes', 'Note history', 'Historial de notas');
  String get noNotesYet => _t(
    'Aucune note pour le moment.',
    'No notes yet.',
    'Aún no hay notas.',
  );
  String get noNoteYetAdmin => _t(
    'Aucune note pour l\'instant — touche le crayon pour en écrire une.',
    'No note yet — tap the pencil to write one.',
    'Aún no hay ninguna nota — toca el lápiz para escribir una.',
  );
  String get noNoteYetReadOnly =>
      _t('Aucune note pour le moment.', 'No note yet.', 'Aún no hay ninguna nota.');
  String loggedBy(String name) =>
      _t('Ajouté par $name', 'Logged by $name', 'Añadido por $name');
  String get deleteNoteTitle => _t(
    'Supprimer cette note ?',
    'Delete this note?',
    '¿Eliminar esta nota?',
  );
  String get deleteNoteMessage => _t(
    'Cette action est définitive.',
    'This is permanent.',
    'Esta acción es definitiva.',
  );
  String get noteDeleted =>
      _t('Note supprimée.', 'Note deleted.', 'Nota eliminada.');
  String get deleteNoteFailed => _t(
    'Impossible de supprimer cette note pour l\'instant.',
    'Unable to delete this note right now.',
    'No se puede eliminar esta nota en este momento.',
  );

  // --- Accessibility (icon-only buttons) ---------------------------------
  String get deleteMealTooltip => _t(
    'Supprimer ce repas',
    'Delete this meal',
    'Eliminar esta comida',
  );
  String get editNoteTooltip =>
      _t('Modifier la note', 'Edit note', 'Editar nota');
  String get clearNoteTooltip =>
      _t('Effacer le texte', 'Clear text', 'Borrar texto');
  String get cancelInvitationTooltip => _t(
    'Annuler l\'invitation',
    'Cancel invitation',
    'Cancelar invitación',
  );
  String get moreOptionsTooltip =>
      _t('Plus d\'options', 'More options', 'Más opciones');

  // --- Enum labels --------------------------------------------------------
  String reactionLabel(String name) => switch (name) {
    'aime' => _t('Aimé', 'Liked', 'Le gustó'),
    'mitige' => _t('Mitigé', 'Mixed', 'Mixta'),
    'pasAime' => _t('Pas aimé', 'Disliked', 'No le gustó'),
    _ => name,
  };

  String foodCategoryLabel(String name) => switch (name) {
    'legumes' => _t('Légumes', 'Vegetables', 'Verduras'),
    'fruits' => _t('Fruits', 'Fruits', 'Frutas'),
    'feculents' => _t('Féculents', 'Starches', 'Féculas'),
    'viandes' => _t('Viandes', 'Meats', 'Carnes'),
    'poissons' => _t('Poissons', 'Fish', 'Pescados'),
    'herbes' => _t('Herbes', 'Herbs', 'Hierbas'),
    'epices' => _t('Épices', 'Spices', 'Especias'),
    'autre' => _t('Autre', 'Other', 'Otro'),
    _ => name,
  };

  String userRoleLabel(String name) => switch (name) {
    'admin' => admin,
    'readOnly' => readOnly,
    _ => name,
  };

  String babyGenderLabel(String name) => switch (name) {
    'fille' => _t('Fille', 'Girl', 'Niña'),
    'garcon' => _t('Garçon', 'Boy', 'Niño'),
    _ => _t('Non précisé', 'Not specified', 'No especificado'),
  };
}
