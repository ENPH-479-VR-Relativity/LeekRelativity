Shader "LeekRelativity/test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma enable_d3d11_debug_symbols

            float4 _vp = float4(0, 0, 0, 0); // Player velocity
            float4 _xp = float4(0, 0, 0, 0); // Player position
            float4 _vo = float4(0, 0, 0, 0); // Object velocity
            float4 _xo = float4(0, 0, 0, 0); // Object position
            float4 _wo = float4(0, 0, 0, 0); // Object angular velocity
            float _vLight = (float)5.0;

            struct v2f
            {
                float4 xv : SV_POSITION; // Vertex position
                float2 uv : TEXCOORD0;
                float doppler : TEXCOORD1; // Doppler factor, player frame of reference.
                float irrad : TEXCOORD2; // Irradiance factor due to spotlight effect. 
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); 
                o.xv = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);

                float4 xvRelO = v.vertex - _vo; // Position of vertex relative to object.

                float4 vvAngular = float4(
                        _wo.y * xvRelO.z - _wo.z * xvRelO.y,
                        _wo.z * xvRelO.x - _wo.x * xvRelO.z,
                        _wo.x * xvRelO.y - _wo.y * xvRelO.x,
                        0
                    ); // Angular component of linear vertex velocity. Due to rotation of object.
                float4 vv = vvAngular + _vo; // Velocity of vertex (stuff from angular velocity + linear velocity of object).

                float4 vvRelP = vv - _vp; // Velocity of vertex relative to player. 
                float4 xvRelP = v.vertex - _xp; // Position of vertex relative to player.

                float playerSpeed = sqrt(_vp.x * _vp.x + _vp.y + _vp.y + _vp.z + _vp.z); // Speed of the player.
                float vertexSpeed = sqrt(vv.x * vv.x + vv.y + vv.y + vv.z * vv.z); // Speed of the vertex.

                float vRelPSpeed = sqrt(vvRelP.x * vvRelP.x + vvRelP.y * vvRelP.y + vvRelP.z * vvRelP.z); // Speed of the vertex relative to the player.
                float vRelPDist = sqrt(xvRelP.x * xvRelP.x + xvRelP.y * xvRelP.y + xvRelP.z * xvRelP.z); // Distance of the vertex relative to the player.

                float xvDotVvRelP = vvRelP.x * xvRelP.x + vvRelP.y * xvRelP.y + vvRelP.z * xvRelP.z; // Dot product of vertex velocity and position, both rel. to player.
                float cosAngXvVvRelP = xvDotVvRelP / (vRelPSpeed * vRelPDist); // Cosine of the angle between the relative velocity of the vertex and the relative position of the vertex (both rel. to player).

                float beta = vRelPSpeed / 1.5; // Beta as in Lorentz factor formula
                float gamma = 1 / sqrt(1 - min(beta * beta, 0.99999)); // Lorentz factor

                o.doppler = max(abs(1 / (gamma * (1 + beta * cosAngXvVvRelP))), 0.00001); // Doppler factor, player frame of reference.
                float dopplerV = gamma * (1 - beta * cosAngXvVvRelP); // Doppler factor, vertex frame of reference.
                
                // o.doppler = vRelPSpeed / 2;
                // o.doppler = vRelPSpeed / 2;

                o.irrad = 1 / (pow(dopplerV, 5) * vRelPDist / dopplerV); // Multiplication factor of irradiance due to spotlight effect. 

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // return tex2D(_MainTex, i.uv);
                // return fixed4(0.0, 0.0, 0.0, 1.0);


                // float mag = sqrt(_vp.x * _vp.x + _vp.y * _vp.y + _vp.z * _vp.z);
                // mag = min(mag, 0.01);

                // return fixed4(_vp.x / mag, _vp.y / mag, _vp.z / mag, 1.0);

                
                fixed4 refColour = fixed4(0.7, 0.3, 0.2, 1);
                float4 colour = fixed4(refColour.x * i.doppler, refColour.y, refColour.z * (1 / i.doppler), 1);
                // fixed4 colour = fixed4(colourDoppler.x * i.irrad, colourDoppler.y * i.irrad, colourDoppler.z * i.irrad, 1);

                // float colourMag = min(sqrt(colour.x * colour.x + colour.y * colour.y + colour.z * colour.z), 0.01);
                float colourMag = max(abs(colour.x), max(abs(colour.y), abs(colour.z)));

                fixed4 colorNorm = fixed4(
                    refColour.x / 2 + (colour.x / colourMag) / 2,
                    refColour.y / 2 + (colour.y / colourMag) / 2,
                    refColour.z / 2 + (colour.z / colourMag) / 2,
                    1
                );

                return colorNorm;
            }
            ENDCG
        }
    }
}
