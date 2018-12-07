Hang Glider Mod for Minetest
----------------------------
This is a fork of the minetest-hangglider mod by Piezo_ (orderofthefourthwall@gmail.com)

Which is located at:
    <https://notabug.org/Piezo_/minetest-hangglider>

**This is my experimental version and is not intended for general use.**

This was synched up with Piezo_'s updates from Nov 25.

- hud overlay and debug can be enabled/disabled.
- Added blender-rendered overlay for struts using the actual model.
- Reduced airbreak penalty severity
- gave glider limited durability.

I've made the following changes to the code:

- Slightly blurred Piezo_'s excellent strut overlay.
- Piezo_ also increased flight speed to 1.75.  This was OK, but the transition seemed too abrupt.
    - I changed flight speed to also increase smoothly. It starts at 1 and maxes out at 1.75.
- Use minetest.get_version() to automatically choose which set_attach offset to use depending on whether minetest version is 0.4.x or 5.x.
- Removed use of blank.png overlay.
- Detect when hangglider is no longer wielded_item and unequip if appropriate. *Don't hit 'Q' key during flight.*
- Added AUX key as hangglider equip alternative, in addition to left-click. This allows hangglider flight on Android clients, but I needed to disable tool wear for now.
