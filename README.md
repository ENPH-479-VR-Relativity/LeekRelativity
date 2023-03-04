# LeekRelativity

I named it LeekRelativity because I was thinking of cooking when I made the folder and we have farms and farms grow leeks.

Contains all the relativity code for our project - can (and should) be added as a submodule within relevant Unity projects.

## Setup Guide

### XR Interaction Hooks

In the Project/Assets tab navigate to "Samples/XR Interaction Toolkit/(version \#)/Default Input Actions" and open XRI Default Input Actions. The following actions should be added:

 - **Position** (*Value; Vector 3*) with binding "XR HMD/Optional controls/centerEyePosition"
 - **Rotation** (*Value; Vector 3*) with binding "XR HMD/Optional controls/centerEyeRotation"
 - **Velocity** (*Value; Vector 3*) with binding "XR HMD/Optional controls/deviceVelocity"
 - **AngularVelocity** (*Value; Vector3*) with binding "XR HMD/Oculus Headset/deviceAngularVelocity"
 - **Acceleration** (*Value; Vector3*) with binding "XR HMD/Oculus Headset/deviceAcceleration"
 - **AngularAcceleration** (*Value; Vector3*) with binding "XR HMD/Oculus Headset/deviceAngularAcceleration"

### Camera Properties Script

Navigate to "XR Rig/Camera Offset/Main Camera" (or similar) in your heirarchy. Add the "Global Properties" script this, and fill out the properties with the actions you just added. Set each property's "Use Reference" to True. For example, the Position property should have reference "XRI HMD/Position". Finally, set Light Speed to 5 (a decent starting value).

### Making an Object Relativistic

Add the "LeekRelativity/Materials/Relativistic Object" material to a given object, as well as the "LeekRelativity/Scripts/RelativityProperties" script. That script should have its "Global Properties" reference set to "Main Camera" (this should be the only option), and its "Object Pos" reference set to itself. 

#### Time Dilation

To give a readable dilated time value to an object, add the "LeekRelativity/Scripts/TimeDilation" script to the object and set the "Rp" property to the one attached to this object. The "Player Time" and "Local Time" values can be altered to start the timing at different points as desired - the script only calculates dilation iteratively. 

Other scripts can read off the "Player Time" value to perform effects. The value can be reset / modified as needed, e.g. resetting the time of a plant to zero after it has been harvested.

