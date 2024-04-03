# Loatheb Rotate
This addon helps setting up rotations for specific classes or specific roles in raid.
  

While it is more efficient if all involved players can view the list by themselves, ultimately not all raid members need to install the addon, considering a raid leader/assistant is willing to tell the rotation e.g. with voice comm.

This addon is heavily based on SilentRotate addon by Vinny, which again is based on the work of Slivo for the TranqRotate addon, which you might want to install if you are interested only in Hunter’s Tranquilizing Shot rotation.

 

## Preparation
Before the fight begins, choose the correct mode you want to setup (Loatheb, Misdirection, Grounding Totem, etc.).
The SilentRotate window displays the list of raid members who may be part of the rotation. Only relevant members are displayed for a given rotation, e.g. only hunters are displayed in Misdirection mode.
Players in the list can be drag'n'dropped to change their order. Members pushed to the very bottom are backup players who do not enter the normal rotation.
The list may be setup by another class. For example, a warrior raid leader may select the "Loatheb" mode and change the order of players, even though the warrior will not be in the list.
The list is shared across all raid members who have installed the addon. Each player can choose its own mode, in which case the list is shared between players who have selected the same mode.
 

## Combat
The next player in the rotation is highlighted in the list.
Once a player has cast a spell that triggers the rotation, a cooldown bar is shown in this player’s bar and the next player in the rotation is highlighted.
Disconnected players and dead players do not take part in the rotation anymore and appear as gray or red, respectively.
 

## History
A History window keeps track of events that are relevant to a given mode.
For example, in Grounding Totem mode, the History window displays when a totem is summoned, when it absorbs a spell, or when it has been replaced by another Wind totem.
 

## Modes
There are up to 15 modes: Tranq, Loatheb, Distract, FearWard, AoE Taunt, Misdirection, Bloodlust, Grounding Totem, Battle Rez, Innervate, BoP, Freedom, Soulstone, Soulwell and Scorpid.
The mode is selected automatically upon login and can be changed by clicking on top of the SilentRotate window.
Not all modes are visible because the number of buttons would make the UI too messy.

These modes are visible by default in Classic Era:
* Tranq
* Loatheb
* Fear Ward

You can select which modes are visible in the Settings panel.

 

### Tranq
Displays Hunters only
Tracks when a tranq-able boss goes into Frenzy and shows an alert to the hunter who should cast Tranquilizing Shot
The rotation switches to the next hunter when a hunter has cast or missed a Tranq Shot
For more information, please check the TranqRotate details
If you want the best experience for fighting Vanilla bosses using your level-60 hunter, TranqRotate provides additional options that you may find useful. Make sure to check it out!
 

### Loatheb
Displays healer classes only (Druids, Paladins, Priests, Shamans)
Tracks when Loatheb’s Corrupted mind prevents a healer from casting a healing spell for 60 seconds
This feature is still in development, so feel free to report any bugs
 

### Fear Ward
Displays Priests only, and only Dwarf Priests in Classic Era
Tracks when a fear ward spell has been cast
 

## Known Limitations
Only one mode can be active at a time
Switching back and forth between modes may not restore the correct order of raid members and may display the wrong targets
Loatheb mode does not filter out non-healer specs, such as Feral Druids
AoE Taunt mode does not filter out non-tank specs, such as Restoration Druids
Talents which modify spells, such as Guardian's Favor in the Paladin tree, are not tracked
Group-based modes, such as Bloodlust, only track the buff from its initial caster, not every target in the group
Tranq mode does not filter out hunters who have not learned the Tranquilizing Shot ability yet, e.g. løøted the Tome of Tranquilizing Shot from Lucifron
More generally, the addon does not check, and sometimes cannot check, if players have learned their abilities from their respective class trainers
Any raid member can change the order of players in the list
Raid members who have not installed the addon must be in the range of 45-ish yards to detect their activity
Localization is incomplete.
