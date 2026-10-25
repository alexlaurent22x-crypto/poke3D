# Casino Minuit — poke3D

![Aperçu du prototype](docs/preview.png)

[Comparer la première version et la refonte visuelle](docs/VISUAL_REWORK.md)

Premier prototype jouable de Texas Hold’em 3D, hors ligne, pour **Godot 4.6.3 Standard** et **Windows 10 64 bits**. Une table, un joueur et trois adversaires IA. Salle Art déco et mobilier originaux, personnages adultes dérivés de la base humaine **MakeHuman CC0**, préparés dans Blender et livrés en GLB. Aucun téléchargement d’asset n’est nécessaire pour jouer.

## Tester avec un double-clic (Windows 10 64 bits)

1. [Téléchargez le petit ZIP du lanceur Windows](https://github.com/alexlaurent22x-crypto/poke3D/raw/refs/heads/main/Tester_Poker_Windows.zip) et extrayez-le.
2. Double-cliquez sur **Tester_Poker.cmd** dans le dossier extrait. Au premier lancement, il télécharge Godot officiel et cette version du jeu, vérifie les empreintes des archives et prépare les modèles 3D (environ 100 Mo, connexion Internet nécessaire).
3. Le jeu démarre directement. Un raccourci **Casino Minuit** est créé sur votre Bureau pour les prochains essais.

Aucun droit administrateur ni passage par l’éditeur n’est nécessaire. Les téléchargements sont conservés dans `%LOCALAPPDATA%\CasinoMinuit`. Si le lanceur est à côté de `project.godot`, il utilise ce projet local ; sinon, il télécharge la version de la refonte visuelle `8e2a35d` (version figée, pas de mise à jour automatique).

Si Vulkan pose problème, ouvrez un terminal dans le dossier du lanceur et exécutez `Tester_Poker.cmd opengl`. Cela lance le mode compatible et adapte le raccourci du Bureau.

Les téléchargements et leur intégrité sont vérifiables dans le script. La création du raccourci Windows et le démarrage par double-clic restent à essayer sur Windows ; ces opérations ne sont pas exécutables dans le cloud Linux.

## Lancer sous Windows 10

1. Téléchargez **Godot 4.6.3 Standard pour Windows x86_64** depuis [les archives officielles](https://godotengine.org/download/archive/4.6.3-stable/). Pas besoin de la version .NET. Extrayez le ZIP.
2. Récupérez ce dépôt avec `git clone https://github.com/alexlaurent22x-crypto/poke3D.git`, ou **Code → Download ZIP** sur GitHub, puis extrayez-le.
3. Lancez Godot, cliquez **Importer**, choisissez `project.godot` dans `poke3D`, puis **Importer et éditer**.
4. Appuyez sur **F5** : la salle apparaît et la première main est distribuée. Attendez la distribution et le tour des IA, puis jouez avec les boutons en bas.

Autre possibilité, sans ouvrir l’éditeur : glissez le fichier `.exe` de Godot sur `lancer_windows.bat`, ou exécutez :

```powershell
.\lancer_windows.bat "C:\Godot\Godot_v4.6.3-stable_win64.exe"
```

**Godot 6 n’est pas la version utilisée : ce projet est développé et testé avec Godot 4.6.3.**

## Jouer

- Chaque joueur commence avec 1 000 jetons fictifs. Blinds fixes 10 / 20, bouton tournant. Aucun argent réel.
- **V / Voir cartes** : montrer ou cacher vos deux cartes. Elles restent visibles dans l’interface quand vous les regardez.
- **F / Passer** : abandonner la main.
- **C / Suivre** : payer la mise adverse ; devient **Parole** s’il n’y a rien à payer. Un tapis insuffisant suit pour les jetons restants.
- Saisissez un montant, puis **R / Miser ou Relancer**. Le montant est le **total engagé sur le tour**, pas l’ajout. Le minimum légal et le maximum sont imposés. **Tapis** engage tout votre solde quand une relance est autorisée ; sinon, utilisez Suivre pour un tapis à hauteur de la mise.
- **Main suivante** : repartir après le résultat. **Nouvelle partie** : remettre les quatre tapis à 1 000 entre les mains. Si vous êtes éliminé, utilisez Nouvelle partie.
- **Q / E** : tourner la caméra proche de votre avatar ; **molette** : zoom ; **Échap** : quitter.
- **Son** : activer ou couper les sons synthétisés de cartes / jetons. **Rendu** : élevé ou fluide.

Les IA attendent environ une seconde par action. L’historique à droite est défilable. Les cartes des adversaires sont cachées jusqu’à l’abattage ; les cartes passées ne sont pas révélées. L’IA utilise uniquement ses propres cartes et le tableau, jamais vos cartes cachées.

## Présent dans cette version

- Une salle Art déco : arche, boiseries veinées, marbre, tapis à motifs, bar éclairé, banquette et lustre ; table en acajou avec rail en cuir cousu, feutre imprimé et porte-gobelets.
- Avatar joueur assis, trois adversaires adultes hommes et femmes et croupière : véritables maillages humains avec doigts, visages, vêtements, cheveux et accessoires. Animations squelettiques de repos et de distribution, cartes glissant sur la table.
- Hold’em No Limit : préflop, flop, turn, river, cartes brûlées, blinds, tours de parole, mises, relances minimales, tapis, règles de réouverture, pots secondaires, partage des égalités et jetons indivisibles attribués à gauche du bouton.
- Évaluation de la meilleure combinaison de cinq cartes parmi sept, de la carte haute à la quinte flush, y compris la quinte A-2-3-4-5.
- Interface française allégée, jeu de 52 cartes à figures et dos illustrés, jetons bicolores, résultat et historique. Illustrations vectorielles originales, avec rangs et symboles convertis en tracés pour rester lisibles dans Godot.

## Graphismes et configuration conseillée

Le rendu **Forward+ (Vulkan)** utilise des ombres dynamiques, une exposition ACES, de l’occlusion ambiante, un léger bloom et un MSAA 2×. La scène compacte, les matériaux procéduraux, les textures vectorielles et les deux spots à ombres limitent le coût. Le jeu est plafonné à 60 images/s. Le mode **fluide** désactive ombres, occlusion ambiante, bloom et MSAA.

Pour votre i7-8700 / RTX 2070 / 16 Go : commencez en mode élevé, fenêtre 1280 × 800 ou plein écran via l’agrandissement de la fenêtre, puis essayez 1920 × 1080. Les performances sur cette configuration restent à mesurer : aucune promesse de fréquence d’images sans essai sur votre PC. Mettez à jour le pilote NVIDIA si Vulkan ne démarre pas.

Solution de repli OpenGL si nécessaire :

```powershell
& "C:\Godot\Godot_v4.6.3-stable_win64.exe" --path . --rendering-method gl_compatibility
```

Le mode de repli ne propose pas tous les effets de Forward+. Dans le cloud Linux avec Vulkan logiciel, l’affichage a été capturé mais la fermeture automatique reste bloquée ; le mode OpenGL et les tests headless se ferment normalement. Ce comportement n’a pas été testé sur votre GPU Windows. Voir le [rapport de validation](docs/VALIDATION.md).

## Produire un exécutable Windows

1. Dans Godot 4.6.3 : **Éditeur → Gérer les modèles d’exportation**, installez les modèles **4.6.3**.
2. **Projet → Exporter** : le préréglage **Windows Desktop** est déjà configuré en x86_64, avec ressources embarquées.
3. Créez le dossier `build/windows`, cliquez **Exporter le projet**, puis choisissez `build/windows/CasinoMinuit.exe`. Désactivez **Exporter avec débogage** pour une version finale.
4. Copiez l’exécutable sur votre PC et lancez-le. Si l’export produit des fichiers d’accompagnement, distribuez tout le dossier.

En ligne de commande, après installation des modèles :

```powershell
New-Item -ItemType Directory -Force build/windows
& "C:\Godot\Godot_v4.6.3-stable_win64.exe" --headless --path . --export-release "Windows Desktop" build/windows/CasinoMinuit.exe
```

L’exécutable n’est pas signé. Ce dépôt fournit le projet source ; consultez [la validation](docs/VALIDATION.md) pour les exports effectivement testés.

## Développement et tests

Le projet ne requiert ni serveur, ni clé API, ni gestionnaire de paquets. Depuis la racine, avec `godot` dans le PATH :

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_poker.gd
godot --headless --path . --script res://tests/test_visual_assets.gd
godot --headless --path . --script res://tests/test_scene.gd
```

Sur une machine cloud où le dossier utilisateur est en lecture seule, utilisez `./tests/run.sh`. Sous Windows, remplacez `godot` par le chemin du programme Godot (de préférence la variante `_console.exe` pour lire les résultats).

- `scripts/poker.gd` : règles et IA indépendantes du rendu.
- `scripts/main.gd` : intégration de la scène, avatars, interface, animations, audio.
- `scripts/casino_room.gd` : architecture, matériaux et lumières de la salle.
- `scripts/table_visuals.gd` : table détaillée, cartes et jetons.
- `assets/characters/` : quatre modèles adultes GLB, animations comprises.
- `tools/build_characters.py` : génération des personnages dans Blender 4.3.2.
- `assets/source/makehuman/ATTRIBUTION.md` : provenance, révision et licence CC0 des données humaines.
- `scenes/main.tscn` : scène d’entrée.
- `tests/` : règles, simulations et essai de l’interface.

## Limites et remplacement des assets

Les personnages ont maintenant des proportions et une topologie humaines, des yeux séparés, des cheveux, des vêtements de soirée et un squelette animé. Ils restent des **modèles de développement**, avec matériaux simples : pas encore de textures de peau photographiques, de vêtements haute couture, de doublage ou de capture de mouvement. Cette refonte ne prétend pas atteindre la qualité visuelle d’un jeu commercial fini.

Les fichiers GLB sont livrés et prêts à importer. Blender n’est nécessaire que pour régénérer ou retoucher ces modèles. `tools/build_characters.py` reconstruit les quatre personnages à partir des sources CC0 incluses. Pour utiliser d’autres modèles, conservez les clips `idle` et `deal`, puis adaptez les chemins `CHARACTER_PATHS` et celui de la croupière dans `scripts/main.gd`.

Le mobilier, les shaders de la salle et les illustrations du jeu de cartes sont originaux. Les données anatomiques sont issues de MakeHuman sous CC0 ; la police utilisée pour les tracés vectoriels est DejaVu, licence incluse sous `assets/table/licenses/`. Aucun asset de Prominence Poker n’est utilisé.

L’IA est heuristique et ne constitue pas un adversaire expert. Pas encore de multijoueur, sauvegarde de partie, éditeur d’avatar, progression ou accessibilité complète. La partie en cours reste en mémoire uniquement.
