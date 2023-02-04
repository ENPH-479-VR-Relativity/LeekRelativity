// Adapted from https://github.com/MITGameLab/OpenRelativity

Shader "Relativity/ColourShift"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "" {}
        _UVTex("UV",2D) = "" {} //UV texture
        _IRTex("IR",2D) = "" {} //IR texture
        _vInWorld("vInWorld", Vector) = (0,0,0,0) //Vector that represents object's velocity in world frame
        _Cutoff("Base Alpha cutoff", Range(0,.9)) = 0.1 //Used to determine when not to render alpha materials
    }

    CGINCLUDE
    // Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members pos2,uv1,svc,vr,draw)
    #pragma exclude_renderers d3d11 xbox360
    // Upgrade NOTE: excluded shader from Xbox360; has structs without semantics (struct v2f members pos2,uv1,svc,vr)	
    // Not sure when this^ got added, seems like unity did it automatically some update?
    #pragma exclude_renderers xbox360
    #pragma glsl
    #include "UnityCG.cginc"

    struct vertexFragmentData
    {
        float4 pos : POSITION;
        float4 posAbs : TEXCOORD0;
        float4 uv1 : TEXCOORD1;
        float gamma: TEXCOORD2;
        float4 vRel : TEXCOORD3;
        float toDraw : TEXCOORD4; 
    };

    sampler2D _MainTex;
    sampler2D _IRTex;
    sampler2D _UVTex;
    sampler2D _CameraDepthTexture;

    float4 _vInWorld = float4(0, 0, 0, 0);
    float4 _vPlayer = float4(0, 0, 0, 0);
    float4 _playerPos = float4(0, 0, 0, 0);
    float _vLight = 100;
    float _worldTime = 0;
    float _startTime = 0;
    float _useColorShift = 1;

    float xyRatio = 1;
    float xScale = 1;

    uniform float4 _MainTex_TexelSize;
    uniform float4 _CameraDepthTexture_ST;

    vertexFragmentData vert(appdata_img vertexData)
    {
        vertexFragmentData output;

        output.pos = mul(unity_ObjectToWorld, vertexData.vertex);
        output.pos -= _playerOffset;

        output.uv1.xy = vertexData.texcoord;

        float speed = sqrt(pow((_vPlayer.x), 2) + pow((_vPlayer.y), 2) + pow((_vPlayer.z), 2));

        float vPlayerDotUObject = (_vInWorld.x * _vPlayer.x + _vInWorld.y * _vPlayer.y + _vInWorld.z * _vPlayer.z);

        float4 uParallel = (vPlayerDotUObject / (speed * speed)) * _vPlayer;
        uParallel = !(isnan(uParallel) || isinf(uParallel)) ? uParallel : 0;

        float4 uPerp = _vPlayer - uParallel;
        float4 vRelative = (_vPlayer - uParallel - (sqrt(1 - speed * speed)) * uPerp) / (1 + vPlayerDotUObject);

        output.vRel = vRelative;
        vRelative *= -1;

        float speedRelative = sqrt(pow(vRelative.x, 2) + pow(vRelative.y, 2) + pow(vRelative.z, 2));
        output.gamma = sqrt(1 - speedRelative * speedRelative);

        #ifdef SHADER_API_D3D9
        if (_MainTex_TexelSize.y < 0)
            o.uv1.y = 1.0 - o.uv1.y;
        #endif

        float4 refLocationInWorld = output.pos;

        if (speedRelative != 0)
        {
            float angle;
            float uObjectX;
            float uObjectY;
            float sinAngle;
            float cosAngle;
            if (speed != 0) {
                // Get the angle between the object z direction and the world z axis
                angle = -acos(-_vPlayer.z / speed);
                if (_vPlayer.x != 0 || _vPlayer.y != 0) {
                    uObjectX = _vPlayer.y / sqrt(_vPlayer.x * _vPlayer.x + _vPlayer.y * _vPlayer.y);
                    uObjectY = _vPlayer.x / sqrt(_vPlayer.x * _vPlayer.x + _vPlayer.y * _vPlayer.y);
                }
                else {
                    uObjectX = 0;
                    uObjectY = 0;
                }

                cosAngle = cos(angle);
                sinAngle = sin(angle);

                // Rotate player velocity to all z; equations concern movement in one direction
                // NOTE: will be deprecated when we account for arbitrarily moving objects
                refLocationInWorld.x = output.pos.x * (cosAngle + uObjectX * uObjectX * (1 - cosAngle))
                    + output.pos.y * (uObjectX * uObjectY * (1 - cosAngle))
                    + output.pos.z * (uObjectY * sinAngle);
                refLocationInWorld.y = output.pos.x * (uObjectY * uObjectX * (1 - cosAngle))
                    + output.pos.y * (cosAngle + uObjectY * uObjectY * (1 - cosAngle))
                    + output.pos.z * (uObjectX * sinAngle);
                refLocationInWorld.z = output.pos.x * (uObjectY * sinAngle)
                    + output.pos.y * (uObjectX * sinAngle)
                    + output.pos.z * (cosAngle);
            }

            // Rotate velocity
            float4 rotatedVInWorld = float4(0, 0, 0, 0);
            if (speed != 0) {
                rotatedVInWorld.x = (_vInWorld.x * (cosAngle + uObjectX * uObjectX * (1 - cosAngle))
                    + _vInWorld.y * (uObjectX * uObjectY * (1 - cosAngle))
                    + _vInWorld.z * (uObjectY * sinAngle)) * _vLight;
            }
            else {
                rotatedVInWorld.x = (_vInWorld.x) * _vLight;
                rotatedVInWorld.y = (_vInWorld.y) * _vLight;
                rotatedVInWorld.z = (_vInWorld.z) * _vLight;
            }

            float posSquareNorm = refLocationInWorld.x * refLocationInWorld.x + refLocationInWorld.y * refLocationInWorld.y + refLocationInWorld.z * refLocationInWorld.z;

            float posDotRotatedV = refLocationInWorld.x * rotatedVInWorld.x + refLocationInWorld.y * rotatedVInWorld.y + refLocationInWorld.z * rotatedVInWorld.z;

            float squareLightVDifference = _vLight * _vLight - (rotatedVInWorld.x * rotatedVInWorld.x + rotatedVInWorld.y * rotatedVInWorld.y + rotatedVInWorld.z * rotatedVInWorld.z);

            // Unsure what the resulting quantity is here - it's a root of the polynomial:
            // 
            //      squareLightVDifference * t^2 + posDotRotatedV * t - posSquareNorm = 0
            // 
            // As for what that is, I presently have no idea
            // UPDATE - t is indeed time, and so my supposition is that this formula
            // is a relativistic approximation of a spatial movement taylor series of order 2.
            // Since I've provided these notes and this is all very likely to change under 
            // the arbitrary movement paradigm, I won't be careful about renaming this variable.
            float tisw = (float)(2 * posDotRotatedV - sqrt(((float)float(4)) * posDotRotatedV * posDotRotatedV - ((float)float(-4)) * posSquareNorm * squareLightVDifference)) / (((float)float(2)) * squareLightVDifference);

            // Check to make sure that objects that have velocity do not appear before they were created (Moving Person objects behind Sender objects) 
            if (_worldTime + tisw > _startTime || _startTime == 0) {
                output.toDraw = 1;
            }
            else {
                output.toDraw = 0;
            }

            // get the new position offset, based on the new time we just found
            // Should only be in the Z direction
            refLocationInWorld.x += rotatedVInWorld.x * tisw;
            refLocationInWorld.y += rotatedVInWorld.y * tisw;
            refLocationInWorld.z += rotatedVInWorld.z * tisw;

            // Apply Lorentz Transform
            float newZ = (((float)speed * _vLight) * tisw);

            newZ = refLocationInWorld.z + newZ;
            newZ /= (float)sqrt(1 - (speed * speed));
            refLocationInWorld.z = newZ;

            if (speed != 0) {
                float refLocationInWorldXStored = refLocationInWorld.x;
                float refLocationInWorldYStored = refLocationInWorld.y;

                refLocationInWorld.x = refLocationInWorld.x * (cosAngle + uObjectX * uObjectX * (1 - cosAngle))
                    + refLocationInWorld.y * (uObjectX * uObjectY * (1 - cosAngle))
                    - refLocationInWorld.z * (uObjectY * sinAngle);
                refLocationInWorld.y = refLocationInWorldXStored * (uObjectY * uObjectX * (1 - cosAngle))
                    + refLocationInWorld.y * (cosAngle + uObjectY * uObjectY * (1 - cosAngle))
                    + refLocationInWorld.z * (uObjectX * sinAngle);
                refLocationInWorld.z = refLocationInWorldXStored * (uObjectY * sinAngle)
                    - refLocationInWorldYStored * (uObjectX * sinAngle)
                    + refLocationInWorld.z * (cosAngle);
            }
        }
        else {
            output.toDraw = 1;
        }

        refLocationInWorld += _playerOffset;

        // Transform the vertex back in to local space for the mesh to use it.

        output.pos = mul(unity_WorldToObject * 1.0, refLocationInWorld);

        output.pos2 = mul(unity_ObjectToWorld, object.pos);
        output.pos2 -= _playerOffset;

        output.pos = UnityObjectToClipPos(output.pos);

        return output;
    }

    // Colour shaders stuff goes here

    ENDCG

    SubShader
    {
        Blend One Zero

        Pass
        {
            Cull Off ZWrite On
            ZTest LEqual
            Fog { Mode off }
            Tags {"RenderType"="Transparent" "Queue"="Transparent"}

            AlphaTest Greater [_Cutoff]
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma fragmentoption ARB_precision_hint_nicest

            #pragma vertex vert
            #pragma fragment frag
                #pragma target 3.0

            ENDCG
        }
    }
}