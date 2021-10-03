// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HundredTalentsProgram/4300/ShadowMapShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

        
            // sampler2D unity_Lightmap;//若开启光照贴图，系统默认填值
            // float4 unity_LightmapST;//与上unity_Lightmap同理

            struct v2f {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                float2 uv2:TEXCOORD1;
                UNITY_FOG_COORDS(2)
                float4 proj : TEXCOORD3;
                float2 depth : TEXCOORD4;
            };


            float4x4 ProjectionMatrix;
            float4x4 _LightProjection;
            sampler2D DepthTexture;

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //动态阴影
                o.depth = o.pos.zw;
                ProjectionMatrix = mul(ProjectionMatrix, unity_ObjectToWorld);
                o.proj = mul(ProjectionMatrix, v.vertex);
                //--------------------------------------------------
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv2 = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                UNITY_TRANSFER_FOG(o, o.pos);

                return o;
            }

            fixed4 frag(v2f v) : COLOR
            {
                //解密光照贴图计算公式
                //float3 lightmapColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,v.uv2));
                fixed4 col = tex2D(_MainTex, v.uv);
                //return fixed4(1.0, 1.0, 1.0, 1.0);
                //return col;
                //col.rgb *= lightmapColor;
                //return col;
                UNITY_APPLY_FOG(v.fogCoord, col);

                float depth = v.depth.x / v.depth.y;
                fixed4 dcol = tex2Dproj(DepthTexture, v.proj);
                float d = DecodeFloatRGBA(dcol);
                float shadowScale = 1;
                if(depth > d)
                {
                    shadowScale = 0.55;
                }
                //return col*shadowScale;
                //return fixed4(1.0, 1.0, 1.0, 1.0)*shadowScale;
                float tt = 0.1;
                //return fixed4(depth*tt, depth*tt, depth*tt, depth*tt);
                return fixed4(d*tt, d*tt, d*tt, d*tt);


                //计算NDC坐标
                fixed4 ndcpos = mul(_LightProjection , v.pos);
                ndcpos.xyz = ndcpos.xyz / ndcpos.w ;
                //从[-1,1]转换到[0,1]
                float3 uvpos = ndcpos * 0.5 + 0.5 ;
                depth = DecodeFloatRGBA(tex2D(DepthTexture, uvpos.xy));
                return fixed4(depth*tt, depth*tt, depth*tt, depth*tt);
                if(ndcpos.z < depth  ){return 1;}
                else{return 0;}

            }
            ENDCG
        }
    }
    //Fallback Off
}
