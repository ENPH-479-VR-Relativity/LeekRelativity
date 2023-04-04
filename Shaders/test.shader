// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

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
            float4 _wp = float4(0, 0, 0, 0); // Player angular velocity
            float4 _vo = float4(0, 0, 0, 0); // Object velocity
            float4 _wo = float4(0, 0, 0, 0); // Object angular velocity
            float _vLight = 5.0; // Speed of light
			float _spaceDilationVLightScalar = 1.0; // Scalar for space dilation speed of light to enhance effects
			float _spotlightScalar = 1.0;
            float4 _vPlayer = float4(0, 0, 0, 0);
            float4 _playerPos = float4(0, 0, 0, 0);
			int _spatialDistEnabled = 0;
			int _spotlightEnabled = 0;
			int _dopplerEnabled = 0;
			float _maxBetaFactor = 0.99999;

            struct v2f
            {
                float4 xv : SV_POSITION; // Vertex position
                float2 uv : TEXCOORD0;
                float doppler : TEXCOORD1; // Doppler factor, player frame of reference.
                float lum : TEXCOORD2; //Luminance factor due to spotlight effect. 
				float4 color : COLOR0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
			sampler2D _IRTex;
			sampler2D _UVTex;
			sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
            float _Beta;

            v2f vert(appdata_full v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v); 
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.xv = UnityObjectToClipPos(v.vertex); 

				if (_dopplerEnabled || _spotlightEnabled) {
					float4 vertexPos = mul(unity_ObjectToWorld, v.vertex);

					float4 xvRelO = vertexPos; // Position of vertex relative to object.
					float4 xvRelP = vertexPos - _xp; // Position of vertex relative to player.

					float4 vvAngObj = float4(
						_wo.y * xvRelO.z - _wo.z * xvRelO.y,
						_wo.z * xvRelO.x - _wo.x * xvRelO.z,
						_wo.x * xvRelO.y - _wo.y * xvRelO.x,
						0
						); // Angular component of linear vertex velocity due to rotation of object.

					float4 vvAngPlr = float4(
						_wp.y * xvRelP.z - _wp.z * xvRelP.y,
						_wp.z * xvRelP.x - _wp.x * xvRelP.z,
						_wp.x * xvRelP.y - _wp.y * xvRelP.x,
						0
						); // Angular component of linear vertex velocity due to rotation of player.

					float4 vv = vvAngObj + _vo; // Velocity of vertex in the Player's view (stuff from angular velocity + linear velocity of object).

					float4 vvRelP = vv + vvAngPlr - _vp; // Velocity of vertex relative to player (adds effect of player's ang. velocity). 

					// vvRelP = -1 * _vp; // Debug

					float playerSpeed = sqrt(_vp.x * _vp.x + _vp.y + _vp.y + _vp.z + _vp.z); // Speed of the player.
					float vertexSpeed = sqrt(vv.x * vv.x + vv.y + vv.y + vv.z * vv.z); // Speed of the vertex.

					float vvRelPSpeed = sqrt(vvRelP.x * vvRelP.x + vvRelP.y * vvRelP.y + vvRelP.z * vvRelP.z); // Speed of the vertex relative to the player.
					float vvRelPDist = sqrt(xvRelP.x * xvRelP.x + xvRelP.y * xvRelP.y + xvRelP.z * xvRelP.z); // Distance of the vertex relative to the player.

					float xvDotVvRelP = vvRelP.x * xvRelP.x + vvRelP.y * xvRelP.y + vvRelP.z * xvRelP.z; // Dot product of vertex velocity and position, both rel. to player.
					float cosAngXvVvRelP = xvDotVvRelP / (vvRelPSpeed * vvRelPDist); // Cosine of the angle between the relative velocity of the vertex and the relative position of the vertex (both rel. to player).

					// float beta = (xvDotVvRelP > 0 ? 1 : -1) * vvRelPSpeed / _vLight; // Beta as in Lorentz factor formula
					float beta = vvRelPSpeed / _vLight; // Beta as in Lorentz factor formula
					
					float gamma = 1 / sqrt(1 - min(beta * beta, _maxBetaFactor)); // Lorentz factor

					float dopplerV = gamma * (1 + beta * cosAngXvVvRelP); // Doppler factor, vertex frame of reference.

					if (abs(dopplerV) < 0.00001) {
						dopplerV = 0.00001 * (dopplerV > 0 ? 1 : -1);
					}
					// o.doppler = vvRelPSpeed / 2;
					// o.doppler = vvRelPSpeed / 2;

					o.doppler = dopplerV;
					
					float lumRaw = -1 * max(min(pow(beta, 2) * cosAngXvVvRelP, 1.0f), -1.0f);
					o.lum = sign(lumRaw) * pow(abs(lumRaw), 1.0f / _spotlightScalar); // Multiplication factor of luminance due to spotlight effect. 

					// o.lum = cosAngXvVvRelP;
				}
                

                // spatial transform
				if (_spatialDistEnabled) {
					// transform based on speed (ignoring any object moving for now)
					float4 relativeV = _vPlayer;
					float speed = sqrt(pow((relativeV.x), 2) + pow((relativeV.y), 2) + pow((relativeV.z), 2));
					float4 velUnitVec = relativeV / speed;

					//float4 vertexPos = v.vertex;
					float4 vertexPos = mul(unity_ObjectToWorld, v.vertex);

					float4 relativePos = vertexPos - _xp;
					float dist = sqrt(pow((relativePos.x), 2) + pow((relativePos.y), 2) + pow((relativePos.z), 2));
					float4 relPosUnitVec = relativePos / dist;

					float4 VParallel = (relativeV.x * relPosUnitVec.x + relativeV.y * relPosUnitVec.y + relativeV.z * relPosUnitVec.z) * relPosUnitVec;
					float4 VPerpendicular = relativeV - VParallel;

					float VParallelSquared = (VParallel.x * VParallel.x + VParallel.y * VParallel.y + VParallel.z * VParallel.z) * _spaceDilationVLightScalar * _spaceDilationVLightScalar;
					float VLightSquared = _vLight * _vLight;

					// hard cap it to 99% of speed of light
					VParallelSquared = min(VParallelSquared, VLightSquared * 0.99);
					float gamma_ = sqrt(1 - VParallelSquared / VLightSquared);

					vertexPos.x = vertexPos.x - relativePos.x * (1 - gamma_);
					vertexPos.y = vertexPos.y - relativePos.y * (1 - gamma_);
					vertexPos.z = vertexPos.z - relativePos.z * (1 - gamma_);

					float4 vertexPosObject = mul(unity_WorldToObject, vertexPos);
					o.xv = UnityObjectToClipPos(vertexPosObject);

				}
				o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);

				o.color = v.color;

                return o;
            }

