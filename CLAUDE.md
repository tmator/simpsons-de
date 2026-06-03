# Instructions projet

Ce projet est un flipper Simpsons Data East sous MPF 0.80 avec GMC/Godot.

- Ne pas mettre de section `keyboard:` dans les fichiers YAML MPF.
- Les touches clavier doivent être ajoutées dans `gmc.cfg`, section `[keyboard]`.
- Ne pas créer de section `images:` MPF si elle n’existe pas déjà dans la config.
- Ne pas casser le mode `base`.
- Les vidéo modes doivent avoir une priorité supérieure à `base`, par exemple 500.
- Toujours inspecter `config.yaml`, `gmc.cfg` et `modes/` avant modification.

