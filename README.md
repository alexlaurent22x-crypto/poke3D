# Casino Minuit — poke3D

![Aperçu du prototype](docs/preview.png)

Premier prototype jouable de Texas Hold’em 3D, hors ligne, pour **Godot 4.6.3 Standard** et **Windows 10 64 bits**. Une table, un joueur et trois adversaires IA. Décor et personnages adultes originaux générés dans le moteur, sans téléchargement d’assets ni dépendance externe.

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

- Une salle de casino 3D : table ovale en feutre texturé, bordure dorée, fauteuils, bar, panneaux décoratifs et luminaires.
- Avatar joueur assis, trois adversaires adultes hommes et femmes en tenues de soirée, croupière adulte provisoire avec geste de distribution et cartes qui glissent sur la table.
- Hold’em No Limit : préflop, flop, turn, river, cartes brûlées, blinds, tours de parole, mises, relances minimales, tapis, règles de réouverture, pots secondaires, partage des égalités et jetons indivisibles attribués à gauche du bouton.
- Évaluation de la meilleure combinaison de cinq cartes parmi sept, de la carte haute à la quinte flush, y compris la quinte A-2-3-4-5.
- Interface française, piles de jetons représentant les mises, cartes animées, sons synthétisés, résultat et historique.

## Graphismes et configuration conseillée

Le rendu **Forward+ (Vulkan)** utilise des ombres dynamiques, une exposition ACES, de l’occlusion ambiante, un léger bloom et un MSAA 2×. La scène compacte, les textures procédurales de 256 pixels et les deux sources à ombres limitent le coût. Le jeu est plafonné à 60 images/s. Le mode **fluide** désactive ombres, occlusion ambiante, bloom et MSAA.

Pour votre i7-8700 / RTX 2070 / 16 Go : commencez en mode élevé, fenêtre 1280 × 800 ou plein écran via l’agrandissement de la fenêtre, puis essayez 1920 × 1080. Les performances sur cette configuration restent à mesurer : aucune promesse de fréquence d’images sans essai sur votre PC. Mettez à jour le pilote NVIDIA si Vulkan ne démarre pas.

Solution de repli OpenGL si nécessaire :

```powershell
& "C:\Godot\Godot_v4.6.3-stable_win64.exe" --path . --rendering-method gl_compatibility
```

Le mode de repli ne propose pas tous les effets de Forward+.

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
godot --headless --path . --script res://tests/test_scene.gd
```

Sur une machine cloud où le dossier utilisateur est en lecture seule, utilisez `./tests/run.sh`. Sous Windows, remplacez `godot` par le chemin du programme Godot (de préférence la variante `_console.exe` pour lire les résultats).

- `scripts/poker.gd` : règles et IA indépendantes du rendu.
- `scripts/main.gd` : salle, avatars, interface, animations, audio.
- `scenes/main.tscn` : scène d’entrée.
- `tests/` : règles, simulations et essai de l’interface.

## Limites et remplacement des assets

Il s’agit d’un **prototype avec personnages stylisés et géométriques**, pas d’un rendu photoréaliste ni de personnages finis. Les silhouettes féminines ont des robes de soirée simples ; il n’y a pas encore de vêtements détaillés, de squelettes animés, de doublage ou de capture de mouvement. La croupière effectue un geste de bras et les cartes se déplacent par interpolation ; aucune simulation physique de lancer n’est utilisée.

Pour remplacer les personnages, importez des modèles adultes originaux ou correctement licenciés au format GLB et remplacez la géométrie dans `character()`. Conservez les racines de personnage et le pivot `ArmPivot`, ou adaptez la distribution à un `AnimationPlayer`. Le jeu n’utilise aucun asset, logo, son ou modèle de Prominence Poker.

L’IA est heuristique et ne constitue pas un adversaire expert. Pas encore de multijoueur, sauvegarde de partie, éditeur d’avatar, progression ou accessibilité complète. La partie en cours reste en mémoire uniquement.
