# Baratza Encore Burr holder 3d model

3d Model for Baratza Encore burr holder - remixed from thingiverse: <https://www.thingiverse.com/thing:1731803>

## Thingiverse

Published on thingiverse: <https://www.thingiverse.com/thing:4900741>

### Thingiverse Description

Baratza burr holder remixed from johnyz's design.

I've made some modifications to make it easier to print, and in the process of that redone the scad file to make it easier to modify.

Changes to model:

- made bottom ring thicker (1.5mm) - it was too thin, printed unevenly and broke when removing supports. I suggest setting it (bottom_thickness parameter) to be equal to 3 times line width
- extended burr holder tabs and sides to the bottom to avoid needing supports (tabs broke off with supports in both initial prints) - this can be changed to original by changing cutouts parameter
- made side tabs thinner - i found they printed fine, instead i broke one off trying to grind/cut it down to fit

Scad file is available on github <https://github.com/michaljbarczewski/baratza_burr_holder>

### Print notes

Default settings assume 0.2 layer height and 0.5 line width.
I've printed with wall count of 6 to make sure part is fully solid with no infill.

To print with different settings some parameters should be adjusted:

- bottom_thickness - should be multiple of line width - this also affects fit of the burr so may take some trial and error
- tab_mid_h - thickness of the 3 side tabs - should be multipole of layer height while also less than 1mm to fit into the grinder

## Design Notes

Recent updates:
- BOSL2 library integration for advanced features
- Replaced middle tab with thread_helix - smoother & stronger threads
- Triple-start trapezoidal thread design - quick & secure attachment
- Thread params: 0.3 turns, 2mm pitch, 1.5mm depth, lead-in for easy engagement
- Added beveled transitions to upper ring to eliminate stress points
- Replaced vertical slits with horizontal slots for better layer strength
- Inverted shoulder transition cone for better load distribution
- Reorganized bottom cylinder segments with continuous walls for integrity

 ## Todos
- [X] remove pointless cutouts on bottom top shoulder
- [ ] replace burrholder tabs by horizontal, closed flexible spring system
- [X] remove useless shoulder between top and bottom
- [X] replace top tabs as a full ring for resistance and printing
- [ ] thicken the stabiliser ridge to limit movement of the burr

## License

Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) <https://creativecommons.org/licenses/by-nc-sa/4.0/>
