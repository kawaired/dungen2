Shader "Unlit/MultiLight"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1) // 漫反射颜色
        _Specular("Specular", Color) = (1, 1, 1, 1) // 高光反射颜色
        _Gloss("Gloss", Range(8, 256)) = 20 // 高光区域大小
    }

        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        // Base Pass 计算平行光、环境光
        pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                // 编译指令，保证在pass中得到Pass中得到正确的光照变量
                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                fixed4 _Diffuse;
                fixed4 _Specular;
                float _Gloss;

                // 应用传递给顶点着色器的数据
                struct a2v
                {
                    float4 vertex: POSITION; // 语义: 顶点坐标
                    float3 normal: NORMAL; // 语义: 法线
                };

                // 顶点着色器传递给片元着色器的数据
                struct v2f
                {
                    float4 pos: SV_POSITION; // 语义: 裁剪空间的顶点坐标
                    float3 worldNormal: TEXCOORD;
                    float3 worldPos: TEXCOORD1;
                };

                // 顶点着色器
                v2f vert(a2v v)
                {
                    v2f o;

                    // 将顶点坐标从模型空间变换到裁剪空间
                    // 等价于o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 将法线从模型空间变换到世界空间
                    // 等价于o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    // 将顶点坐标从模型空间变换到世界空间
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                    return o;
                }

                // 片元着色器
                fixed4 frag(v2f i) : SV_TARGET
                {
                    fixed3 worldNormal = normalize(i.worldNormal);
                // 获得世界空间下单位光向量 (是ForwardBase的pass，光一定是平行光)
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射
                // 兰伯特公式：Id = Ip * Kd * N * L
                // IP：入射光的光颜色；
                // Kd：漫反射颜色；
                // N：单位法向量，L：单位光向量
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // 观察方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 半角向量
                float3 halfDir = normalize(worldLightDir + viewDir);
                // 计算高光反射
                // Blinn-Phong高光反射公式：
                // Cspecular=(Clight * Mspecular) * max(0,n.h)^mgloss
                // Clight：入射光颜色；
                // Mspecular：高光反射颜色；
                // n: 单位法向量；
                // h: 半角向量：光线和视线夹角一半方向上的单位向量 h = (V + L)/(| V + L |)
                // mgloss：反射系数；
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                return fixed4(ambient + diffuse + specular, 1);
            }

            ENDCG

        }

    // Add pass 计算额外的逐像素光源(点光源、聚光灯等), 每个pass对应1个光源
    pass
    {
        Tags { "LightMode" = "ForwardAdd" }

            // 开启混合，
            Blend One One
            CGPROGRAM

            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

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
                float3 worldNormal: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                v2f o;

                // 将顶点坐标从模型空间变换到裁剪空间
                // 等价于o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将法线从模型空间变换到世界空间
                // 等价于o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 将顶点坐标从模型空间变换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed3 worldNormal = normalize(i.worldNormal);

            // 世界空间光向量一般直接用Unity内置函数计算
            // 即：fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos))
            #ifdef USING_DIRECTIONAL_LIGHT
                // 平行光
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
            #else
                // 非平行光
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
            #endif

                // 计算漫反射颜色
                // 兰伯特公式：Id = Ip * Kd * N * L
                // IP：入射光的光颜色；
                // Kd：漫反射颜色；
                // N：单位法向量，L：单位光向量
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                // 观察向量
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 半角向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 计算高光反射
                // Blinn-Phong高光反射公式：
                // Cspecular=(Clight * Mspecular) * max(0,n.h)^mgloss
                // Clight：入射光颜色；
                // Mspecular：高光反射颜色；
                // n: 单位法向量；
                // h: 半角向量：光线和视线夹角一半方向上的单位向量 h = (V + L)/(| V + L |)
                // mgloss：反射系数；
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(diffuse + specular, 1.0);
            }
            ENDCG

        }
    }
}
