using UnityEngine;
using System.Collections;
namespace SwanEngine.Core
{
    public class DepthTextureCamera : MonoBehaviour
    {
        Camera _camera;//在平行光源处创建相机

        RenderTexture rt_2d;//光源处的深度纹理，shadowMap
        public Transform lightTrans;

        Matrix4x4 sm = new Matrix4x4();

        public Material shadowCasterMat = null;//从光源处投射阴影的材质
        public Material shadowCollectorMat = null;//从MainCamera处比较深度和shadowMap计算深度的材质
        public GameObject _light;//平行光

        public float orthographicSize = 6f;//一些相机参数
        public float nearClipPlane = 0.3f;
        public float farClipPlane = 20f;
        RenderTexture screenSpaceShadowTexture = null;//屏幕空间下的深度纹理
        public int qulity = 2;//深度纹理的质量
        void Start()
        {
            _camera = CreateDirLightCamera();//在光源处创建相机
            _camera.transform.parent = this.transform;//父亲为平行光
            _camera.transform.localPosition = Vector3.zero;
            _camera.transform.localRotation = Quaternion.identity;
            _camera.orthographicSize = orthographicSize;
            _camera.nearClipPlane = nearClipPlane;
            _camera.farClipPlane = farClipPlane;

            _camera.cullingMask = 1 << LayerMask.NameToLayer("Caster");

        }

        void Update()
        {
            if (!_camera.targetTexture)
                _camera.targetTexture = Create2DTextureFor(_camera);
            Shader.SetGlobalFloat("_gShadowBias", 0.005f);
            _camera.RenderWithShader(Shader.Find("CustomShadow/Caster"),"");//渲染光源角度的深度图，即ShadowMap
            Shader.SetGlobalTexture("_gShadowMapTexture", rt_2d);
            Shader.SetGlobalFloat("_gShadowStrength", 0.5f);

            if (screenSpaceShadowTexture == null)
            {
                screenSpaceShadowTexture = new RenderTexture(Screen.width * qulity, Screen.height * qulity, 0, RenderTextureFormat.Default);
                screenSpaceShadowTexture.hideFlags = HideFlags.DontSave;
            }

            Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, false);
            Shader.SetGlobalMatrix("_gWorldToShadow", projectionMatrix * _camera.worldToCameraMatrix);//设置从世界空间到光源空间的矩阵

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

            rt_2d = new RenderTexture(512* 2, 512 * 2, 24, rtFormat);
            rt_2d.hideFlags = HideFlags.DontSave;

            Shader.SetGlobalTexture("_gShadowMapTexture", rt_2d);

            return rt_2d;
        }


    }
}
