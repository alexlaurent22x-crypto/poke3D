# Validation de la refonte visuelle

Moteur : **Godot 4.6.3 stable officiel**. Vérifications du 25 octobre 2026 dans le cloud Linux. Aucun test matériel sous Windows ni sur la RTX 2070 de l’utilisateur.

| Vérification | Résultat |
| --- | --- |
| Génération des quatre GLB dans Blender 4.3.2 | Réussie, fichiers et outils inclus |
| Import de tous les assets dans Godot headless | Réussi, sans erreur de script |
| `tests/test_poker.gd` | **10 211 vérifications, 571 mains, 0 échec** |
| `tests/test_visual_assets.gd` | **3 472 vérifications, 52 faces distinctes, 3 312 triangles vérifiés, 0 échec** |
| `tests/test_scene.gd` headless | Réussi : personnages avec squelettes, clips idle/deal, distribution, révélation, main complète avec IA, résultat, main suivante, relance, passage, son, qualité et extinction des deux spots à ombres |
| Même scénario avec rendu OpenGL | Réussi : 14 actions et commandes supplémentaires, 0 échec, processus terminé avec code 0 |
| Démarrage et fermeture du jeu avec OpenGL | Réussis, code 0 avec `--quit-after 5` |
| Captures Forward+ Vulkan | Réussies et inspectées : `preview.png` et `detail.png` montrent le jeu livré |
| Fermeture automatique avec Vulkan logiciel | Bloquée dans cette instance après les captures / les premières images ; processus arrêtés manuellement. L’affichage fonctionne, mais cette fermeture n’est pas validée |
| Audio | Génération et commandes vérifiées ; aucune écoute humaine, pilote audio fictif dans les essais graphiques |
| Exécutable Windows | Non produit ; modèles d’export Windows non installés. Préréglage et procédure fournis dans README.md |
| Performances i7-8700 / RTX 2070 | Non mesurées ; le rendu logiciel cloud ne permet pas de les prédire |

Le rendu graphique utilise Xvfb et Mesa logiciel (llvmpipe / lavapipe). Une attente de fermeture a été observée avec Vulkan, y compris lors d’un démarrage du jeu avec `--quit-after 5`. Le mode de rendu de threads `safe` et la désactivation de V-Sync ont aussi été essayés. Le même arrêt fonctionne avec OpenGL ; les tests headless se terminent normalement. La cause précise de l’attente Vulkan n’est pas établie, et aucun résultat sur un vrai GPU Windows n’est extrapolé. La commande OpenGL de repli est documentée dans le README.

Les règles sont testées sur les neuf catégories de mains, kickers, roue, meilleure main parmi sept, égalités, blinds et option de la grosse blind, heads-up, mises invalides, tapis partiels, réouverture des relances, pots secondaires, joueurs couchés, jeton indivisible et conservation des 4 000 jetons.

Le test de scène active les signaux des vrais boutons. Il ne remplace pas un parcours physique souris/clavier sous Windows. Les captures servent à vérifier le placement et le rendu. La synthèse sonore ne remplace pas une écoute humaine.

Pour reproduire les contrôles sans écran : `./tests/run.sh`. Le scénario de scène varie avec les décisions IA ; les échecs provoquent un code de sortie non nul.

La comparaison avant/après et les limites artistiques sont décrites dans [VISUAL_REWORK.md](VISUAL_REWORK.md). Les outils graphiques temporaires ont été extraits sous `/tmp` depuis des paquets Debian vérifiés ; ils ne sont pas nécessaires sur Windows. Tous les modèles et toutes les textures de jeu sont livrés dans le dépôt.

![Refonte Casino Minuit — capture réelle Forward+](preview.png)

## Lanceur Windows a double-clic

`Tester_Poker_Windows.zip` contient le fichier hybride CMD / PowerShell `Tester_Poker.cmd` et les instructions courtes. Les archives Godot et jeu ont été téléchargées par la fonction réelle du lanceur et vérifiées : SHA-512 officiel Godot 4.6.3 Windows et SHA-256 de l’archive du jeu figée à `8e2a35d`. Les chemins internes de ces deux ZIP et le contenu du ZIP du lanceur ont été contrôlés. Le script a été analysé avec PowerShell 7.5.4 sous Linux et relu pour sa compatibilité PowerShell 5.1.

Le double-clic Windows, l’import par le moteur Windows, la création du raccourci COM et le démarrage de la fenêtre Windows n’ont pas été exécutés dans ce cloud Linux. Aucun droit administrateur ni désactivation de vérification TLS ou d’empreinte n’est demandé par le lanceur.
