/**
 * Grab player and object spatial parameters and the speed of light, pass along to shader.
 */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RelativityProperties : MonoBehaviour
{
    private GlobalProperties globalProperties;
    // public Transform objectPos;

    public Vector3 xp { get; set; } = Vector3.zero;
    public Vector3 vp { get; set; } = Vector3.zero;
    public Vector3 wp { get; set; } = Vector3.zero;

    void Start()
    {
        globalProperties = FindObjectOfType<GlobalProperties>();

        Shader.SetGlobalFloat("_vLight", globalProperties.LightSpeed);
        Shader.SetGlobalFloat("_spaceDilationVLightScalar", globalProperties.SpaceScalar);
        Shader.SetGlobalFloat("_spotlightScalar", globalProperties.SpotlightScalar);
        print(globalProperties);
        // objectPos = GetComponent<Transform>();

        Shader.SetGlobalInteger("_spatialDistEnabled", globalProperties.IsSpatialDistortionEnabled ? 1 : 0);
        Shader.SetGlobalInteger("_spotlightEnabled", globalProperties.IsSpotlightEnabled ? 1 : 0);
        Shader.SetGlobalInteger("_dopplerEnabled", globalProperties.IsDopplerEnabled ? 1 : 0);
    }

    // Update is called once per frame
    void Update()
    {
        if (globalProperties == null) return;
        xp = globalProperties.Position;
        vp = globalProperties.Velocity;
        wp = globalProperties.AngularVelocity;

        Shader.SetGlobalVector("_xp", new Vector4(xp.x, xp.y, xp.z, 0f));
        Shader.SetGlobalVector("_vp", new Vector4(vp.x, vp.y, vp.z, 0f));

        // same things different name to account for different naming in shaders between doppler and spatial distortion
        Shader.SetGlobalVector("_playerPos", new Vector4(xp.x, xp.y, xp.z, 0f));
        Shader.SetGlobalVector("_vPlayer", new Vector4(vp.x, vp.y, vp.z, 0f));
        Shader.SetGlobalVector("_wp", new Vector4(wp.x, wp.y, wp.z, 0f));

        // Update which effects are enabled
        // convert to integers because shaders do not support bools

        Shader.SetGlobalInteger("_spatialDistEnabled", globalProperties.IsSpatialDistortionEnabled ? 1 : 0);
        Shader.SetGlobalInteger("_spotlightEnabled", globalProperties.IsSpotlightEnabled ? 1 : 0);
        Shader.SetGlobalInteger("_dopplerEnabled", globalProperties.IsDopplerEnabled ? 1 : 0);

        Shader.SetGlobalFloat("_vLight", globalProperties.LightSpeed);
        Shader.SetGlobalFloat("_spaceDilationVLightScalar", globalProperties.SpaceScalar);
        Shader.SetGlobalFloat("_spotlightScalar", globalProperties.SpotlightScalar);
    }
}
