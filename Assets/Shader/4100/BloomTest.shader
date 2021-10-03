Shader "HundredTalentsProgram/4100Bloom/BloomTest"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
        _Bloom ("Bloom(RGB)", 2D) = "black" {}                              // 模糊后的纹理
        _LuminanceThreshold("Luminance Threshold", Float) = 0.5             // 阈值
        _BlurSize("Blur Size", Float) = 1.0                                 // 模糊范围
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        uniform sampler2D_float _CameraDepthTexture;

        //------------------------------ 提取较亮部分 ----------------------
        struct v2fExtractBright{                                            // 顶点着色器输出结构体
          float4 pos : SV_POSITION;
          half2 uv : TEXCOORD;
        };

        v2fExtractBright vertExtractBright(appdata_img v){                  // 【顶点着色器】处理顶点位置到裁剪空间
            v2fExtractBright o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed luminance(fixed4 color){                                      // 计算颜色的亮度值
            return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
        }

        fixed4 fragExtractBright(v2fExtractBright i) : SV_Target{           // 【片元着色器】提起亮度值大于阈值的部分                
            fixed4 c = tex2D(_MainTex, i.uv);
            fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
            return c * val;                                                 // 小于阈值的部分被clamp到0了
        }

        //------------------------------ 模糊 ----------------------
        struct v2fBlur{
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD;
        };
        
        v2fBlur vertBlurVertical(appdata_img v){
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = o.uv[0] + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = o.uv[0] - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = o.uv[0] + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = o.uv[0] - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            return o;
        }

        v2fBlur vertBlurHorizontal(appdata_img v){
            v2fBlur o;
            o.pos = UnityObjectToClipPos(v.vertex);
            half2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = o.uv[0] + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = o.uv[0] - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = o.uv[0] + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = o.uv[0] - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            return o;
        }

        fixed4 fragBlur(v2fBlur i): SV_Target{
            float weight[3] = {0.4026, 0.2442, 0.0545}; 
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
            fixed sum1 = tex2D(_MainTex, i.uv[0]).a * weight[0];

            for(int it = 1; it < 3; it++){                                     // uv 12 34
                sum += tex2D(_MainTex, i.uv[2*it-1]).rgb * weight[it] ;
                sum += tex2D(_MainTex, i.uv[2*it]).rgb * weight[it] ;
                sum1 += tex2D(_MainTex, i.uv[2*it-1]).a * weight[it] ;
                sum1 += tex2D(_MainTex, i.uv[2*it]).a * weight[it] ;
            }

            //sum *= (1 - tex2D(_MainTex, i.uv[0]).a);                          // 结合Alpha控制泛光强度
            //sum *= tex2D(_MainTex, i.uv[0]).a;                              // 结合Alpha控制泛光强度
            return fixed4(sum,sum1);
            //return fixed4(tex2D(_MainTex, i.uv[0]).rgb, 1.0);
        }

        //------------------------------ 混合 ----------------------
        struct v2fBloom{
            float4 pos : SV_POSITION;
            half4 uv: TEXCOORD0;
        };


        v2fBloom vertBloom(appdata_img v){                                  // 【顶点着色器】处理pos和uv
            v2fBloom o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord;
            o.uv.zw = v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0.0){
                o.uv.w = 1.0 - o.uv.w;
            }
            #endif
            return o;
        }

        fixed4 fragBloom(v2fBloom i) : SV_Target{
            //return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw) * 10 * (1-clamp(tex2D(_MainTex, i.uv.xy).a,0,1));
            //return tex2D(_Bloom, i.uv.zw) * 10 * tex2D(_MainTex, i.uv.xy).a;
            //return tex2D(_MainTex, i.uv.xy);
            //return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw) * (1-clamp(tex2D(_MainTex, i.uv.xy).a,0,1));
            //return tex2D(_Bloom, i.uv.zw)*clamp(tex2D(_MainTex, i.uv.xy).a,0,1);
            float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv.xy));
            depth = Linear01Depth(depth) * 10.0f;
            //return depth;
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw) * (1-clamp(tex2D(_MainTex, i.uv.xy).a,0,1));
        }

        ENDCG

        ZTest Always Cull off ZWrite off
        Pass {
            CGPROGRAM
            #pragma vertex vertExtractBright
            #pragma fragment fragExtractBright
            ENDCG
        }

        Pass {
            CGPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDCG
        }

        Pass {
            CGPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDCG
        }

        Pass {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
}
