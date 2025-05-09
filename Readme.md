# Baratza Encore Burr holder 3d model

3d Model for Baratza Encore burr holder - remixed from thingiverse: <https://www.thingiverse.com/thing:1731803>

## Thingiverse

Published based on : 

### Thingiverse Description

Baratza burr holder re-engineered from Michał Barczewski's version on thingiverse: <https://www.thingiverse.com/thing:4900741>

I've made some heavy handed changes
- redesigned some parts to be more fit to 3d printing & PETG, regarding strength overall and precision
- most noticeable are: a full on outer threading instead of small original tabs ; thicker rings on top for easier printing and sturdiness
- added a rugged outside for manual screwing/unscrewing when testing

Model available on: https://github.com/duquesnay/baratza_burr_holder.git

### Print notes
(GD After a bit of trail & error)
- PETG is the way. PLA is too hard and won't handle the friction of the outer threading for a part so thin. Everything is small and put together tight in the grinder so the flexibility is not getting in the way. Also, heat resistance is never bad, grinding creates heat
- 0.2 layer height needed to gives a smooth threading
- 0.43 layers width w 0.6 nozzle
- wall count of 3 w 0.6 nozzle, the part is mostly solid.
- no support: it never comes out clean from the outer thread, any bits add friction
- made to use straigt out of the printer 

## Code style notes
I've made a lot of refactoring from the original code, based on software coding experience
- went hard Clean Code principles to refactor the file: named most hard coded value as variables and modules renamed to express the function of the part. Should be easier to work on
- redesigned the shape hierarchy so each part is visualized independently (different colors)

## Design Notes
Recent updates:
- BOSL2 library integration for advanced features
- Printing upside down 
  - prevents support since the top part of the millstone, main point of pressure on it, is flat
  - had to extend external tabs -now a ring to the max height
- Outer thread
  - Replaced middle tab with thread_helix - smoother & stronger threads
  - Triple-start trapezoidal thread design - easy printing, easy sliding, but precise holding (since thread goes all the way around)
  - Thread params: 0.3 turns, 2mm pitch, 1.5mm depth (max is 2 but not more friction and printing issue, lead-in for easy engagement
- Top part
  - Replaces flimsy top tabs with full rings, going all the way up for support. Nothing else needed
  - There's a flat bridge between the upper rings but it prints easy at this dimension (2mm in circle)
- Bottom
  - cylinder segments is split by sections, to work on each feature independently
  - the tabs retaining the millstone have vertical slit for flexibility, there must be a stronger way, they might need a bit of care... but also do push it strongly 

 ## Todos
- [X] remove pointless cutouts on bottom top shoulder
- [X] remove useless shoulder between top and bottom
- [X] replace top tabs as a full ring for resistance and printing
- [X] thicken the stabiliser ridge to limit movement of the burr
- [X] fine-tuned the spacing between the rings for taking in the rubber part

## License
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0) <https://creativecommons.org/licenses/by-nc-sa/4.0/>
