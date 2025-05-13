# What is this?
This implements an algorithm for a Dubins Path for Godot in GDscript to use in your project

# How to use
To use this code, take this project and put it under the addons folder in your project. You can then use a DubinsPath2D node in your tree, or call DubinsPathMath.compute_dubins_paths to create a dubins path directly. Run the demo project by running demo.tscn(and click/drag the mouse to move the truck) to see it in action.

# What is a Dubins Path?
Given a start point, start direction, end point, end direction, and minimum turning radius, it gives you the quickest path from your start point to your end point. Useful when modeling cars, train tracks, and other vehicles that may have a minimum turning radius

See more here:
https://en.wikipedia.org/wiki/Dubins_path

# Demo
 ![me](demo.gif)

