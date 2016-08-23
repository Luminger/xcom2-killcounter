TL;DR: Tactical UI now shows you how many enemies you've killed and, if you've
       already build the ShadowChamber, the total enemy count.

This mod adds a (very) simple counter to the Tactical UI which shows how many
enemies were killed so far. It will also show the number of total enemies in a
mission, as long as you've already build the ShadowChamber. 

So this mod doesn't show you anything which you didn't already know, but who
does exactly count how many aliens have been killed so far? While the total
enemy count will go up whenever reinforcements arrive, this also isn't
something you didn't already knew (as long as you counted fast enough). In case
you dislike this, there's an ini option to disable the total count.

If you never want to know the total count of enemies in a mission, paste the
following into your XComKillCounter.ini:

[KillCounter.KillCounter]
neverShowEnemyTotal=true

This mod is still in early development and likely to develop more features (and
bugfixes whenever needed). I'll do my best to keep it working, but this may
take a while as real life is a priority way before XCOM.

Possible future features:
 - Show the names (and count) of each enemy type killed, maybe in a tooltip. If
   you have any other idea how to visualize this properly (I'm not a UI 
   designer) please leave a comment [HIGH]
 - Give players the option to not count reinforcements into the total count
   [LOW]
 - Give players the option to move the UI wherever they please [LOW]

Features marked with [LOW] are questionable and might not be useful at all.
Please feel free to leave a comment if you do think a features marked as [LOW]
is worth implementing and I'll see if I raise the priority of it.