using System.Collections;
using System.Collections.Generic;
using UnityEngine;
 
public class ChangeMaterial : MonoBehaviour
{
    // Start is called before the first frame update

    void Start()
    {
        Random.InitState((int)System.DateTime.Now.Ticks);//初始化随机种子
    }
 
    // Update is called once per frame
    void Update()
    {
        //Vector4 loc = new Vector4(0, 0, 0, 0);//生成位置
        GameObject ball = GameObject.Find("Sphere");
        Vector4 loc = ball.GetComponent<Transform>().position;
        //gameObject.GetComponent<Renderer>().material.SetColor("_TestLocation", loc);//Material.SetColor设置颜色属性
        if(System.Math.Abs(loc.x-this.GetComponent<Transform>().position.x)<=5 && System.Math.Abs(loc.y-this.GetComponent<Transform>().position.y)<=5){
            //gameObject.GetComponent<Renderer>().material.SetColor("_TestLocation", loc);//Material.SetColor设置颜色属性
        }
    }
}