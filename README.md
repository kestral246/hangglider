Hang Glider Mod for Minetest
----------------------------
This is a fork of the minetest-hangglider mod by Piezo_ (orderofthefourthwall@gmail.com)

Which is located at:
    <https://notabug.org/Piezo_/minetest-hangglider>

This was last synched up with Piezo_'s updates from Nov 25.

- hud overlay and debug can be enabled/disabled.
- Added blender-rendered overlay for struts using the actual model.
- Reduced airbreak penalty severity
- gave glider limited durability.

I've made the following changes to the code:

- Slightly blurred Piezo_'s excellent strut overlay.
- Changed flight speed to increase smoothly. It starts at 1 and maxes out at 1.75.
- Use minetest.get_version() to automatically choose which set_attach offset to use depending on whether minetest version is 0.4.x or 5.x.
- Removed use of blank.png overlay.
- Detect when hangglider is no longer wielded_item and unequip if appropriate. *Don't hit 'Q' key during flight.*
- Added AUX key as hangglider equip alternative, in addition to left-click. This allows hangglider flight on Android clients.
- Wear is back and better than ever. Breaks on unequip rather than equip, so doesn't leave you falling from a cliff.
- Number of uses is configurable, currently defaults to 50, but expect this will need tuning.
- Updated pos offset for launching, so don't have unintended wear when standing.
- Added sound while flying. Loop derived from "Flag Flapping in Wind" by Felix Blume, CC0 1.0 Universal License.
