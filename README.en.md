# White Dragon Desktop Widget

[中文说明](README.md)

An **unofficial community project** by MissGPT-DragonDen, independent of and not endorsed by OpenAI. This Windows companion runs without an open ChatGPT webpage and is separate from the native ChatGPT pet project. **1.0.0 public** derives from accepted v8, adding bilingual UI, a separate public settings profile, and release cleanup; it is not an unchanged copy of v8.

## Run and recover

Extract the entire Windows ZIP into a stable folder. Double-click `Start.vbs`, or use `Start.cmd` if VBS is unavailable. Requires a Windows desktop, Windows PowerShell 5.1 and WPF/.NET Framework. No Python, npm, administrator rights or installer is needed. Scripts are unsigned; do not bypass organizational restrictions. `Diagnostic.cmd` is an optional visible troubleshooting console.

Right-click or long-press the character for its menu. Drag and snap to edges, press feedback, full-body/half-body switching, per-slot local PNG/JPEG import, scaling, position saving and custom/random lines are supported. The full-body layout uses a small inward-facing speech triangle; the half-body layout displays usage on its black placard. The window stays off the taskbar. Use the tray to show/hide/exit, or `Restore.cmd` if you cannot find it. Duplicate launches using the same settings restore the existing instance.

Choose Chinese or English from `语言 / Language`; Chinese is the default and the choice is saved. Custom dialogue is not forcibly translated. The public profile uses `%LOCALAPPDATA%/WhiteDragonWidgetPublic` and its own `WhiteDragonWidgetPublic.user-startup.vbs`, leaving private v8 settings and imported art untouched.

Windows sign-in startup is **off by default**. It creates only a current-user Startup-folder entry when explicitly enabled. Disable the menu toggle or run `DisableAutoStart.cmd` to undo it. After moving folders, toggle off/on to update the path; there is no automatic path tracking. Public-version upgrades retain their own existing settings and do not forcibly disable an existing startup entry.

## Automatic usage: requirements and scope

**Automatic usage is unavailable without an installed, logged-in, compatible official Codex client.** The widget does not bundle/install a client or initiate login. Character features still work. Client discovery checks `codex.exe` on PATH and the official Windows Codex installation location; changed layouts may not be discovered.

The documented official `app-server --stdio` method `account/rateLimits/read` reuses that client's existing login. It selects the unique 10080-minute weekly window in the `codex` bucket. Remaining percentage is `100-usedPercent`; reset uses official Unix-second `resetsAt` and displays in your local time zone. This is the shared Codex/Work weekly limit, **not a universal balance for ordinary ChatGPT conversations, API organization usage, or credits money**. Plans and shared scope are governed by OpenAI's current service rules. A different client account/window may not match your visible dashboard; compare your own account.

Refresh defaults to five minutes; choose 1/5/15/60 minutes, manual refresh, or disable it. The background read has a 25-second bound. Failures retain an explicitly old reading and its read time. Missing, ambiguous or expired data is never invented, and reaching reset does not imply 100%. Manual entry is clearly marked and is not live automation.

The widget does not open authentication files, copy tokens, use private HTTP interfaces or create login authorization. The official client internally handles its existing authentication and normal service requests, so usage checking is not fully offline. See [Privacy / security](PRIVACY.md).

## Licensing and releases

Our code and project-written documentation use [0BSD](LICENSE); our rights in the two named artworks are dedicated under [CC0-1.0](ASSET_RIGHTS.md). No attribution is required for our contributions; you may use, modify, redistribute and commercially use them. Third-party trademark, reference-image and system component rights are not granted. See [NOTICE](NOTICE.md) and [CHANGELOG](CHANGELOG.md).

The package contains no personal settings, account readings, screenshots, logs, credentials, reference materials or client binaries. `MANIFEST.json` lists public-file SHA256 values; `Build.ps1` packages an explicit allowlist.

## Validation and compatibility

Inherited v8 evidence covers the Windows WPF interaction, two appearances, tray/single instance, real official reads, retained old readings, cancellation and inward layouts, including the current 150% screen scale. Public release adds focused bilingual menu/tray/bubble/placard, persistence and text-fitting checks. No new quota read or complete historical UI rerun was performed. Multi-monitor, other DPI scales and real reboot/sign-in startup remain untested.

Official references: [Codex App Server](https://developers.openai.com/codex/app-server/) and [Using Codex with your ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan). Future client and API changes may affect compatibility.