/*
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
*/

//----------------------------------------------------------------------------------------------------
// 
// 			              MIT Game Lab code for colour stuff
//
//----------------------------------------------------------------------------------------------------

			//Color shift variables, used to make guassians for XYZ curves
			#define xla 0.39952807612909519
			#define xlb 444.63156780935032
			#define xlc 20.095464678736523

			#define xha 1.1305579611401821
			#define xhb 593.23109262398259
			#define xhc 34.446036241271742

			#define ya 1.0098874822455657
			#define yb 556.03724875218927
			#define yc 46.184868454550838

			#define za 2.0648400466720593
			#define zb 448.45126344558236
			#define zc 22.357297606503543

			//Used to determine where to center UV/IR curves
			#define IR_RANGE 400
			#define IR_START 700
			#define UV_RANGE 380
			#define UV_START 0

			//Color functions, there's no check for division by 0 which may cause issues on
			//some graphics cards.
			float3 RGBToXYZC(float r, float g, float b)
			{
				float3 xyz;
				xyz.x = 0.13514 * r + 0.120432 * g + 0.057128 * b;
				xyz.y = 0.0668999 * r + 0.232706 * g + 0.0293946 * b;
				xyz.z = 0.0 * r + 0.0000218959 * g + 0.358278 * b;
				return xyz;
			}
			float3 XYZToRGBC(float x, float y, float z)
			{
				float3 rgb;
				rgb.x = 9.94845 * x - 5.1485 * y - 1.16389 * z;
				rgb.y = -2.86007 * x + 5.77745 * y - 0.0179627 * z;
				rgb.z = 0.000174791 * x - 0.000353084 * y + 2.79113 * z;

				return rgb;
			}
			float3 weightFromXYZCurves(float3 xyz)
			{
				float3 returnVal;
				returnVal.x = 0.0735806 * xyz.x - 0.0380793 * xyz.y - 0.00860837 * xyz.z;
				returnVal.y = -0.0665378 * xyz.x + 0.134408 * xyz.y - 0.000417865 * xyz.z;
				returnVal.z = 0.00000299624 * xyz.x - 0.00000605249 * xyz.y + 0.0484424 * xyz.z;
				return returnVal;
			}

			float getXFromCurve(float3 param, float shift)
			{
				float top1 = param.x * xla * exp((float)(-(pow((param.y * shift) - xlb, 2)
					/ (2 * (pow(param.z * shift, 2) + pow(xlc, 2)))))) * sqrt((float)(float(2) * (float)3.14159265358979323));
				float bottom1 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xlc, 2)));

				float top2 = param.x * xha * exp(float(-(pow((param.y * shift) - xhb, 2)
					/ (2 * (pow(param.z * shift, 2) + pow(xhc, 2)))))) * sqrt((float)(float(2) * (float)3.14159265358979323));
				float bottom2 = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(xhc, 2)));

				return (top1 / bottom1) + (top2 / bottom2);
			}
			float getYFromCurve(float3 param, float shift)
			{
				float top = param.x * ya * exp(float(-(pow((param.y * shift) - yb, 2)
					/ (2 * (pow(param.z * shift, 2) + pow(yc, 2)))))) * sqrt(float(float(2) * (float)3.14159265358979323));
				float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(yc, 2)));

				return top / bottom;
			}

			float getZFromCurve(float3 param, float shift)
			{
				float top = param.x * za * exp(float(-(pow((param.y * shift) - zb, 2)
					/ (2 * (pow(param.z * shift, 2) + pow(zc, 2)))))) * sqrt(float(float(2) * (float)3.14159265358979323));
				float bottom = sqrt((float)(1 / pow(param.z * shift, 2)) + (1 / pow(zc, 2)));

				return top / bottom;
			}

			float3 constrainRGB(float r, float g, float b)
			{
				float w;

				w = (0 < r) ? 0 : r;
				w = (w < g) ? w : g;
				w = (w < b) ? w : b;
				w = -w;

				if (w > 0) {
					r += w;  g += w; b += w;
				}
				w = r;
				w = (w < g) ? g : w;
				w = (w < b) ? b : w;

				if (w > 1)
				{
					r /= w;
					g /= w;
					b /= w;
				}
				float3 rgb;
				rgb.x = r;
				rgb.y = g;
				rgb.z = b;
				return rgb;

			};

			//Per pixel shader, does color modifications
			float4 frag(v2f i) : SV_Target
			{
				if (_dopplerEnabled || _spotlightEnabled) {
					// //Used to maintian a square scale ( adjust for screen aspect ratio )
					// float x1 = i.pos2.x * 2 * xs;
					// float y1 = i.pos2.y * 2 * xs / xyr;
					// float z1 = i.pos2.z;

					float shift = i.doppler;

					//Get initial color 
					float4 data = tex2D(_MainTex, i.uv).rgba;
					float UV = tex2D(_UVTex, i.uv).r;
					float IR = tex2D(_IRTex, i.uv).r;

					//Set alpha of drawing pixel to 0 if vertex shader has determined it should not be drawn.
					// data.a = i.draw ? data.a : 0;

					float3 rgb = data.xyz;


					//Color shift due to doppler, go from RGB -> XYZ, shift, then back to RGB.
					float3 xyz = RGBToXYZC(float(rgb.x), float(rgb.y), float(rgb.z));
					float3 weights = weightFromXYZCurves(xyz);
					float3 rParam, gParam, bParam, UVParam, IRParam;
					rParam.x = weights.x; rParam.y = (float)615; rParam.z = (float)8;
					gParam.x = weights.y; gParam.y = (float)550; gParam.z = (float)4;
					bParam.x = weights.z; bParam.y = (float)463; bParam.z = (float)5;
					UVParam.x = 0.02; UVParam.y = UV_START + UV_RANGE * UV; UVParam.z = (float)5;
					IRParam.x = 0.02; IRParam.y = IR_START + IR_RANGE * IR; IRParam.z = (float)5;

					float xf = pow((1 / shift), 3) * (getXFromCurve(rParam, shift) + getXFromCurve(gParam, shift) + getXFromCurve(bParam, shift) + getXFromCurve(IRParam, shift) + getXFromCurve(UVParam, shift));
					float yf = pow((1 / shift), 3) * (getYFromCurve(rParam, shift) + getYFromCurve(gParam, shift) + getYFromCurve(bParam, shift) + getYFromCurve(IRParam, shift) + getYFromCurve(UVParam, shift));
					float zf = pow((1 / shift), 3) * (getZFromCurve(rParam, shift) + getZFromCurve(gParam, shift) + getZFromCurve(bParam, shift) + getZFromCurve(IRParam, shift) + getZFromCurve(UVParam, shift));

					float3 rgbColourShifted = XYZToRGBC(xf, yf, zf);
					if (!_dopplerEnabled) {
						rgbColourShifted = rgb;
					}

					float lumScalar = i.lum;

					if (!_spotlightEnabled) {
						lumScalar = 0;
					}

					float3 rgbFinal = float3(
						rgbColourShifted.x + (1 - rgbColourShifted.x) * lumScalar,
						rgbColourShifted.y + (1 - rgbColourShifted.y) * lumScalar,
						rgbColourShifted.z + (1 - rgbColourShifted.z) * lumScalar
					);

					rgbFinal = float3(
						rgbFinal.x > 1 ? 1 : rgbFinal.x,
						rgbFinal.y > 1 ? 1 : rgbFinal.y,
						rgbFinal.z > 1 ? 1 : rgbFinal.z
					);

					rgbFinal = float3(
						rgbFinal.x < 0 ? 0 : rgbFinal.x,
						rgbFinal.y < 0 ? 0 : rgbFinal.y,
						rgbFinal.z < 0 ? 0 : rgbFinal.z
					);
					

					// rgbFinal = constrainRGB(rgbFinal.x, rgbFinal.y, rgbFinal.z); //might not be needed

					// return float4((float)abs(i.lum), (float)max(i.lum, 0), (float)max(-1 * i.lum, 0), data.a);
					// return float4((float)i.lum, (float)i.lum, (float)i.lum, data.a);

					//Test if unity_Scale is correct, unity occasionally does not give us the correct scale and you will see strange things in vertices,  this is just easy way to test
					//float4x4 temp  = mul(unity_Scale.w*_Object2World, _World2Object);
					//float4 temp2 = mul( temp,float4( (float)rgbFinal.x,(float)rgbFinal.y,(float)rgbFinal.z,data.a));
					//return temp2;	
					//float4 temp2 =float4( (float)rgbFinal.x,(float)rgbFinal.y,(float)rgbFinal.z,data.a );

					// float4 _xp = mul(unity_ObjectToWorld, _xp);
					// return float4((float)i.xv.x - _xp.x, (float)i.xv.y - _xp.y, (float)i.xv.z - _xp.z, data.a);

					return float4((float)rgbFinal.x, (float)rgbFinal.y, (float)rgbFinal.z, data.a); //use me for any real build
				}
				else {
					// For only spatial distortion enabled
					float4 data = tex2D(_MainTex, i.uv).rgba;
					float3 rgb = data.xyz;

					float3 rgbColourShifted = rgb;
					float lumScalar = 0;

					float3 rgbFinal = float3(
						rgbColourShifted.x + (1 - rgbColourShifted.x) * lumScalar,
						rgbColourShifted.y + (1 - rgbColourShifted.y) * lumScalar,
						rgbColourShifted.z + (1 - rgbColourShifted.z) * lumScalar
						);

					rgbFinal = float3(
						rgbFinal.x > 1 ? 1 : rgbFinal.x,
						rgbFinal.y > 1 ? 1 : rgbFinal.y,
						rgbFinal.z > 1 ? 1 : rgbFinal.z
						);

					rgbFinal = float3(
						rgbFinal.x < 0 ? 0 : rgbFinal.x,
						rgbFinal.y < 0 ? 0 : rgbFinal.y,
						rgbFinal.z < 0 ? 0 : rgbFinal.z
						);

					return float4((float)rgbFinal.x, (float)rgbFinal.y, (float)rgbFinal.z, data.a);
				}
			}
            ENDCG
        }
    }
}
