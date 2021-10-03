Shader "HundredTalentsProgram/3300TSandGs/GrassShader"
{
    Properties
    {
        [Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)                      // 顶部颜色
        _BottomColor("Bottom Color", Color) = (1,1,1,1)                // 底部颜色
        _TranslucentGain("Translucent Gain", Range(0,1)) = 0.5         // 
        _BladeWidth("Blade Width", Float) = 0.05                       // 
        _BladeWidthRandom("Blade Width Random", Float) = 0.02          // 
        _BladeHeight("Blade Height", Float) = 0.5                      // 
        _BladeHeightRandom("Blade Height Random", Float) = 0.3         //     
    }
    SubShader
    {
        Cull Off

        Pass {

            Tags {
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma vertex vert                                         // 顶点shader
            #pragma geometry geo                                        // 几何shader
            #pragma fragment frag                                       // 像素shader

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "Autolight.cginc"                                  // 

            #pragma target 4.6

            float4 _TopColor;                                           // 
            float4 _BottomColor;                                        // 
            float _TranslucentGain;                                     //
            

            float rand(float3 co){
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
            }

            float3x3 AngleAxis3x3(float angle, float3 axis){
                float c, s;
                sincos(angle, s, c);
                
                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                );
            }

            float _BladeWidth;                                          // 
            float _BladeWidthRandom;                                    // 
            float _BladeHeight;                                         //
            float _BladeHeightRandom;                                   //

            struct vertexInput{                                         // 顶点输入结构体
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct vertexOutput{                                        // 顶点输出结构体
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            //----------------------------------------------------------// 顶点着色器 -------------------------------------------------------------------
            vertexOutput vert (vertexInput v){                          
                vertexOutput o;

                o.vertex = v.vertex;
                o.normal = v.normal;
                o.tangent = v.tangent;

                return o;
            }

            //----------------------------------------------------------// 几何着色器 --------------------------------------------------------------------
            struct geometryOutput{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            geometryOutput CreateGeoOutput(float3 pos, float2 uv){      // 空间转换
                geometryOutput o;
                o.pos = UnityObjectToClipPos(pos);
                o.uv = uv;
                return o;
            }

            [maxvertexcount(3)]                                         // 定义最大输出点
            void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream){
                                                                        // 输入 三角形 输出 三角形（每个点用到了结构体）
                float3 pos = IN[0].vertex;
                float3 vNormal = IN[0].normal;
                float4 vTangent = IN[0].tangent;
                float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

                float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
                float width = (rand(pos.zyx) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
                                                                        // 旋转矩阵和空间转换矩阵 共同构成了变化矩阵
                float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
                float3x3 tangentToLocal = float3x3(
                    vTangent.x, vBinormal.x, vNormal.x,
                    vTangent.y, vBinormal.y, vNormal.y,
                    vTangent.z, vBinormal.z, vNormal.z
                );
                float3x3 transformationMat = mul(tangentToLocal, facingRotationMatrix);

                geometryOutput o;
                                                                        // 依次装入3个点
                triStream.Append(CreateGeoOutput(pos + mul(transformationMat, float3(width, 0 , 0)), float2(0, 0)));
                triStream.Append(CreateGeoOutput(pos + mul(transformationMat, float3(-width, 0 , 0)), float2(1, 0)));
                triStream.Append(CreateGeoOutput(pos + mul(transformationMat, float3(0, 0 , height)), float2(0.5, 1)));

            }


            //----------------------------------------------------------// 像素着色器 -------------------------------------------------------------------
            float4 frag (geometryOutput i, fixed facing : VFACE) : SV_Target{
                return lerp(_BottomColor, _TopColor, i.uv.y);
            }
            ENDCG
        }                  
    }
    FallBack "Diffuse"
}
