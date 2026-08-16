# Trumpy's Odyssey — Game Bible

Original design brief, preserved verbatim from the project's Drive folder.

---

Please build a video game playable on Win11 using all original maps, artwork, sounds, music, joystick support that is a metroidvania style collectathon. There should be little alien creatures all colors of the rainbow that make sounds as you get closer to them, soon as you collide with their sprite they fly around you leaving magic sparkles in their wake and yell "Trumpy!" They sort of look like Alf but a harder, longer snout!

The game will have 8 distinct environments with their own theme and 101 secrets hidden throughout in cracked walls where bombs open a secret entrance to the area where you grab the secret, two lit torches on either side and a distinct icon for each item.

These 101 secret items will all be ridiculously overpowered ranging from 25% to 100% increase to positive traits, or decrease to damage taken, magic cost of spells, fall damage, fire damage, ice damage... the idea is they all become part of a special inventory of secrets with their own UI to look through that tells you the effect, and all of them stack, every single one should feel unique and please generate a name based off Greek mythology like "Blessed Shield of the Gorgon" and their names should follow a color convention based on the amount of the effect, 25% is rare and then EPIC, LEGENDARY and finally for something with 100% effect; MYTHIC.

The game tiles should be unique to every world, tiles with secrets behind them should look slightly different than a normal tile, but the secrets are always behind a tile that is a modified version of a regular tile.. if it's a tree tile, the secret tile version will look like a dried tree and can be burned with a magic lamp or fire stick or bomb could set it ablaze... it's a game of adventure and exploration.

Other worlds can be visible from the starting world but inaccessible till you gain some item or ability that lets you pass some barrier to the new areas, again these all will be overt parts of the game in item inventory, separate from the secrets, not a single secret will be necessary to finish the game but as they stack they will make it so much easier. If you find them all you enter Zeus mode, can't take damage, unlimited ammo/expendables like bombs, arrows, magic, double walk speed, etc.

Invent necessary items to progress from games like Zelda, drops off bosses, a dungeon in each world, each with unique tiles related to that worlds theme.

The game should have SNES quality graphics with multi layer parallax giving a sense of depth to the game.

Save this whole text of the email as the game bible in the directory you create on the Google drive for this game, there should also be a built in hook for you to play test the game and record the audio/video from the game to save as an MP4.

The sprite for our protagonist will start off in a green tunic, then if he reaches at least 100% fire damage mitigation his tunic turns blue, if he reaches at least 100% freeze mitigation the tunic turns blue, if both exceed/reach at least 100% mitigation the tunic becomes purple.

The animation for walking is smooth and works in all 4 directions, using items animate appropriately when it makes sense to do so.

Enemies are about and some have regular paths they patrol but upon seeing or hearing you can come after you, resetting if you leave that screen, and come back.

All enemies will have animations for all directions and be unique to that world and fit with the theme, in addition to Trumpys of all colors, you can also collect little jewels with different colors grant different total values gem pouch starts small keeps getting bigger as you progress through the game and there will be caves or stores where you can purchase consumables ike bombs, arrows, fire sticks, health potions, mana potions, both at the same time potions.

Each world should have at least 8 screens to it and 1-3 secrets hidden in each screen of each world.

Take any and all missing cues necessary to make a functional game from the original NES Zelda game, but remember to aim for SNES quality graphics or better. Use whatever programming language you estimate would be best for this game, name it something that will give its Greek mythology background a nod... build as much of the roadmap you need to get started, but finish the list of secret items and their names first off, then work on icons to represent them in game as a starting point.

---

## Notes

- **"Trumpy"** is an original fictional creature — a rainbow-colored, Alf-like alien with a longer/harder snout. Not based on any real person; the name is purely a whimsical creature name chosen for this game.
- Engine chosen: **Godot 4** (see `GODOT_SETUP_GUIDE.md`).
- Full 101-secret list with names, rarities, and effects lives in `data/secrets_101.json`.
