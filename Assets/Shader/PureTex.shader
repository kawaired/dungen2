Shader "Unlit/PureTex"
{
    Properties
    {
        _MainTex ("maintex", 2D) = "white" {}
        _MaskTex("masktex",2D) = "white"{}
        _RampMin("rampmin",range(-1,1))=-0.1
        _RampMax("rampmax",range(-1,1))=0.1
        _PointRampMin("pointrampmin",range(-1,1))=-0.1
        _PointRampMax("pointrampmax",range(-1,1))=0.1
        //_Ambient("ambient",Color)=(0.2,0.2,0.2,1)
        _ColorScale("colorscale",range(0,4))=1
        _PointLightRange("pointlightrange",range(1,4))=2
        _AttenuStartRange("attenustartrange",range(0,4))=4
        _AttenuFac("attenufac",range(0,1))=0.5


    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldpos:TEXCOORD1;
                float3 worldnormal:TEXCOORD2;
                float3 ptlightdir:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float _RampMin;
            float _RampMax;
            float _PointRampMin;
            float _PointRampMax;
			//float4 _Ambient;
            float4 _LightColor0;
            float4 _PointLightPos;
            float4 _PointLightColor;
            float _ColorScale;
            float _PointLightRange;
            float _AttenuStartRange;

            float _AttenuFac;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldpos = mul(unity_ObjectToWorld, v.vertex);
                o.worldnormal= UnityObjectToWorldNormal(v.normal);
                //o.ptlightdir = _PointLightPos - o.worldpos;
                return o;
            }

            float MyRamp(float x,float min, float max)
            {
                float rampfac=clamp((x - min) / (max - min),-1,1);
                return 0.55 + rampfac * 0.45;
            }

            float MyAttenu(float mulsqar)
            {
                float fac = mulsqar * _AttenuFac;
                fac =  (sqrt(max(_PointLightRange - pow(fac, 2),0) / mulsqar));
                return fac;
            }

            float DirAttenu(float3 normaldir, float3 affectdir, float2 sideoffsetvector)
            {
                float affectdot = dot(normaldir, affectdir);
                float r4 = (affectdot * sideoffsetvector.x + sideoffsetvector.y);
                return pow(r4, 2);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 maincolor = tex2D(_MainTex, i.uv);
              
                float4 maskcolor = tex2D(_MaskTex, i.uv);

                //return maincolor*maskcolor.x;

                float3 lightdir = normalize(_WorldSpaceLightPos0.xyz);
                float lambert =  saturate(MyRamp(dot(lightdir, normalize(i.worldnormal)), _RampMin, _RampMax));
                float4 lightonecolor= lambert * _LightColor0 * maincolor * maskcolor.x * _ColorScale;
                //return lightonecolor;

                float3 ptlightdir = _PointLightPos - i.worldpos;
                float3 ptlightnormal = normalize(ptlightdir);
                float ptlightdis = length(ptlightdir);
                float lambert2 = saturate(MyRamp(dot(normalize(ptlightdir), normalize(i.worldnormal)), _PointRampMin, _PointRampMax));
                float4 attenucolor = MyAttenu(pow(ptlightdis, 2)) * DirAttenu(ptlightnormal, float3(1.2, 0, 0), float2(0.7, 0.6));
                float4 lighttwocolor = attenucolor * lambert2 * _PointLightColor * maincolor * maskcolor.x;
                //return lighttwocolor;

                return lightonecolor + lighttwocolor;

                //return lightonecolor;

                //float3 ptlightdir = _PointLightPos - i.worldpos;
                //float ptlightdis = length(ptlightdir);
                //float attenurate = 1 - saturate((ptlightdis - _AttenuStartRange) / (_PointLightRange - _AttenuStartRange));
                //float4 lighttwocolor = attenurate * _PointLightColor * maincolor * maskcolor.x;
                ////float3 ptlightdir = _PointLightPos - i.worldpos;
                ////return lighttwocolor;
                //float lambert2 = dot(ptlightdir, normalize(i.worldnormal));

                //return lightonecolor + lighttwocolor * (lambert2>0);




                //return normalize(i.ptlightdir).xyzz;

            }
            ENDCG
        }

    pass
    {
            cull front
            // 开启混合，
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            // 应用传递给顶点着色器的数据
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            // 顶点着色器传递给片元着色器的数据
            struct v2f
            {
                float4 pos: SV_POSITION;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex + float4(v.normal*0.2 , 0));
                return o;
            }

            // 片元着色器
            float4 frag(v2f i) : SV_TARGET
            {
                return float4(0,0,0,1);
            }
            ENDCG
        }
    }
}
