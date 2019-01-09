# LaserCat

LaserCat allows users to visualize hypothetical laser-to-camera offsets by shooting lasers that attatch cats on surfaces. 


One neat feature is the off-principal axis hit testing done by the 'laser'.

This is a very primative form of collision detection bewteen virtual objects and real surfaces. 

Currently, the collision detection is very basic and inefficient.  

It simply checks if any of the world map points are contained in the bounding cylinder of the laser. 

One possible extension for this app would be to create a smarter way to do collision detection,
perhaps masking points that will have no chance of causing a collision. 

Another possible extension would be to improve the visualization of surfaces by constructing an adaptive triangle mesh
from world map points. 

These extensions are left until later, as the main goal of  visualizing laser-to-camera offsets has been achieved.

