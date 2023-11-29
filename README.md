# Another Lönn Plugin

This plugin adds:
- a **styleground file picker** that works with both unzipped mods and the graphics dump
- a **styleground preview** that lets you see what your parallaxes will look like
- keybinds to **snap selected objects to a customisable grid** (<kbd>ctrl + shift + arrow keys</kbd> / <kbd>shift + S</kbd> by default), and to **view that grid** (<kbd>ctrl + shift + G</kbd>)
- keybinds to **pan the view**, defaulting to <kbd>alt + </kbd><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd>
- a tool to **move rooms** (even several at a time)
- a tool to **teleport the player** using Everest's DebugRC interface
- a **coordinate viewer** (<kbd>`</kbd> by default)
- scripts (for use with [Lönn Scripts](https://gamebanana.com/tools/8050)) to:
  - **copy and paste stylegrounds** using the clipboard, so you can move them between maps, edit them in a text editor, or send them to others;
  - **convert fillers into filler rooms**, for easier editing
  - **fix lightbeams placed in Ahorn**

It also supports the following experimental add-ons, which you should **only put in your mods folder if you're actively using them**, and **could break even unrelated plugins very easily (!)**:
- a **brush mask**, in the edit menu, which lets you make tools only replace either air or ground, rather than both, available [here](https://github.com/microlith57/AnotherLoennPlugin/releases/tag/brushmask-v1.0.0)
- a **colourgrade preview**, available [here](https://github.com/microlith57/AnotherLoennPlugin/releases/tag/colorgrading-v1.0.0)

These features can be configured; see [the wiki](https://github.com/microlith57/AnotherLoennPlugin/wiki) for information.

Note that this will intentionally stop working for newer Lönn versions than it is updated for (currently v0.7.7), to make sure it doesn't break things.

Some code in this repository is derived from [Lönn](https://github.com/CelestialCartographers/Loenn) under the MIT License.
