/**
 * Grab player and object spatial parameters and the speed of light, pass along to shader.
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RelativityProperties : MonoBehaviour
{
    public GlobalProperties globalProperties;
    public Transform objectPos;

    public Vector3 xp { get; set; } = Vector3.zero;
    public Vector3 vp { get; set; } = Vector3.zero;
    public Vector3 wp { get; set; } = Vector3.zero;

    void Start()
    {
        Shader.SetGlobalFloat("_vLight", globalProperties.LightSpeed);
        objectPos = GetComponent<Transform>();
        globalProperties = FindObjectOfType<GlobalProperties>();
    }

    // Update is called once per frame
    void Update()
    {
        xp = globalProperties.Position;
        vp = globalProperties.Velocity;
        wp = globalProperties.AngularVelocity;

        Shader.SetGlobalVector("_xp", new Vector4(xp.x, xp.y, xp.z, 0f));
        Shader.SetGlobalVector("_vp", new Vector4(vp.x, vp.y, vp.z, 0f));
        Shader.SetGlobalVector("_wp", new Vector4(wp.x, wp.y, wp.z, 0f));

        Shader.SetGlobalVector("_xo", objectPos.position);

        print("Position: " + xp);
        print("Velocity: " + vp + "; magnitude: " + vp.magnitude);
    }
}
