using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class gpuComputeShader : MonoBehaviour
{
    struct Particle
    {
        public Vector3 pos;     //起始位置
        public Vector3 newPos;      //更新位置
    }
    int ThreadBlockSize = 256;  //线程组大小
    int blockPerGrid;       //每个组
    ComputeBuffer ParticleBuffer, argsBuffer;
    private uint[] _args;
    private int number;  //粒子数目
    public int width, height; //设置长宽范围
    public int interval;        //间隔距离
    public float randomDegree;      //随机角度
    public float radius_r, radius_R, length_h;      //圆台的小半径、大半径、长度
    [SerializeField]
    private Mesh Particle_Mesh;         //粒子网格
    [SerializeField]
    ComputeShader _computeShader;       //申明computeshader
    [SerializeField]
    private Material _material;     //粒子材质

    private void Start()
    {
        number = width * height;
        randomDegree = Random.Range(1, 359);    //随机一个1-359的度数
        Particle[] particles = new Particle[number];    //创建粒子数组
        blockPerGrid = (number + ThreadBlockSize - 1) / ThreadBlockSize;    
        ParticleBuffer = new ComputeBuffer(number, 24); //创建第一个ComputeBuffer 6*4 ----> 24
        _args = new uint[5] { 0, 0, 0, 0, 0 };
        argsBuffer = new ComputeBuffer(1, _args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        //粒子的开始位置设0
        for (int i = 0; i < width; ++i)         //遍历设置粒子位置
        {
            for (int j = 0; j < height; ++j)
            {
                int id = i * height + j;
                float x = (float)i / (width - 1);
                float y = (float)j / (height - 1);
                particles[id].pos = new Vector3((x * interval), (y * interval), y * interval);
                particles[id].newPos = new Vector3((x * interval), (y * interval), y * interval);
            }
        }
        //setdata
        ParticleBuffer.SetData(particles);
    }

    private void Update()
    {
        randomDegree = Random.Range(1, 359);
        UpdateComputeShader();
        argsBuffer.SetData(_args);
        Graphics.DrawMeshInstancedIndirect(Particle_Mesh, 0, _material, new Bounds(Vector3.zero, new Vector3(100f, 100f, 100f)), argsBuffer);
    }

    private void UpdateComputeShader()
    {
        int kernelId = _computeShader.FindKernel("CSMain");
        _computeShader.SetFloat("_deltaTime", Time.deltaTime);

        _computeShader.SetFloat("_radius_r", radius_r);
        _computeShader.SetFloat("_radius_R", radius_R);
        _computeShader.SetFloat("_length_h", length_h);
        _computeShader.SetFloat("_randomDegree", randomDegree);
        _computeShader.SetBuffer(kernelId, "_ParticleBuffer", ParticleBuffer);
        _computeShader.Dispatch(kernelId, blockPerGrid, 1, 1);

        _args[0] = (uint)Particle_Mesh.GetIndexCount(0);
        _args[1] = (uint)number;
        _args[2] = (uint)Particle_Mesh.GetIndexStart(0);
        _args[3] = (uint)Particle_Mesh.GetBaseVertex(0);

        _material.SetBuffer("_ParticleBuffer", ParticleBuffer);
        _material.SetMatrix("_GameobjectMatrix", this.transform.localToWorldMatrix);
    }
}
