/**
 * Grab linear and angular position, velocity, and acceleration data from corresponding properties.
 * 
 * Used to fetch spatial parameters for HMD and/or controllers.
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class GlobalProperties : MonoBehaviour
{
    public bool IsSpatialDistortionEnabled = true;
    public bool IsSpotlightEnabled = true;
    public bool IsDopplerEnabled = true;

    public float LightSpeed;
    public float SpaceScalar;

    public InputActionProperty positionProperty;
    public InputActionProperty rotationProperty;
    public InputActionProperty velocityProperty;
    public InputActionProperty angularVelocityProperty;
    public InputActionProperty accelerationProperty;
    public InputActionProperty angularAccelerationProperty;

    public Vector3 Position { get; private set; } = Vector3.zero;
    public Quaternion Rotation { get; private set; } = new Quaternion(0, 0, 0, 1);
    public Vector3 Velocity { get; private set; } = Vector3.zero;
    public Vector3 AngularVelocity { get; private set; } = Vector3.zero;
    public Vector3 Acceleration { get; private set; } = Vector3.zero;
    public Vector3 AngularAcceleration { get; private set; } = Vector3.zero;
    
    // Update is called once per frame
    void Update()
    {
        Position = positionProperty.action.ReadValue<Vector3>();
        Rotation = rotationProperty.action.ReadValue<Quaternion>();
        Velocity = velocityProperty.action.ReadValue<Vector3>();
        AngularVelocity = angularVelocityProperty.action.ReadValue<Vector3>();
        Acceleration = accelerationProperty.action.ReadValue<Vector3>();
        AngularAcceleration = angularAccelerationProperty.action.ReadValue<Vector3>();
    }
}
