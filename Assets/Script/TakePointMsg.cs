using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TakePointMsg : MonoBehaviour
{
    Light ptlight;
    // Start is called before the first frame update
    void Start()
    {
        ptlight = GetComponent<Light>();
    }

    private void Update()
    {
        if (ptlight.type == LightType.Point)
        {
            //Debug.Log(transform.position);
            Shader.SetGlobalVector("_PointLightPos", transform.position);
            Shader.SetGlobalVector("_PointLightColor", ptlight.color);
        }
    }
}
