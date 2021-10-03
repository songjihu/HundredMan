// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "HundredTalentsProgram/3300TSandGs/GrassWithTessShader1"
{
    Properties
    {
        [Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)                       // 顶部颜色
        _BottomColor("Bottom Color", Color) = (1,1,1,1)                 // 底部颜色

        _TranslucentGain("Translucent Gain", Range(0,1)) = 0.5          // 

        _BladeWidth("Blade Width", Float) = 0.05                        // 小草宽度
        _BladeWidthRandom("Blade Width Random", Float) = 0.02           
        _BladeHeight("Blade Height", Float) = 0.5                       // 小草高度
        _BladeHeightRandom("Blade Height Random", Float) = 0.3
        _BendRotationRandom("Bend Rotation Random", Range(-1,1)) = 0.2  // 小草弯曲的程度
        _BladeForward("Blade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}      // 风 Texture
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)   // 风 频率         
        _WindStrength("Wind Strength", Float) = 1                       // 风 强度

        _TessellationUniform("Tessellation Uniform", Range(1,64)) = 1   // 曲面细分的范围 1 - 64


        _TestLocation("Test Location", Vector) = (0, 0, 0, 0)           // 测试世界坐标      
        _TestVector("Test Vector", Vector) = (0, 0, 0, 0)               // 测试Vector
        


    }

    CGINCLUDE
    #include "UnityCG.cginc"
    #include "TessShader.cginc"
    #include "Autolight.cginc"   

    #define BLADE_SEGMENTS 3

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
                            
    float3 model2clipPos(float3 pos){                                     // 模型空间到裁剪空间
        return UnityObjectToClipPos(pos);
    }

    float3 world2clipPos(float3 pos){                                     // 世界空间到裁剪空间
        return mul(UNITY_MATRIX_VP,pos);
    }
    
    float3 world2viewPos(float3 pos){                                     // 世界空间到观察空间
        return mul(UNITY_MATRIX_V,pos);
    }

    float3 model2viewPos(float3 pos){                                     // 模型空间到观察空间
        return mul(UNITY_MATRIX_MV,pos);
    }

    float compileFactor(float3 xPos, float3 yPos){                        // 计算影响因子 输入2个世界坐标
        //xPos = world2clipPos(xPos);
        //yPos = model2clipPos(yPos);
        // yPos = mul(unity_ObjectToWorld, yPos);
        return clamp(distance(xPos,yPos),0,1);
        // return distance(xPos,yPos);
        // return abs(yPos.x-xPos.x);
    }


    float4 _TestVector;

    float compileFacingFactor(float3 xPos, float3 yPos){                  // 计算影响因子
        //xPos = world2clipPos(xPos);
        //yPos = model2clipPos(yPos);
        // yPos = mul(unity_ObjectToWorld, yPos);
        float x = yPos.x-xPos.x;
        float z = yPos.z-xPos.z;
        float t = 0;
        if(x < 0){
            x = -x;
            z = -z;
            t = UNITY_PI;
        }
        return acos(dot(float3(0, 0, -1),normalize(float3(x, 0, z)))) + t;
        // return acos(dot(float3(0, 0, -1),normalize(float3(yPos.x-xPos.x, 0, yPos.z-xPos.z)))) / _TestVector.y * 6.3;
        // return distance(xPos,yPos);
        // return abs(yPos.x-xPos.x);
    }



    float _BladeHeight;
    float _BladeHeightRandom;
    float _BladeWidth;
    float _BladeWidthRandom;
    sampler2D _WindDistortionMap;
    float4 _WindDistortionMap_ST;
    float _WindStrength;
    float2 _WindFrequency;
    float _BendRotationRandom;
    float _BladeForward;
    float _BladeCurve;
    float4 _TestLocation;

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

    geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float height, float forward, float2 uv, float3x3 transformMatrix){
        float3 tangentPoint = float3(width, forward, height);
        float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);
        return CreateGeoOutput(localPosition, uv);
    }

    [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]                    // 定义最大输出点
    void geo(triangle VertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream){
                                                                // 输入 三角形 输出 三角形（每个点用到了结构体）
        float3 pos = IN[0].vertex;
        float3 vNormal = IN[0].normal;
        float4 vTangent = IN[0].tangent;
        float4 vWorldPos = IN[0].worldPos;
        float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

        float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
        float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
        float forward = rand(pos.yyz) * _BladeForward;          // 前向弯曲程度
                                                                // 受到风影响的变换矩阵
        float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
        float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
        float3 wind = normalize(float3(windSample.x, windSample.y, 0));
        float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);
                                                                // 朝向旋转矩阵
        float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
                                                                // 向前弯曲矩阵
        float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
                                                                // 空间变换矩阵（从切线空间变换到本地空间）
        float3x3 tangentToLocal = float3x3(
            vTangent.x, vBinormal.x, vNormal.x,
            vTangent.y, vBinormal.y, vNormal.y,
            vTangent.z, vBinormal.z, vNormal.z
        );
        float3x3 transformationMat = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);

        float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

        geometryOutput o;
                                                                // 使用循环装入点，一次装2个
        // float4 wPos = mul(unity_ObjectToWorld, float4(pos,0));
        // float disFactor = clamp(abs(wPos.x - _TestLocation.x) * abs(wPos.z - _TestLocation.z) * abs(wPos.y - _TestLocation.y) * 1,0,1) ;
        // float disFactor = clamp(distance(wPos, _TestLocation),0,1) ;


        float disFactor = compileFactor(_TestLocation,vWorldPos);
        float forwardFactor = 2;                                // 草增加弯曲程度
        float underFactor = 1;
        float windFactor = 0.5;
        float facingFactor = compileFacingFactor(_TestLocation,vWorldPos);     
        float3x3 windRotationCus = AngleAxis3x3(UNITY_PI * windSample * windFactor * disFactor, wind);
        float3x3 bendRotationMatrixCus = AngleAxis3x3(forwardFactor * disFactor * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
        float3x3 facingRotationMatrixCus = AngleAxis3x3(facingFactor, float3(0, 0, 1)); 

        float3x3 transformationMatCus = mul(tangentToLocal, windRotationCus);
        transformationMatCus = mul(mul(transformationMatCus, bendRotationMatrixCus),facingRotationMatrixCus);
        underFactor = disFactor < 0.6 ? 0.2 * disFactor : 1;    // 判断是否草在正下方
        disFactor = disFactor < 0.8 ? disFactor * 0.9 : 1;        // 小于 0.5 的草高度降低
        height = height * disFactor * underFactor; 
        transformationMat = disFactor < 1 ? transformationMatCus : transformationMat;
        transformationMatrixFacing = disFactor < 1 ? transformationMatCus : transformationMatrixFacing;
        for(int i = 0; i < BLADE_SEGMENTS; i++){
            float t = i / (float)BLADE_SEGMENTS;                // 自底向上，逐渐收缩
            float segmentHeight = height * t;
            float segmentWidth = width * (1 - t);
            //float segmentForward = pow(t, _BladeCurve) * forwardFactor;
            float segmentForward = pow(t, _BladeCurve) * forward;
            float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMat;
                                                                // 最下边的点不需要改变朝向和弯曲
            triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, segmentForward, float2(0, t), transformMatrix));
            triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, segmentForward, float2(1, t), transformMatrix));
        }
                                                                // 添加最后一个点
        triStream.Append(GenerateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMat));
    }
    ENDCG

    SubShader
    {
        Cull Off

        Pass {

            Tags {
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma vertex tessvert                                     // 顶点着色器
            #pragma hull hullProgram                                    // 壳函数
            #pragma domain ds                                           
            #pragma geometry geo                                        // 几何着色器
            #pragma fragment frag                                       // 像素着色器

            #include "Lighting.cginc"                                 

            #pragma target 4.6

            float4 _TopColor;                                           
            float4 _BottomColor;                                       
            float _TranslucentGain;                                     

            
            //----------------------------------------------------------// 像素着色器 -------------------------------------------------------------------
            float4 frag (geometryOutput i, fixed facing : VFACE) : SV_Target{
                return lerp(_BottomColor, _TopColor, i.uv.y);
            }
            ENDCG
        }                  
    }
    FallBack "Diffuse"
}
