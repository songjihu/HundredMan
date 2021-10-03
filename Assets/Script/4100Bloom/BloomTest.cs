using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BloomTest : PostEffectsBase

{
    public Shader bloomShader;                  // 定义使用Shader的名字
    private Material bloomMaterial = null;      // 定义材质

    public Material material                    // 检查Shader是否存在并创建材质
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]
    public int iterations = 3;                  // 模糊迭代次数
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;             // 模糊范围
    [Range(1, 8)]
    public int downSample = 2;                  // 下采样，控制渲染纹理的大小
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;     // 阈值，开启了HDR所以为1-4

                                    
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);
                                                // 阈值传给shader
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
                                                // 创建一张渲染纹理并设置为双线性滤波
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;
                                                // 使用shader中的第一个Pass提取纹理src中较亮的部分给buffer0
            Graphics.Blit(src, buffer0, material, 0);
                                                // 开始循环模糊，每次迭代扩大范围，分别在竖直和水平方向模糊
            for(int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            material.SetTexture("_Bloom", buffer0);                                         // 将迭代的结果赋值给纹理参数
            Graphics.Blit(src, dest, material, 3);                                          // 混合结果
            RenderTexture.ReleaseTemporary(buffer0);

        }
        else
        {
            Graphics.Blit(src, dest);                                                       // 不进行计算
        }
    }




}
