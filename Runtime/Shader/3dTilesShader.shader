Shader "Custom/Tiles3D"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        baseColorTexture ("Base Color Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { 
            "RenderPipeline" = "UniversalPipeline" 
            "IgnoreProjector" = "True" 
            "Queue" = "Geometry" 
            "RenderType" = "Opaque"
        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            sampler2D baseColorTexture;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = v.uv;
               
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.vertex.xyz);
                o.shadowCoord = TransformWorldToShadowCoord(o.worldPos);

                return o;
            }

            float3 Lambert(float3 lightColor, float3 lightDir, float3 normal)
            {
                float NdotL = saturate(dot(normal, lightDir));
                return lightColor * NdotL;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 texColor = tex2D(baseColorTexture, i.uv);
                float4 color = texColor * _Color;
                               
                Light mainLight = GetMainLight(i.shadowCoord); //get dir light
                float3 lightCol = Lambert(mainLight.color * mainLight.shadowAttenuation, mainLight.direction, float3(0,1,0)); //lets keep up normal always

                // uint lightsCount = GetAdditionalLightsCount();
                // for (int j = 0; j < lightsCount; j++)
                // {
                //     Light light = GetAdditionalLight(j, i.worldPos);
                //     lightCol += Lambert(light.color * (light.distanceAttenuation * light.shadowAttenuation), light.direction, i.normal);
                // }

                color.rgb *= lightCol + 1;
                return color;
            }
            ENDHLSL
        }
    }
}