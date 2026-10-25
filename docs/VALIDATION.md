# Validation du prototype

Moteur : **Godot 4.6.3 stable officiel**. Tests exécutés dans le cloud Linux le 25 octobre 2026. Aucun test exécuté sur Windows ni sur la RTX 2070 de l’utilisateur.

| Vérification | Résultat |
| --- | --- |
| Import du projet dans l’éditeur en mode headless | Réussi, sans erreur de script |
| `tests/test_poker.gd` | **10 211 vérifications, 571 mains, 0 échec** |
| `tests/test_scene.gd` headless | Réussi : distribution, quatre avatars, révélation des cartes, main complète via interface + IA, résultat, main suivante, relance, passage, son et qualité |
| Scène et main complète avec rendu OpenGL Compatibility | Réussi sous Xvfb, Mesa llvmpipe logiciel |
| Scène et main complète avec rendu Vulkan Forward+ | Réussi sous Xvfb, Mesa lavapipe logiciel |
| Capture graphique du mode Forward+ | Inspectée ; voir l’aperçu ci-dessous |
| Synthèse audio | Génération et commandes vérifiées ; écoute humaine non effectuée, sortie audio fictive dans les tests graphiques |
| Exécutable Windows | Non produit : modèles d’export Windows non installés dans cette instance. Préréglage et procédure fournis dans README.md |
| Performances i7-8700 / RTX 2070 | Non mesurées ; le rendu logiciel cloud ne permet pas de les prédire |

Les tests des règles couvrent les neuf catégories de mains, kickers, roue, meilleure main parmi sept, égalités, blinds et option de la grosse blind, heads-up, mises invalides, tapis partiels, réouverture après relance complète ou cumul de petites relances, mise d’ouverture inférieure à une blind, pots secondaires, exclusion des joueurs couchés, jeton indivisible et conservation des 4 000 jetons sur des simulations déterministes.

Le test de scène instancie la vraie scène et active les signaux des boutons. Ce n’est pas un robot de clics physiques : le placement, la lisibilité et le rendu ont été vérifiés sur une capture, pas par un parcours complet à la souris sous Windows.

Les vérifications de règles sont déterministes. Le nombre d’actions du test de scène varie avec les décisions IA ; les échecs provoquent un code de sortie non nul. Pour reproduire les tests headless : `./tests/run.sh`.

Les outils graphiques temporaires de validation (Xvfb et pilote Mesa) ont été téléchargés depuis le dépôt Debian avec métadonnées signées et vérification des paquets, puis extraits sous `/tmp`. Ils ne sont pas requis sur Windows et ne sont pas des dépendances du projet.

![Prototype Casino Minuit, rendu Forward+](preview.png)
