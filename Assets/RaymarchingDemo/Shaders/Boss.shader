Shader "Raymarching/Boss"
{

    Properties
    {
        [Header(PBS)]
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.5
        _Glossiness ("Smoothness", Range(0.0, 1.0)) = 0.5

        [Header(Pass)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Culling", Int) = 2

        [Header(Raymarching)]
        _Loop ("Loop", Range(1, 100)) = 30
        _MinDistance ("Minimum Distance", Range(0.001, 0.1)) = 0.001
        _DistanceMultiplier ("Distance Multiplier", Range(0.001, 2.0)) = 1.0
        _ShadowLoop ("Shadow Loop", Range(1, 100)) = 10
        _ShadowMinDistance ("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.005
        _ShadowExtraBias ("Shadow Extra Bias", Range(0.0, 0.1)) = 0.01
        [PowerSlider(10.0)] _NormalDelta ("NormalDelta", Range(0.00001, 0.1)) = 0.0001

        // @block Properties
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        [HDR] _EmissionColorB ("Emission Color B", Color) = (1, 1, 1, 1)
        // @endblock
    }

    SubShader
    {

        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "DisableBatching" = "True" }

        Cull [_Cull]

        CGINCLUDE

        #define OBJECT_SHAPE_CUBE

        #define CAMERA_INSIDE_OBJECT

        #define USE_RAYMARCHING_DEPTH

        #define SPHERICAL_HARMONICS_PER_PIXEL

        #define DISTANCE_FUNCTION DistanceFunction
        #define POST_EFFECT PostEffect
        #define PostEffectOutput SurfaceOutputStandard

        #include "Assets\uRaymarching\Shaders\Include\Legacy/Common.cginc"

        // @block DistanceFunction
        #include "Common.cginc"

        float4 _EmissionColor;
        float4 _EmissionColorB;

        #define MAT_BODY_A 1
        #define MAT_WING_B 2

        float2 foldRotateWing(float2 p, float s, inout float a)
        {
            a = PI / s - atan2(p.x, p.y);
            float n = TAU / s;
            a = floor(a / n) * n;
            p = mul(rotate(a), p);
            return p;
        }

        float dFeather(float3 pos, float scale)
        {
            float3 p = pos;

            float h = 4 * scale;
            p.y -= h;
            float3 size = scale * float3(0.4 - p.y * 0.2, 4, 0.1);

            return sdBox(p, size);
        }

        float2 dBoss(float3 pos)
        {
            float3 p = pos;

            p.x = abs(p.x);

            float2 res = float2(sdSphere(p, 1.0), MAT_BODY_A);

            for (int i = 0; i < 5; i++)
            {
                float3 p1 = p;

                float s = TAU / 6 + TAU / 16 * i;
                
                rot(p1.xy, -s + 0.3 * sin(_Beat * TAU / 4));
                rot(p1.xz, 0.3);
                p1 -= float3(0, 1, 0);

                s = saturate(cos(s * 0.2 + TAU / 24));
                s = s * s ;

                // s = 1;

                res = opU(res, float2(dFeather(p1, s), MAT_WING_B));
            }

            return res;
        }

        inline float DistanceFunction(float3 pos)
        {
            float2 res = dBoss(pos);
            return res.x;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 scale = GetScale();
            float3 p = ToLocal(ray.endPos) * scale;
            float2 res = dBoss(p);
        }
        // @endblock

        ENDCG

        Pass
        {
            Tags { "LightMode" = "Deferred" }

            Stencil
            {
                Comp Always
                Pass Replace
                Ref 128
            }

            CGPROGRAM

            #include "Assets\uRaymarching\Shaders\Include\Legacy/DeferredStandard.cginc"
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma exclude_renderers nomrt
            #pragma multi_compile_prepassfinal
            #pragma multi_compile ___ UNITY_HDR_ON
            ENDCG

        }

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #include "Assets\uRaymarching\Shaders\Include\Legacy/ShadowCaster.cginc"
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            ENDCG

        }
    }

    Fallback "Raymarching/Fallbacks/StandardSurfaceShader"

    CustomEditor "uShaderTemplate.MaterialEditor"
}