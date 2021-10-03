using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript : MonoBehaviour
{


    RenderTexture rt_2d;
    Camera LightCamera;
    Shader shadowCaster ;
    // Start is called before the first frame update
    void Start()
    {
        LightCamera = CreateDirLightCamera();
    }

    // Update is called once per frame
    void Update()
    {
        if (!LightCamera.targetTexture)
            LightCamera.targetTexture = Create2DTextureFor(LightCamera);
        Shader.SetGlobalFloat("_gShadowBias", 0.005f);
        LightCamera.cullingMask = 1 << LayerMask.NameToLayer("Caster");
        shadowCaster = Shader.Find("CustomShadow/Caster");
        LightCamera.RenderWithShader(shadowCaster, "");
        //Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(dirLightCamera.projectionMatrix, false);
        //Shader.SetGlobalMatrix("_gWorldToShadow", projectionMatrix * dirLightCamera.worldToCameraMatrix);
    }

    public Camera CreateDirLightCamera()
    {
        GameObject goLightCamera = new GameObject("Directional Light Camera");
        Camera LightCamera = goLightCamera.AddComponent<Camera>();
        LightCamera.backgroundColor = Color.white;
        LightCamera.clearFlags = CameraClearFlags.SolidColor;
        LightCamera.orthographic = true;
        LightCamera.orthographicSize = 6f;
        LightCamera.nearClipPlane = 0.3f;
        LightCamera.farClipPlane = 20;

        LightCamera.enabled = false;

        return LightCamera;

    }

    private RenderTexture Create2DTextureFor(Camera cam)
    {
        RenderTextureFormat rtFormat = RenderTextureFormat.Default;
        if (!SystemInfo.SupportsRenderTextureFormat(rtFormat))
            rtFormat = RenderTextureFormat.Default;

        int shadowResolution = 2;
        rt_2d = new RenderTexture(512* shadowResolution, 512 * shadowResolution, 24);
        rt_2d.hideFlags = HideFlags.DontSave;

        Shader.SetGlobalTexture("_gShadowMapTexture", rt_2d);

        return rt_2d;
    }

}
