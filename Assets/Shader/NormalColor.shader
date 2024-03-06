Shader "Unlit/NormalColor"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldnormal:TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.worldnormal.xyzz;
            }
            ENDCG
        }
    }
}
