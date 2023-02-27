// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "LeekRelativity/test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Amount("Extrusion Amount", Range(-1,1)) = 0.5
        _VLight("Speed of Light", Range(1,100)) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float4 _vPlayer = float4(0, 0, 0, 0);
            float4 _playerPos = float4(0, 0, 0, 0);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 col : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Amount;
            float _VLight;
            float _Beta;
            float4 _VParallel;
            float4 _VPerp;
            float4 _rel;

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // transform based on speed (ignoring any object moving for now)
                float4 relativeV = _vPlayer;
                _rel = relativeV;
                float speed = sqrt(pow((relativeV.x), 2) + pow((relativeV.y), 2) + pow((relativeV.z), 2));
                float4 velUnitVec = relativeV / speed;

                //float4 vertexPos = v.vertex;
                float4 vertexPos = mul(unity_ObjectToWorld, v.vertex);
                
                float4 relativePos = vertexPos - _playerPos;
                float dist = sqrt(pow((relativePos.x), 2) + pow((relativePos.y), 2) + pow((relativePos.z), 2));
                float4 relPosUnitVec = relativePos / dist;

                float4 VParallel = (relativeV.x * relPosUnitVec.x + relativeV.y * relPosUnitVec.y + relativeV.z * relPosUnitVec.z) * relPosUnitVec;
                float4 VPerpendicular = relativeV - VParallel;

                float VParallelSquared = VParallel.x * VParallel.x + VParallel.y * VParallel.y + VParallel.z * VParallel.z;
                float VLightSquared = _VLight * _VLight;

                _VParallel = VParallel;
                _VPerp = VPerpendicular;

                // hard cap it to 95% of speed of light
                VParallelSquared = min(VParallelSquared, VLightSquared * 0.95);
                float gamma = sqrt(1 - VParallelSquared / VLightSquared);

                //_Beta = sqrt(VParallelSquared / VLightSquared);

                ////v.vertex = _playerPos + relativePos * gamma;
                ///*v.vertex.x = _playerPos.x + (relativePos.x * 0.5);
                //v.vertex.y = _playerPos.y + (relativePos.y * 0.5);
                //v.vertex.z = _playerPos.z + (relativePos.z * 0.5);*/

                vertexPos.x = vertexPos.x - relativePos.x*(1 - gamma);
                vertexPos.y = vertexPos.y - relativePos.y*(1 - gamma);
                vertexPos.z = vertexPos.z - relativePos.z*(1 - gamma);

               /* v.vertex.x = vertX;
                v.vertex.y -= vertY * 0.5;
                v.vertex.z = vertZ;*/

                float4 vertexPosObject = mul(unity_WorldToObject, vertexPos);

                o.vertex = UnityObjectToClipPos(vertexPosObject);

        
                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // return tex2D(_MainTex, i.uv);
                float mag = sqrt(_vPlayer.x * _vPlayer.x + _vPlayer.y * _vPlayer.y + _vPlayer.z * _vPlayer.z);
                mag = min(mag, 0.01);
                return fixed4(_Beta, _Beta, _Beta, 1.0);
                //return fixed4(0.0, 0.0, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
