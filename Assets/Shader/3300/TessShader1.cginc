#include "Tessellation.cginc"

#pragma target 5.0

sampler2D _MainTex;
float4 _MainTex_ST;

struct VertexInput{                                    // 顶点输入结构体
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD;
};

struct VertexOutput{                                   // 顶点输出结构体
    float4 vertex : SV_POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD;
};

VertexOutput vert (VertexInput v){                     // 无需转换，在几何着色器中转换过了
    VertexOutput o;
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.vertex = v.vertex;                                     
    o.normal = v.normal;
    o.tangent = v.tangent;

    return o;
}

            
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
    o.uv = v.uv ;
    return o;
}

//------------------------------------hull shader部分------------------------------------------------
float _TessellationUniform;
OutputPatchConstant hsconst (InputPatch<TessVertex, 3> patch){
    float minDist = 10.0;
    float maxDist = 25.0;                               // 基于距离设置影响因子
    float4 distanceFactor = UnityDistanceBasedTess(patch[0].vertex, patch[1].vertex, patch[2].vertex, minDist, maxDist, 4);
    OutputPatchConstant o;                              // 曲面细分的参数设置函数
    o.edge[0] = distanceFactor.x * 4;
    o.edge[1] = distanceFactor.y * 4;
    o.edge[2] = distanceFactor.z * 4;
    o.inside = distanceFactor.w * 4;
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
