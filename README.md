# Loatheb Rotate
This addon helps setting up rotations for specific classes or specific roles in raid.
  
<img src="https://github.com/Sentilix/LoathebRotate/blob/main/LoathebRotate/_assets/loatheb-rotate-0.4.4.png?raw=true" />

While it is more efficient if all involved players can view the list by themselves, ultimately not all raid members need to install the addon, considering a raid leader/assistant is willing to tell the rotation e.g. with voice comm.

This addon is heavily based on SilentRotate addon by Vinny, which again is based on the work of Slivo for the TranqRotate addon, which you might want to install if you are interested only in Hunter’s Tranquilizing Shot rotation.

 
## Preparation
Before the fight begins you should set up the desired healing rotation:
Players (healers) in the list can be drag'n'dropped to change their order. Healers pushed to the very bottom are backup players who do not enter the normal rotation.
The list may be setup by another class. For example, a warrior raid leader may select the "Loatheb" mode and change the order of players, even though the warrior will not be in the list.
The list is shared across all raid members who have installed the addon.
 
## Loatheb
The next player in the rotation is highlighted in the list.
Once a player has cast a spell that triggers the rotation, a cooldown bar is shown in this player’s bar and the next player in the rotation is highlighted.
Disconnected players and dead players do not take part in the rotation anymore and appear as gray or red, respectively.
Tracks when Loatheb’s Corrupted mind prevents a healer from casting a healing spell for 60 seconds
This feature is still in development, so feel free to report any bugs
 
 
## Slash Commands
LoathebRotate offers a few commands to control the addon, although for daily use they are not really needed.
Commands can be invoked by typing /loathebrotate <command> or using the short form /loa <command>.
 
`/loa toggle` - show or hide the main window.<br>
`/loa show` - show the main window.<br>
`/loa hide` - hide the main window.<br>
`/loa lock` - lock the main window (it can no longer be moved)<br>
`/loa unlock` - unlock the main window. <br>
`/loa report` - post healing rotation in raid.<br>
`/loa settings` - open / close the configuration window.<br>
`/loa history` - open / close the history window.<br>
`/loa version` - check other player's LoathebRotate version<br>
