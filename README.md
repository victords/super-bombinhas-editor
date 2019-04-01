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
using the pattern "&lt;game repository&gt;/data/img/bg/&lt;number&gt;.png". To make a
background available in the editor, it must be placed in the data/img/bg directory
of the editor as well.
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

### Terrain

The terrain components can be found in the left panel. They are:
* Tileset selector: the dropdown allows the selection of the tileset to be used in this
section. The available tilesets will be all the PNG files in the data/tileset
directory. Tilesets must be 10 x 10 tiles, 32 x 32 pixels each tile (so the overall
image must be 320 x 320 pixels). The tiles used for walls, passable blocks and ramps
must be in predefined positions; refer to existing tilesets to see the pattern.
* Wall: a solid block that can't be entered by the player from any direction.
* Pass: a "passable" block, which serves as floor, but the player can go through it
from the sides and from below. These are placed in rectangular areas, click and hold
on one corner and release on the opposite corner. Hold ctrl while doing this to make
it be placed behind other blocks.
* Hide: a foreground tile that can hide any elements behind it. In the game, it will
appear very similar to walls.
* Ramp: opens a menu with the predefined ramp sizes (in tiles). Click on the desired
size and then on the map to place the ramp.
* Other: choose any of the other tiles from the tileset. The behavior of this tile
will be defined by the value of the dropdown below, as follows:
    * w: the tile will work as a wall.
    * p: the tile will work as a passable block.
    * b: the tile will be background (no interaction with the player)
    * f: the tile will be foreground (no interaction with the player)

### Elements and Enemies

To place interactive elements, items and enemies, use the "OBJ" and "ENEMY" buttons
on the right. Both when clicked open a panel of elements to choose from. Many
elements and enemies allow arguments that change their behavior (and for some of
them the arguments are required). You can define arguments in the same way you
define entrance numbers (the field can be showed by pressing Enter or clicking the
"args..." button in this same panel). To find out which arguments are supported for
each element, you can check the constructor of the corresponding class in the
"items.rb", "elements.rb" or "enemies.rb" file from the game's source code (the
name of the class shows up when you hover over the element).

The elements and enemies that show up in the editor are defined by the images placed
in the data/img/el folder. Enemies are separated from the others by having a "!"
at the end of the file name (before the extension).

### The offset functionality

You can move everything in the stage or a selection by a number of tiles, both
horizontally and vertically, using the offset functionality. You can open the panel
by pressing Tab on the keyboard or clicking the "offset" button in the right panel.
To make a selection, hold Alt and click and drag from one corner to the opposite one
of the area you want to select.

## Remarks

* The source code is distributed under the GNU GPLv3 license and the image assets
(contents of the folders data/img and data/tileset) under the Creative Commons
Attribution-ShareAlike 4.0 license.
* This is a summary of how to use and extend the editor, but if you need more details
you can always reach out to
[victordavidsantos@gmail.com](mailto:victordavidsantos@gmail.com).
* As this editor was originally designed only for my own use, there are many things
you can do in the editor that will break the actual game. I didn't program any
validations regarding the arguments of the elements, for example;
moreover, the interactions between every combination of elements haven't been tested,
so it is very likely that you find combinations that generate strange behaviors or
even cause the game to crash.
