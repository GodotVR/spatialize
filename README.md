Spatialize
==========

**Spatialize** is a set of utilities for converting flat-screen 3D games into
immersive or semi-immersive XR experiences.

First Steps
-----------

The first step is just getting your project to start in OpenXR mode.

In "Project Settings":

- Check the **XR** -> **OpenXR** -> **Enabled** checkbox
- Check the **XR** -> **Shaders** -> **Enabled** checkbox
- Restart the Godot editor

Now, we'll need to add some nodes to your the main XR scene. This could be the
same as the flat main scene, or a new main scene just for XR, which can include
all the XR-specific nodes, and then perhaps instance your game scene inside of it.

In any case, add these to your main XR scene:

- `XROrigin3D`
- `XRCamera3D` as a child of the `XROrigin3D` node
- Add two `XRController3D` nodes as children of the `XROrigin3D` node,
  and set their "Tracker" properties to "left_hand" and "right_hand".

Finally, add an instance of the `start_xr.tscn` scene from XR Tools to your main
XR scene. This will automatically start OpenXR when your application launches.

Rendering
---------

When converting a flat-screen game to XR, there are multiple approaches that
you could take to rendering:

- **Immersive**: the 3D game world surrounds the player completely - they are
  _inside_ the game.
- **Portal:** the game world renders on the other side of a flat "portal",
  with either the real world room or a non-playable virtual environment
	surrounding the player.
- **Volume:** the game world renders within a 3D volume, which appears to
  float in their real world room, or in a non-playable virtual environment.

### Immersive

By default, with no other changes, when you launch your app, you will find
yourself inside your game world!

One challenge may be **scale**.

If you build your game such that `1.0` unit in the game world was the same
as 1 meter in the real world, then you won't have any problems. However,
3D games frequently use arbitrary scale, and so you may need to place your
game world in a parent `Node3D` with some scale applied.

If you do this, then you may find you have problems with `global_position`,
because it will now be in the scale of the XR world, rather than the game
world.

This addon provides some utilities to help with this:

```gdscript
const SpatializeUtils = preload("res://addons/spatialize/utils.gd")

func _process(delta) -> void:
  # [...]

  # Rather than using `global_position` get the position relative to your
  # "game parent" node, which holds the game world.
  var gp := SpatializeUtils.get_relative_position(self, game_parent)
```

This code will work both in XR and non-XR, so long as you use the right
`game_parent` for each mode.

### Portal

Another option is showing the game world through a portal, that could
simply be a floating panel, or be affixed to a real world wall.

Godot supports stencils since Godot 4.5+, which is the easiest way to make
a portal. This addon provides a class called `Stencilizer` to make it easier
to make stencil-based portals.

```
const Stencilizer = preload("res://addons/spatialize/stencilizer.gd")

@onready var portal_mesh: MeshInstance3D = %PortalMesh
@onready var game_parent: Node3D = %GameParent

var stencilizer := Stencilizer.new()

func _ready() -> void:
  # The portal_mesh should be a MeshInstance3D with a QuadMesh. 
  # Use stencilizer to setup its material as a portal.
  stencilizer.setup_portal_material(portal_mesh)

  # Then use stencilizer to setup the material on all the meshes in the game world.
  # This will work for anything that uses `StandardMaterial3D` - if you use custom
  # `ShaderMaterial`'s, then you'll need to update those manually.
  stencilizer.setup_object_materials(game_parent)
```

In order to see the real world around you, edit the `StartXR` node that we added
from XR Tools, and check the **Enable Passthrough** property.

### Volume

A volume is basically a portal, setup just like we did in the previous section,
but using a `BoxMesh` rather than a `QuadMesh`.

And you may also want to scale your game parent even more, so it looks like a
diorama.

However, if you were to just run your game like this, it wouldn't really feel
like it's in your room, because Godot's render distance isn't limited to the
volume. So long as you're looking through the cube, it will render the full
far distance of the camera.

To fix this, instantiate a `cube_depth.tscn` scene from this addon into your
main XR scene, and make the mesh the same size and position as your cube shaped
portal.

This will fill the depth buffer to prevent rendering anything beyond the bounds
of the cube.

User Interface
--------------

Your game probably has some 2D user interface, like a menu or a HUD.

The simplest way to get these into your game, is to instantiate a
`viewport_2d_in_3d.tscn` from XR Tools and setting its **Content** -> **Scene**
property to point to your top-level UI or HUD scene.

Then instantiate `function_pointer.tscn` scenes from XR Tools under each of the
`XRController3D` nodes in your main XR scene. This will give the user pointers
attached to their hands which they can use to click inside the 2D UI.

See the [XR Tools documentation](https://github.com/GodotVR/godot-xr-tools/wiki)
for more details.

Input
-----

Input from XR controllers doesn't normally come through Godot's input system,
and instead uses a different system.

However, if you instantiate a `controller_input.tscn` scene from this addon
in your main XR scene, it will automatically convert input from XR controllers
into gamepad input in Godot's normal input system.

If you've changed the default OpenXR action map, you will need to update
the properties on the node to match. However, if you've kept the default values,
it should just work!
