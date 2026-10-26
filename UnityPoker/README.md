# POKS CASINO 3D — LE TOURNOI

**Nouveau projet Unity 6 HDRP / C#, indépendant du jeu Godot du dossier parent.** Première version de développement pour Windows 10 x64. Le projet et les ressources sont préparés ; **Unity n'est pas installé dans la machine de création et l'ouverture, la compilation Unity, le rendu HDRP et l'exécutable Windows n'ont pas été testés**. La qualité visuelle n'est pas encore celle de Prominence Poker.

## Essayer sans écrire de code

1. Installer [Unity Hub](https://unity.com/download), puis **Unity 6 — 6000.0.62f1** avec le module **Windows Build Support**. Une licence Unity adaptée à votre situation est nécessaire. [Page exacte de cette version](https://unity.com/releases/editor/whats-new/6000.0.62f1).
2. Extraire tout le projet dans un dossier local. Double-cliquer **LANCER-POKS.cmd** (raccourci Bureau créé automatiquement), ou choisir **Add project from disk** dans Unity Hub et sélectionner le dossier contenant `Assets`, `Packages` et `ProjectSettings`.
3. Laisser Unity télécharger **HDRP 17.0.4** et importer les FBX/textures. La première compilation des shaders peut prendre plusieurs minutes. Internet est nécessaire pour les packages Unity ; aucun achat d'asset n'est requis.
4. La préparation HDRP s'effectue au premier import. Si nécessaire : menu **POKS → Préparer le projet**. Le menu crée l'asset HDRP, les matériaux persistants et les paramètres Windows.
5. Le lanceur demande le passage automatique en **Play** après les imports. En ouverture manuelle : **POKS → Ouvrir le Salon**, puis **Play**. Le titre et la création du personnage se construisent au lancement. La scène sur disque contient l'amorce du jeu ; son décor est assemblé à l'exécution depuis les FBX fournis.

`Creer-Raccourci-Bureau.ps1` crée un raccourci vers **LANCER-POKS.cmd**, qui cherche un build Windows puis Unity 6. Aucun exécutable Windows n’est fourni. Le script n'a pas été exécuté sous Windows ici. Ne pas désactiver la politique de sécurité Windows pour le lancer ; l'ouverture par Unity Hub reste disponible.

Pour produire le jeu indépendant de l'éditeur : menu **POKS → Construire Windows x64**. Distribuer ensuite **tout** `Build/Windows`, et pas seulement l'EXE. Cette construction n'a pas été exécutée dans le cloud.

## Cette première version contient

- Écran de titre français, mention 18+, création et sauvegarde locale d'un avatar adulte.
- Sélection homme/femme, deux apparences de tenue, cinq coiffures incluant rasé, sans barbe ou deux barbes pour l'homme, morphologie et cinq réglages du visage. **Les coiffures, barbes et modifications morphologiques restent des approximations de prototype ; les deux tenues utilisent la même base vestimentaire avec des teintes différentes.**
- Salle noire, bordeaux et or : table ovale maillée avec socle, rail, liserés, porte-gobelets ; boiseries, colonnes, grande porte dorée, bar, bouteilles, lustre, meubles, télévision textuelle animable et chat endormi modélisé avec respiration. Mobilier externe détaillé et textures PBR fournies.
- Trois joueurs à table et un croupier visible ; deux gardes, barmaid, spectateurs et surveillante. Les humains sont de vrais maillages anatomiques articulés, issus de dérivés MakeHuman CC0 du précédent prototype, convertis pour Unity. Aucun script ou moteur Godot n'est utilisé par le nouveau jeu. **Ce ne sont pas de nouveaux humains photogrammétriques ; leurs matériaux de peau et vêtements demandent encore un travail artistique.**
- Caméra assise : maintenir le clic gauche hors interface pour capturer le curseur et tourner à 360°, relâcher pour conserver l'angle, molette pour la distance, Échap pour revenir derrière l'avatar. Le personnage ne marche pas.
- Tournoi C# hors ligne : Texas Hold'em No Limit, trois tapis de 1 000 jetons, blindes 10/20 doublées toutes les huit mains, élimination, heads-up, dernier joueur gagnant, IA fondée sur les cartes connues uniquement.
- Mises, relances minimales, tapis courts, réouverture, pots secondaires, égalités, jetons indivisibles, cartes brûlées et évaluation de la meilleure main sur sept. Le montant de relance est le **total engagé sur le tour**, pas un supplément.
- Cartes illustrées originales et déplacement animé, jetons, historique français et commandes de partie. `V` montre/cache les cartes.
- Carte de membre noire et dorée après la victoire du joueur : portrait capturé du rendu, identité, pays, numéro unique et qualification, sauvegarde JSON/PNG. **Il s'agit d'une qualification locale enregistrée par cette version : aucun futur jeu ou service en ligne n'existe pour la valider à distance.**

## État réel de l'audio et des animations

Les clips de squelette de repos/distribution sont inclus ; les gestes restent génériques et la synchronisation des doigts, des cartes et des jetons doit être revue dans Unity. Les gardes/barmaid disposent d'une pose debout distincte. Les conversations, le service au bar et l'écriture de la surveillante utilisent pour l'instant des gestes génériques, pas des animations métier finalisées. La télévision affiche du texte ; aucun film n'est fourni. Le chat est un maillage original simple, pas un modèle réaliste téléchargé.

Les sons cartes/jetons/bar et la boucle musicale sont **des compositions et bruitages synthétisés de remplacement**. Aucun enregistrement réaliste de foule ni bavardage français n'est inclus.

Une voix française peut être générée sur Windows avec `Tools/Generate-FrenchVoice.ps1` si une voix française **System.Speech** compatible est installée. Le script échoue explicitement si elle manque. Aucun WAV parlé n'a été généré ni testé ici. Pour des prises enregistrées, placer `welcome.wav`, `deal.wav`, `flop.wav`, `turn.wav`, `river.wav`, `showdown.wav`, `victory.wav` dans `Assets/POKS/Resources/Audio/Voice/` ; le code les charge automatiquement. Ne pas ajouter un enregistrement sans droits commerciaux.

## Sauvegardes

L'avatar est enregistré dans `Application.persistentDataPath/avatar.json`. Sous Windows, Unity utilise généralement `%USERPROFILE%\AppData\LocalLow\POKS\POKS CASINO 3D — LE TOURNOI\`. La carte et son identité sont dans le sous-dossier `Membership`. Le chemin exact de l'export est affiché dans la console Unity / le journal du joueur. Les mains en cours ne sont pas sauvegardées ; revenir au menu termine la tentative en cours.

## Vérifications effectuées ici

- Moteur C# compilé et exécuté sous .NET 8 : **4 248 contrôles**, 100 tournois complets, cas de heads-up/tapis court/pots secondaires et essai IA ; succès.
- Vérification exhaustive des **2 598 960 mains de cinq cartes** contre la distribution combinatoire connue ; succès.
- Analyse syntaxique C# 9 des scripts : succès. **Ceci ne remplace pas la compilation avec les assemblies Unity.**
- FBX réimportés et inspectés dans Blender ; rapport complet des 13 fichiers dans `Documentation/art-validation.json`, lié aux fichiers par SHA-256. Il distingue maillages, squelettes, morphs et animations.
- Les tests NUnit fournis se lancent dans **Window → General → Test Runner → EditMode**. Ils **n'ont pas été exécutés dans Unity** ici.

Pas de mesure sur RTX 2070 / i7-8700 / 16 Go. Le profil vise 1280×800, 60 FPS plafonnés, sans ray tracing, avec deux lumières à ombres et un mode fluide ; ce sont des choix de départ, pas une garantie de performances. Tester ensuite en 1920×1080 dans un build Windows et ajuster selon le Profiler.

## Architecture

`Assets/POKS/Scripts/Core` : règles C# sans dépendance Unity. `Runtime` : interface, profils, scène, caméra, présentation, audio, orchestration. `Editor` : importeurs et préparation/build Windows. `Resources` : FBX, textures, cartes et sons fournis. `Tests/Editor` : tests NUnit. `Tools` : outils facultatifs de production, pas nécessaires pour jouer ni ouvrir les assets déjà générés.

Sources, liens exacts, licences et crédits : [Documentation/ASSETS.md](Documentation/ASSETS.md). État détaillé : [Documentation/STATUS.md](Documentation/STATUS.md). Aucune ressource commerciale de Prominence Poker n'est utilisée.
