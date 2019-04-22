# LaserCat

Check out the video demo in the Repo: LasarCatDemo

LaserCat is an iOS app that was designed to function as both standalone product, and as a stepping stone 
toward the larger goal of developing portable lasers that can attach to iPhones, and enhance Augmented
Reality experiences.

In order to use a laser in AR, it's position and orientation relative to the iPhone camera must be determined,
described here as laser-to-camera calibration.

LaserCat executes an important step in the larger goal of laser-to-iPhone integration, by validating hypothetical 
laser-to-camera calibrations. 

LaserCat does this by showing the real-time effects of various laser-to-camera position and rotation offsets,
thereby allowing users to ensure they have the correct understanding of how to apply the offsets. 

Users can adjust the x, y, z, pan, and tilt offsets of the virtual laser relative to the device camera and 
see the resulting effects. Note, only 5 degrees of freedom are necessary to completely specify the calibration,
since a roll offset has no effect, due to the cylindrical symmetry of the laser.

Why cats?

While the mathematics involved, and the off-axis hit testing of real-world objects grabs many users' attention,
it has been found through testing that engagement with the app increases when the lasers feature cats, and cat noises.

Furture work for this app:

One possible extension for this app would be to create a smarter way to do collision detection,
perhaps masking points that will have no chance of causing a collision, or a smarter search algorithm. 

Another possible extension would be to improve the visualization of surfaces by constructing an adaptive triangle
mesh from world map points. 

These extensions are left until later, as the main goal of visualizing laser-to-camera offsets has been achieved.

