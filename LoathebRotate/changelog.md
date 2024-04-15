## LoathebRotate Changelog

#### v0.4.1 (2024-04-15)
- Bugfix: Fixed a LUA error in Debug mode if bossId or spellId was not set.
- Bugfix: Fixed an error where synchronization was not done when re-joining a raid.

#### v0.4.0 (2024-04-14)
- Bugfix: sync request was messed up between clients and has been rewritten to
  circumvent a bug in Blizzard's UnitGUID API function.
  This is a breaking change - versions below 0.4.0 will not be able to synchronize data.
- Bugfix: Window will no longer show at Login unless configured to do so.
- Promotion is now needed to change or reset rotation order.
- Colours updated.

#### v0.3.0 (2024-04-13)
- Added configurable debug mode, removed old testMode
- Removed lots of unused code, such as right-click hunter assignments
- Moved icons to 2nd row of main frame
- Non-healer classes will no longer see window unless they do /loa show
- Announcements updated - Whisper added and set as default option.

#### v0.2.3 (2024-04-12)
- Announcements implemented.
- Bugfix: Drag'n'Drop is no longer interrupted by the UI refresh task.
- Bugfix: Window position is now saved and loaded correctly.
- Bugfix: Aura and Spell rotation works again.
- Fixed even more LUA errors. The addon seems a bit more stable now.
- Added internal test mode: can trigger Corrupted Mind via power word: shield.

#### v0.2.2 (2024-04-11)
- Targetting Boss will now broadcast OpenWindow to all clients.
- UI updates will now only be called every 10th second outside active periods.
- Fixed more LUA errors.

#### v0.2.1 (2024-04-10)
- Fixed LUA error in history.
- Fixed message delivery, including cross-realm handling.
- Fixed disconnect status not being shown correctly.
- Fixed loading/joining raid not being updated correctly.

#### v0.2.0 (2024-04-10)
- All modes except Loatheb removed
- Synchronization rewritten
- Version check rewritten

#### v0.1.0 (2024-04-04)
- Branched from SilentRotate version 1.0.1 by Vinny
- Updated ACE3 libraries to newest version
- Fixed a few issues with the 1.15.x client.
