using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerState : MonoBehaviour
{

    public SpatialProperties playerProperties;

    private Vector3 Position { get; set; } = Vector3.zero;
    private Vector3 Velocity { get; set; } = Vector3.zero;

    // Update is called once per frame
    void Update()
    {
        Position = playerProperties.Position;
        Velocity = playerProperties.Velocity;
        Shader.SetGlobalVector("_xp", new Vector4(Position.x, Position.y, Position.z, 0));
        Shader.SetGlobalVector("_vp", new Vector4(Velocity.x, Velocity.y, Velocity.z, 0));
        Shader.SetGlobalVector("_xo", new Vector4((float)2.3917, (float)1.4782, (float)0.5710, (float)0.000));

        print("Position: " + Position);
        print("Velocity: " + Velocity + "; magnitude: " + Velocity.magnitude);
    }
}
