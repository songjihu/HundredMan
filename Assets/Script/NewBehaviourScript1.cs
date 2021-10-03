using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewBehaviourScript1 : MonoBehaviour
{

    public float m_speed = 0.1f;
    public GameObject[] planeArray;
    public GameObject ball;
    public Vector4 loc;
    // Start is called before the first frame update
    void Start()
    {
        ball = GameObject.Find("Sphere");
    }

    // Update is called once per frame
    void Update()
    {
        MoveControlByTranslate();
        loc = ball.GetComponent<Transform>().position;
        SetVec();

    }



    //Translate移动控制函数
    void MoveControlByTranslate()
    {
        if (Input.GetKey(KeyCode.W) | Input.GetKey(KeyCode.UpArrow)) //前
        {
            this.transform.Translate(Vector3.forward * m_speed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.S) | Input.GetKey(KeyCode.DownArrow)) //后
        {
            this.transform.Translate(Vector3.forward * -m_speed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.A) | Input.GetKey(KeyCode.LeftArrow)) //左
        {
            this.transform.Translate(Vector3.right * -m_speed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.D) | Input.GetKey(KeyCode.RightArrow)) //右
        {
            this.transform.Translate(Vector3.right * m_speed * Time.deltaTime);
        }
    }

    void SetVec()
    {

        planeArray = GameObject.FindGameObjectsWithTag("plane");
        foreach (GameObject respawn in planeArray)
        {
            respawn.GetComponent<Renderer>().material.SetColor("_TestLocation", loc);
        }
    }


}
