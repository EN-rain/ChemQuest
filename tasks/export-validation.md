# Export validation (2026-09-08)

Godot 4.6.1 headless exports were rerun from the repository root after the
responsive-layout implementation. Both commands completed successfully and
wrote only under ignored `tasks/builds/`.

```powershell
godot --headless --path . --export-debug "Android" tasks/builds/chemquest_android.apk
godot --headless --path . --export-debug "Web" tasks/builds/web/index.html
```

## Outputs

| Output | Bytes | SHA-256 |
| --- | ---: | --- |
| `tasks/builds/chemquest_android.apk` | 91,142,654 | `CDCB23E934F53EA107669DDD70357C22B6449CE1BE8AD86E1AC2FC25B1E03C61` |
| `tasks/builds/chemquest_android.apk.idsig` | 726,451 | `0062978823A9A03CC3ADF5AEAF2AD410DC78C30CAEEB47FA2E87FDD25E30C49E` |
| `tasks/builds/web/index.html` | 5,442 | `4E8344B4AC0E464F52E6A82F830C2192EB9033AF7FBFA7E2EA90422D85DCA760` |
| `tasks/builds/web/index.pck` | 63,124,992 | `9EE03196E7051294FACF15C264B7349CFE104BB9A6D4F5304FC3D55F824D62DD` |
| `tasks/builds/web/index.js` | 279,925 | `8EE40F1DFAC8EA4D9828CBE4F17FBF4834BA3E7708C1FE5A96C3388977F5EF38` |
| `tasks/builds/web/index.wasm` | 35,739,700 | `148A6727FE28AE28F2CAC38484A6D42ACF1D3DA969F2527268817CAECF87A985` |
| `tasks/builds/web/index.png` | 21,443 | `3CB4495C0B98DFBE4B663CBF2B6836473572339BEB66D902367893162A70BE0E` |
| `tasks/builds/web/index.icon.png` | 11,458 | `B49C3604049373B7601826D9B7B6B4DDC8BB77FCACC62B86F1FA270ACD56C8FF` |
| `tasks/builds/web/index.apple-touch-icon.png` | 13,497 | `3769A3BE93E7429BB560B045719B74E4F6338A33311A0F36C87243E220278B12` |

## Source/archive checks

- APK archive listing and embedded PCK string scan: 0 `.aseprite` entries/strings and 0 `.zip` entries/strings.
- Web PCK binary path scan: 0 `.aseprite` strings and 0 `.zip` strings.
- Presets exclude `*.aseprite,*.zip` for both targets. `tasks/`, `tests/`, and `docs/` are additionally hidden from the export scan by their `.gdignore` boundaries.
- The local `addons/auvrynt_bridge` editor plugin remains enabled in the project and leaves three `res://addons/` strings in the Web pack; it is not a runtime dependency and remains an owner-controlled local-only release decision.

## Warnings requiring owner follow-up

The packages are buildable, but the logs report duplicate UID warnings from the retained legacy/duplicate trees and the pre-existing Auvrynt bridge listener error on port 49322. These are recorded release blockers, not hidden or suppressed failures. See `docs/decisions/0002-provisional-resource-ownership.md` and the owner decisions in `tasks/todo.md`.

## Playability-recovery rerun

After the route recovery changes, debug exports were rerun into ignored
`tasks/builds/` paths and completed successfully:

| Output | Bytes | SHA-256 |
| --- | ---: | --- |
| `tasks/builds/recovery_android.apk` | 91,155,521 | `b83940f4e90f267dcb58ff2db05790a8e93ac977d2e44ea4ac67093cd8be9807` |
| `tasks/builds/web/recovery/index.html` | 5,442 | `c9204380965ff61fff86480cf5a60a60a38e0241922dacf6490bfb21ab71e41a` |
| `tasks/builds/web/recovery/index.pck` | 63,453,492 | `5c1ffa9defa94c8de1daf01bf327f80459922ac38158b2a9e2aec12828a43f12` |
| `tasks/builds/web/recovery/index.wasm` | 35,739,700 | `148a6727fe28ae28f2cac38484a6d42acf1d3da969f2527268817caecf87a985` |

The recovery APK and Web PCK each contain zero `.aseprite` and `.zip` source
strings. The same duplicate-UID and local Auvrynt warnings remain as above.
