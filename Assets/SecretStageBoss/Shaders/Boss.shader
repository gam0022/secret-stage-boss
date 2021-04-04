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
        _BodySizeA ("Body Size A", Vector) = (1, 1, 1, 1)
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
        float4 _BodySizeA;

        #define MAT_BODY_A 1
        #define MAT_BODY_B 2
        #define MAT_WING_A 3
        #define MAT_WING_B 4

        float2 foldRotateWing(float2 p, float s, inout float a)
        {
            a = PI / s - atan2(p.x, p.y);
            float n = TAU / s;
            a = floor(a / n) * n;
            p = mul(rotate(a), p);
            return p;
        }

        float2 mFeather(float3 pos, float scale)
        {
            float3 p = pos;

            float h = 4 * scale;
            p.y -= h;
            float3 size = scale * float3(0.4 - p.y * 0.2, 4, 0.1);

            float2 res = float2(sdBox(p, size), MAT_WING_A);

            size.x *= 0.1;
            size.z *= 1.5;
            // size.y *= 0.9;
            res = opU(res, float2(sdBox(p, size), MAT_WING_B));

            return res;
        }

        float2 mBody(float3 pos)
        {
            float3 p = pos;

            float r = 0.5 - 0.1 * abs(p.y);

            // 上下の枠
            p.xz = foldRotate(pos.xz, 6);
            p.y = abs(p.y) - 0.7;
            p.y -= 0.4 * abs(p.x);
            p.z -= r + _BodySizeA.w;
            float2 res = float2(sdBox(p, _BodySizeA.xyz), MAT_BODY_A);

            // 太い枠・縦
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.z -= r + 0.1;
            res = opU(res, float2(sdBox(p, float3(0.2 + 0.04 * (p.y - 1.0), 0.75, 0.05)), MAT_BODY_A));

            // 細かい線
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.y = opRepRange(p.y, 0.12, 0.1);
            p.z -= r - 0.05;
            res = opU(res, float2(sdBox(p, float3(0.3, 0.03, 0.02)), MAT_BODY_B));

            // 芯線
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            res = opU(res, float2(sdBox(p, float3(0.4, 0.9, 0.2)), MAT_BODY_A));

            return res;
        }

        float2 mBoss(float3 pos)
        {
            float3 p = pos;

            p.x = abs(p.x);
            // p.y -= -0.5 * sin(_Beat * TAU / 4);

            float2 res = mBody(p);

            for (int i = 0; i < 5; i++)
            {
                float3 p1 = p;

                float s = TAU / 6 + TAU / 16 * i;
                
                rot(p1.xy, -s + 0.3 * sin(_Beat * TAU / 4));
                rot(p1.xz, 0.3);
                rot(p1.yz, 0.3 * sin(i * 0.5 + _Beat * TAU / 4));
                p1 -= float3(0, 1, 0.3 - 0.2 * i);

                s = saturate(cos(s * 0.2 + TAU / 24));
                s = s * s ;

                res = opU(res, mFeather(p1, s));
            }

            return res;
        }

        inline float DistanceFunction(float3 pos)
        {
            float2 res = mBoss(pos);
            return res.x;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 scale = GetScale();
            float3 p = ToLocal(ray.endPos) * scale;
            float2 res = mBoss(p);

            float edge = calcEdge(p, 0.02);

            if (res.y == MAT_BODY_B)
            {
                float s = 5;
                if (((0.5 - p.y / scale.y) - frac(_Beat)) > 0)
                {
                    // o.Emission = _EmissionColor;
                }

                o.Emission = _EmissionColor * _AudioSpectrumLevels[0] * 20;
            }
            else if (res.y == MAT_BODY_A)
            {
                // o.Emission += _EmissionColor * edge;
            }
            else if (res.y == MAT_WING_B)
            {
                o.Emission = _EmissionColor * saturate(sin(_Beat * TAU));
            }
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