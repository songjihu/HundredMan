Shader "HundredTalentsProgram/3300TSandGs/TessShader"
{
    Properties
    {
        _TessellationUniform("Tessellation Uniform", Range(1,64)) = 1   // 曲面细分的范围 1 - 64
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass {
            LOD 200
            Name "FORWARD"
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma hull hullProgram                                    // 定义2个函数 hullshader domainshader
            #pragma domain ds
            #pragma vertex tessvert                                     // 顶点shader
            #pragma fragment frag                                       // 像素shader

            #include "UnityCG.cginc"
            #include "Tessellation.cginc"                               // Unity提供的曲面细分头文件 

            #pragma target 5.0

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct VertexInput{                                         // 顶点输入结构体
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD;
            };

            struct VertexOutput{                                        // 顶点输出结构体
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD;
            };

            VertexOutput vert (VertexInput v){                          // 空间转换函数，在Domain Shader中
                VertexOutput o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = UnityObjectToClipPos(v.vertex);              // 从对象空间到裁剪空间
                o.normal = v.normal;
                o.tangent = v.tangent;

                return o;
            }

            #ifdef UNITY_CAN_COMPILE_TESSELLATION                       // 宏定义 确保曲面着色器被平台支持再运行
                struct TessVertex {                                     // 顶点着色器结构体定义
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };

                struct OutputPatchConstant {                            // 不同的图元对应不同的结构体，在Hull Shader中
                    float edge[3] : SV_TESSFACTOR;
                    float inside : SV_INSIDETESSFACTOR;
                };

                TessVertex tessvert (VertexInput v){                    // 将顶点信息传入曲面细分着色器中
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                //------------------------------------hull shader部分------------------------------------------------
                float _TessellationUniform;
                OutputPatchConstant hsconst (InputPatch<TessVertex, 3> patch){
                    OutputPatchConstant o;                              //曲面细分的参数设置函数
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside = _TessellationUniform;
                    return o;
                }

                [UNITY_domain("tri")]                                   // 设置图元类型为三角形（triangel quad）
                [UNITY_partitioning("fractional_odd")]                  // 设置拆分edge方式（equal_spacing fractional_odd fractional_even）
                [UNITY_outputtopology("triangle_cw")]                   // 设置输出三角形的顶点顺序（顺时针 逆时针）
                [UNITY_patchconstantfunc("hsconst")]                    // 设置patch中3个点共用的曲面细分的参数设置函数
                [UNITY_outputcontrolpoints(3)]                          // 设置控制点的数量3，对应三角形图元
                
                TessVertex hullProgram (InputPatch<TessVertex, 3> patch, uint id : SV_OutputControlPointID){
                    return patch[id];                                   // 返回控制点ID对应的Patch
                }


                //------------------------------------domain shader部分------------------------------------------------
                [UNITY_domain("tri")]

                VertexOutput ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex, 3> patch, float3 bary : SV_DomainLocation){
                    VertexInput v;                                      // 从重心坐标空间转换到模型空间
                    v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
                    v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
                    v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
                    v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
                    VertexOutput o = vert(v);
                    return o;
                }
            #endif

                float4 frag (VertexOutput i) : SV_Target{
                    return float4(1.0,1.0,1.0,1.0);
                }
            ENDCG
        }                  
    }
    FallBack "Diffuse"
}
