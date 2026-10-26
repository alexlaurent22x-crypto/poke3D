# Sources et licences — POKS Unity HDRP

Ressources recherchées et notices consultées sur Internet pendant cette création. Les fichiers réellement téléchargés, leurs URL et SHA-256 figurent dans `downloads.json`. Aucun asset de Prominence Poker n'a été copié.

## Ressources externes incluses

| Ressource | Auteur / titulaires et licence | Source exacte | Intégration |
| --- | --- | --- | --- |
| Sheen Chair | © 2020 Wayfair, LLC ; Eric Chadwick. CC0 1.0 | https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SheenChair | GLB téléchargé, converti en FBX ; version supplémentaire de fauteuil fournie dans Resources. |
| Chair Damask Purplegold | © 2021 Wayfair ; Eric Chadwick, modèles et textures. **CC BY 4.0** | https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/ChairDamaskPurplegold | Fauteuils du salon ; FBX et textures PBR extraites. |
| Sheen Wood Leather Sofa | © 2024 Darmstadt Graphics Group GmbH ; Eric Chadwick, améliorations, **CC BY 4.0**. Original © 2021 domaine public ; Fran Calvente, **CC0 1.0** | https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SheenWoodLeatherSofa | Canapé du salon. WEBP convertis en PNG, modèle converti en FBX. |
| Lights Punctual Lamp | © 2021 DGG, **CC BY 4.0** ; notice mentionnant Teresa González Viegas pour la création | https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/LightsPunctualLamp | Lampe de salon ; FBX et textures extraites. Les lumières HDRP sont configurées séparément. |
| Base humaine adulte MakeHuman | Titulaires des données : notamment Data Collection AB, Joel Palmius, Jonas Hauquier et Manuel Bastioni, selon les en-têtes sources. **CC0 1.0** | https://github.com/makehumancommunity/makehuman/tree/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data | Les quatre dérivés GLB fournis par le dépôt existant sont copiés sous `Tools/SourceAssets/Humans`, puis convertis en FBX pour ce nouveau projet. Le moteur Godot et les scripts GDScript ne sont pas inclus dans Unity. |
| Licence des données MakeHuman vérifiée | CC0 1.0 — distincte du code applicatif AGPL | https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md | Notice complète conservée. Aucun code de l'application MakeHuman n'est embarqué. |
| Police DejaVu Sans | Licence libre DejaVu / Bitstream Vera, notice incluse | https://dejavu-fonts.github.io/ | Utilisée pour rasteriser les cartes originales. Unity utilise sa police d'interface embarquée. |

Les licences **CC0** et **CC BY 4.0** autorisent l'usage commercial. **CC BY 4.0 impose l'attribution et l'indication des modifications** : les notices sont fournies dans `Assets/POKS/Licenses`, dans cet inventaire et dans l'écran Crédits ; le build Windows copie les notices à côté de l'exécutable. À conserver lors de la distribution.

Modifications : conversion glTF/GLB vers FBX, extraction PNG, conversion des canaux metallic/roughness vers le mask HDRP (R métallique, G occlusion neutre, B détail neutre, A lissage), apparences recolorées, variantes de cheveux/barbes et morphs, poses debout ajoutées, réassemblage et nouvelles lumières. Les extensions sheen/transmission/variants du glTF ne sont pas intégralement reproduites par le convertisseur ; **le résultat HDRP n'est pas certifié identique aux captures des auteurs**.

Les modèles anatomiques existants ont déjà une licence CC0 documentée ; ils sont provisoires. La création d'un nouveau moteur Unity ne rend pas ces humains photoréalistes. Leurs textures de peau, leurs coupes de vêtements et les accessoires demandent encore une finition artistique.

## Liens directs des fichiers téléchargés

- https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenChair/glTF-Binary/SheenChair.glb
- https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb
- https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/SheenWoodLeatherSofa/glTF-Binary/SheenWoodLeatherSofa.glb
- https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/LightsPunctualLamp/glTF-Binary/LightsPunctualLamp.glb

Ces ressources sont **déjà intégrées** : il n'est pas nécessaire de les télécharger manuellement pour essayer la version fournie.

## Ressources supplémentaires non téléchargées

L'API `https://api.polyhaven.com/assets?t=textures` n'était pas accessible depuis ce cloud : refus du proxy HTTP 403. Aucun téléchargement Poly Haven et aucune intégration d'un pack de textures Poly Haven ne sont revendiqués. Les textures PBR fournies proviennent des meubles listés ci-dessus ; la table et les boiseries réemploient une texture de bois du fauteuil, avec son attribution.

Recherche de modèles de table/casino dans le catalogue accessible : aucun modèle de table de poker répondant au besoin et avec une licence vérifiée n'a été retenu. La table du projet est donc **une création maillée originale**, et non une table photoréaliste téléchargée. Aucun chat réaliste, pack de personnel de casino ou animation de service/écriture sous licence vérifiée n'a été téléchargé. Les éléments correspondants restent des créations ou gestes provisoires.

Pour la suite, Mixamo permet de chercher des mouvements assis : https://www.mixamo.com/#/?page=1&query=sitting&type=Motion%2CMotionPack . Connexion Adobe et téléchargement manuel possibles ; **aucune animation Mixamo n'est incluse et ses conditions n'ont pas été vérifiées dans cette session**. Un remplacement requiert du retargeting, pas simplement le dépôt d'un FBX dans un dossier. Il ne fait pas partie des prérequis pour ouvrir cette version.

## Créations originales et audio provisoire

`Tools/build_unity_art.py` génère la salle, la table et le chat. `Tools/generate_original_media.py` produit les 53 images de cartes et les quatre sons WAV de remplacement. Aucun de ces sons n'est un enregistrement de cartes, de foule, de bar ou de musique commerciale. Le script de voix Windows utilise une voix française locale ; aucun enregistrement parlé n'est distribué dans cette version.
