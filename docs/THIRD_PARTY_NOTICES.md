# Third-party notices

This file is the repository’s attribution and provenance index. It records what can be established from files currently present; it does not infer a license where the source package does not include one.

## Lilita One

- Runtime copy: `assets/LilitaOne-Regular.ttf`
- Author/copyright shown by the bundled notice: Juan Montoreano (2011), reserved font name Lilita.
- License: SIL Open Font License 1.1.
- Notice source: `games/chapter_one/hometown/building_two/level/Assets/FONTS/OFL.txt`.
- The ZIP at `games/chapter_one/hometown/building_two/level/Assets/FONTS/Lilita_One.zip` contains the same font and notice and is retained as source provenance. It is excluded from Android/Web exports.

## Nougat

- Source archive: `games/chapter_one/hometown/building_two/level/Assets/FONTS/nougat.zip`.
- Contents: `Nougat-ExtraBlack.ttf`.
- License/author: not present in the archive or repository scan; provenance is unresolved and must be confirmed before a public release.
- The archive is excluded from Android/Web exports and is not referenced by runtime scenes.

## Treasure Hunters art pack

- Source art: 42 `.aseprite` files under the two `.../mattermaze/Assets/Treasure Hunters/` trees.
- Runtime derivatives: PNG files in the canonical `games/chapter_one/hometown/building_two/level2-2/mattermaze/Assets/Treasure Hunters/` tree.
- License/author/source URL: no notice or readme is present in the repository; provenance is unresolved. Do not publish a release until the owner records the pack’s license and attribution.
- Aseprite sources are excluded from Android/Web exports.

## Pixel Adventure art

- Runtime art is under `games/chapter_one/hometown/building_two/level2-2/mattermaze/Assets/Pixel Adventure 1/Free/`.
- License/author/source URL: no notice or readme is present in the repository; provenance is unresolved. Confirm the pack license and attribution before release.

## Project-authored assets

Project-authored artwork, scenes, scripts, and audio are not third-party notices. Their canonical paths and duplicate status are tracked in `tasks/manifests/asset-consolidation.md` and the feature dependency manifests.

## Release gate

Known notices are preserved in place, unresolved packs are explicitly recorded, and source archives are export-excluded. Android/Web release approval remains blocked until the owner supplies provenance/licensing decisions for Nougat, Treasure Hunters, Pixel Adventure, and any other imported pack discovered during final review.
