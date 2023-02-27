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
        Shader.SetGlobalVector("_playerPos", new Vector4(Position.x, Position.y, Position.z, 0));
        Shader.SetGlobalVector("_vPlayer", new Vector4(Velocity.x, Velocity.y, Velocity.z, 0));

        Shader.SetGlobalVector("_playerOffset", new Vector4(Position.x, Position.y, Position.z, 0));
        Shader.SetGlobalVector("_vpc", new Vector4(Velocity.x, Velocity.y, Velocity.z, 0));

        //print("Position: " + Position);
        print("Velocity: " + Velocity + "; magnitude: " + Velocity.magnitude);
        float beta = Shader.GetGlobalFloat("_Beta");
        Vector4 VParallel = Shader.GetGlobalVector("_VParallel");
        Vector4 VPerp = Shader.GetGlobalVector("_VPerp");
        Vector4 rel = Shader.GetGlobalVector("_rel");
        print("rel: " + rel);
        //print("Beta: " + beta);
        //print("VParallel: " + VParallel);
        //print("VPerp: " + VPerp);
    }
}
