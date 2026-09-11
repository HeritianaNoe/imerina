# Fanatsarana UI - Quiz Imerina

## Izay natao

1. **Orientation** : Novaina ho **portrait** amin'ny mobile (Android/iOS) – mety kokoa amin'ny telefaonina.
2. **Fond image** : Nampiana background image amin'ny Home, Quiz ary Result.
3. **Layout mobile** : Responsive (mifanaraka amin'ny haben'ny efijery), font size mivadika, spacing tsara, shadow, sns.
4. **Choices** : Grid mivadika 1 na 2 columns arakaraka ny sakany (mety amin'ny portrait).

## Ahoana ny fampidirana ny sary (Fond image)

1. Mamorona dossier : `assets/images/`
2. Apetraho ao ny sary anao (ohatra sary Merina / Rova / tantara) miaraka amin'ny anarana :
   ```
   assets/images/bg_merina.jpg
   ```
3. Ampidiro ao amin'ny `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/bg_merina.jpg
    # ... ny assets hafa efa misy (json, sounds, ...)
```

4. `flutter pub get` dia `flutter run`

Raha tsy misy sary dia mampiasa gradient mena maizina (fallback) ka tsy misy crash.

## Fanamarihana

- Ny sary dia azo avy amin'ny sary public domain na anao manokana.
- Tsara ny sary maizina kely na landscape/portrait izay mety amin'ny cover.
