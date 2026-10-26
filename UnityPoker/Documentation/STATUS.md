# État vérifiable de la première version

Cette livraison est un **projet source Unity 6 HDRP préparé**, pas un exécutable Windows testé. Le moteur, les écrans et l'assemblage du salon sont écrits en C#. Le projet ne charge aucun moteur Godot et n'exécute aucun GDScript.

| Partie | Réalisé | Vérifié ici | Limite restante |
| --- | --- | --- | --- |
| Projet Unity | Manifest Unity 6 / HDRP 17.0.4, scène d'amorce, assemblages, importeurs, préparation et menu de build | JSON, références de ressources, GUID de la scène et syntaxe C# 9 | L'import et la compilation Unity restent à exécuter sous Unity |
| Avatar | Sélections, sauvegarde, six morphs exportés, variantes coiffure/barbe | Présence des six morphs et vrais squelettes vérifiée dans les FBX réimportés ; déplacements morphologiques examinés | Coiffures et barbes simples ; apparences de tenue recolorées ; visage/peau non photoréalistes |
| Salle | Nouvelle géométrie, table, bar, mobilier détaillé téléchargé, personnel, télévision textuelle, chat animé | Maillages réimportés dans Blender ; cartes et textures lisibles | L'éclairage/rendu HDRP et les accessoires sur les os restent à contrôler dans Unity |
| Poker | Tournoi No Limit à trois joueurs, élimination/heads-up, relances, tapis, pots secondaires, IA | Cœur C# réellement compilé et exécuté sous .NET 8 ; 100 tournois et tests ciblés, succès | Interaction des coroutines/UI/animations non exécutée dans Unity |
| Évaluateur | Meilleure main de cinq à sept cartes | Les 2 598 960 mains de cinq cartes classées selon les fréquences connues ; succès | Tests d'intégration Unity non exécutés |
| Caméra | Orbite assise 360°, capture/relâchement, retour Échap, zoom | Code présent, paramètres et géométrie revus | Souris et capture du curseur à tester dans Unity/Windows |
| Animations | Repos/distribution squelettiques, poses debout, cartes/jetons interpolés, respiration du chat | Animations relues dans les FBX ; les options d'export erronées ont été corrigées avant livraison | Gestes génériques ; pas de service, conversation ni écriture finalisés |
| Audio | Boucle lounge originale et bruitages de remplacement ; générateur de voix Windows | WAV synthétiques non vides et lisibles | Ni enregistrements réalistes, ni bavardages, ni voix française pré-générée ; écoute Unity non testée |
| Qualification | Certificat local, identité/numéro, capture de portrait et export JSON/PNG après victoire | Code et chemins relus | Capture/export non exécutés dans Unity ; aucune qualification sur un service en ligne |
| Windows | Lanceur Windows avec détection Unity, raccourci Bureau et demande de Play automatique, menu d'export x64 | Scripts fournis et relus | Aucun double-clic Windows, raccourci COM ou build EXE testé |
| Performance | 1280×800, sans ray tracing, deux lumières avec ombres, mode fluide | Choix présents dans le code | Aucun FPS, budget mémoire ou essai sur RTX 2070/i7-8700 mesuré |

`Blender-layout-review.png`, s'il est présent, est **une revue de géométrie rendue dans Blender/Cycles, pas une capture Unity ni une preuve du rendu HDRP**. Elle ne contient pas l'interface C#, les cartes et les actions de la partie, construites à l'exécution dans Unity.

## Première vérification dans Unity

1. Ouvrir le dossier avec Unity 6000.0.62f1 et laisser terminer packages/import/shaders.
2. Vérifier Console, exécuter **POKS → Préparer le projet**, puis **POKS → Ouvrir le Salon**.
3. Play : titre → création ; changer sexe/cheveux/visage et renseigner l'identité ; démarrer.
4. Vérifier les positions assises, la caméra (souris/relâchement/Échap), le rendu des textures et la lisibilité de l'interface.
5. Essayer suivre, passer, miser, relancer et tapis ; contrôler les animations et le son.
6. Exécuter EditMode tests via Test Runner ; les tests d'évaluateur exhaustifs peuvent prendre quelques secondes.
7. Vérifier la sauvegarde de l'avatar après fermeture/réouverture et l'export du certificat après une victoire.
8. Installer Windows Build Support si nécessaire ; construire via le menu POKS ; tester le dossier exporté complet sous Windows 10 x64.

Ces opérations ne sont pas marquées réussies : elles nécessitent l'éditeur/licence Unity et Windows, absents de ce cloud. Aucune modification du code n'est demandée à l'utilisateur pour démarrer cette vérification.
