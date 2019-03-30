# Super Bombinhas Level Editor

This is the level editor for the platformer game
[Super Bombinhas](https://github.com/victords/super-bombinhas),
built with Ruby and the Gosu and MiniGL libraries.

## Running the editor

1. Install Ruby.
    * For Windows: [RubyInstaller](https://rubyinstaller.org/)
    * For Linux: [RVM](https://rvm.io/)
2. Install Gosu and MiniGL (see "Installing" [here](https://github.com/victords/minigl)).
3. Clone this repository.
4. Open a command prompt/terminal in the repository folder and run `ruby main.rb`.

## Using the editor

In order for the editor to work properly, you must have both this and the game's
repository cloned in the same directory. The editor loads and saves files directly
from the levels folder of the game's repository.

### Editing stages

After you launch the editor, in order to edit an existing stage, type in the fields
at the bottom the world, stage and section numbers. These numbers will compose the
path and name of the file to be loaded, following the pattern
"&lt;game repository&gt;/stage/&lt;world&gt;/&lt;stage&gt;-&lt;section&gt;".
For example, if you leave the default values and click "Load", the file
"data/stage/1/1-1" from the game repository will be loaded. When you click "Save",
the same fields and pattern will determine the file that will be saved (if the file
already exists, there will be a confirmation to overwrite; otherwise, a new file
will be created).

### Level properties

On the top panel there are the properties of the level (more specifically, the
section) being edited. These are:
* The width and height, in number of tiles. Edit the values in the fields and click
OK to change the size.
* The number of the background image. It will identify the background to be used
using the pattern "&lt;game repository&gt;/data/img/bg/&lt;number&gt;.png".
* The background music identifier. It will identify the background music to be used
using the pattern "&lt;game repository&gt;/data/song/&lt;identifier&gt;.ogg".
* The type of exit of the section. The first 4 options, which represent arrows
pointing up, right, down and left, indicate that if the player touches the corresponding
edge of the level, it will be automatically transported to the default entrance of
the next section (more on entrances later). The last option "-" indicates that touching
the edges of the level will have no effect (except dying by trespassing the bottom edge).
* The "dark" checkbox. If checked, this section will be in complete darkness except for
a small area around the player. This feature is not very useful by now, because there
are some other elements on the stage that should cast a light, but this hasn't been
developed yet.

### Entrances

To place an entrance on a section, use the "Bomb" button, at the right, and press Enter
on the keyboard to make the "arguments" field appear. Fill in the entrance number, press
Enter again and then click on the position of the map where the entrance should be.
A stage will not work unless there is at least an entrance for every section.
Furthermore, the number of the entrance must be unique across all sections of a same
stage. The "default" check box must be used for only one entrance per section. This
will be the starting point of the first section of the stage, and, on other sections
(not the first), it will be the point where the player is placed when it leaves the
previous section by touching one of its edges. The entrance numbers can be used as
arguments for other elements such as doors and check points.

