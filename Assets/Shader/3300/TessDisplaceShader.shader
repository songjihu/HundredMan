Shader "HundredTalentsProgram/3300TSandGs/TessDisplaceShader"
{
    Properties
    {
        _TessellationUniform("Tessellation Uniform", Range(1,64)) = 1       // 曲面细分的范围 1 - 64
        _DisplacementStrength("Parallax Strength", Range(0,1)) = 0          // 替换强度
        _Smoothness("Smoothness", Range(0,1)) = 0                           // 高光的光滑度
        _MainTex ("Albedo (RGB)", 2D) = "white" {}                          // Albedo
        _DisplacementMap ("Displacement Map", 2D) = "white" {}              // 置换贴图（对应uv处需要被置换的强度）
        _DisplacementNormalMap ("Displacement Normal Map", 2D) = "white" {} // 法线贴图

        
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

            //#include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "Tessellation.cginc"                               // Unity提供的曲面细分头文件 

            #pragma target 5.0

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DisplacementMap;                                 // 置换贴图
            sampler2D _DisplacementNormalMap;                           // 法线贴图
            float _DisplacementStrength;                                // 替换的强度
            float _Smoothness;                                          // 光滑度

            struct VertexInput{                                         // 顶点输入结构体
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD;
            };

            struct VertexOutput{                                        // 顶点输出结构体
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD;

                half3 tspace0 : TEXCOORD2;                              // 转换矩阵，从切线空间到世界空间
                half3 tspace1 : TEXCOORD3;
                half3 tspace2 : TEXCOORD4;

            };

            //----------------------------------------------------------// 顶点变换部分------------------------------------------------------------------
            VertexOutput vert (VertexInput v){                          // 空间转换函数，在Domain Shader中
                VertexOutput o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                                                                        // displacement
                                                                        // 获取displacement的值0-1
                                                                        // 原作者注：有余并不是在Fragment shader中读取图片，GPU无法获取mipmap信息
                                                                        // 因此需要使用tex2Dlod来读取图片，使用第四个坐标作为mipmap的level，这里取了0
                float4 displacement = tex2Dlod(_DisplacementMap, float4(o.uv.xy, 0.0, 0.0)).g;
                displacement = (displacement - 0.5) * _DisplacementStrength;
                v.normal = normalize(v.normal);
                v.vertex.xyz += v.normal * displacement;                // 顶点沿着法线方向变化

                o.pos = UnityObjectToClipPos(v.vertex);                 // 从对象空间到裁剪空间 顶点
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);        // 从对象空间到世界空间 顶点

                                                                        //
                half3 wNormal = UnityObjectToWorldNormal(v.normal);     // 从对象空间到世界空间 法线
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);  // 从对象空间到世界空间 切线

                                                                        // 通过叉乘计算次切线方向（先计算符号/朝向）
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
                                                                        // 将上述结果组成切线空间的矩阵（由于上边顶点沿着法线方向进行变换后，
                                                                        // 需要保存变化后的切线空间信息到转换矩阵中，用来变换法线贴图到世界空间）
                o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

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

                //------------------------------------------------------// hull shader部分--------------------------------------------------------------
                float _TessellationUniform;
                OutputPatchConstant hsconst (InputPatch<TessVertex, 3> patch){
                    OutputPatchConstant o;                              // 曲面细分的参数设置函数
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


                //------------------------------------------------------// domain shader部分------------------------------------------------------------
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


                //------------------------------------------------------// fragment shader部分 -------------------------------------------------------
                float4 frag (VertexOutput i) : SV_Target{
                    float3 lightDir = _WorldSpaceLightPos0.xyz;         // 光源位置（世界空间）和法线（切线空间）
                    float3 tnormal = UnpackNormal(tex2D(_DisplacementNormalMap, i.uv));
                    half3 worldNormal;
                    worldNormal.x = dot(i.tspace0, tnormal);            // 通过上边的矩阵将法线转换回世界空间
                    worldNormal.y = dot(i.tspace1, tnormal);
                    worldNormal.z = dot(i.tspace2, tnormal);

                    float3 albedo = tex2D(_MainTex, i.uv).rgb;          // Lambert
                    float3 lightColor = _LightColor0.rgb;
                    float3 diffuse = albedo * lightColor * DotClamped(lightDir, worldNormal);

                    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                    float3 halfVector = normalize(lightDir + viewDir);  // Blin Phong
                    float3 specular = albedo * pow(DotClamped(halfVector, worldNormal), _Smoothness * 100);

                    float3 result = specular + diffuse;
                    return float4(result,1.0);
                }
            ENDCG
        }                  
    }
    FallBack "Diffuse"
}
