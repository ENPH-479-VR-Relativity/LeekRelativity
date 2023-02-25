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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float4 _vPlayer = float4(0, 0, 0, 0);
            float4 _playerPos = float4(0, 0, 0, 0);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
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

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // return tex2D(_MainTex, i.uv);
                float mag = sqrt(_vPlayer.x * _vPlayer.x + _vPlayer.y * _vPlayer.y + _vPlayer.z * _vPlayer.z);
                mag = min(mag, 0.01);
                return fixed4(_vPlayer.x / mag, _vPlayer.y / mag, _vPlayer.z / mag, 1.0);
                // return fixed4(0.0, 0.0, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
