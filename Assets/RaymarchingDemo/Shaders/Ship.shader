Shader "Raymarching/Ship"
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
        _MinDistance ("Minimum Distance", Range(0.001, 0.1)) = 0.01
        _DistanceMultiplier ("Distance Multiplier", Range(0.001, 2.0)) = 1.0
        _ShadowLoop ("Shadow Loop", Range(1, 100)) = 10
        _ShadowMinDistance ("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
        _ShadowExtraBias ("Shadow Extra Bias", Range(0.0, 0.1)) = 0.01
        [PowerSlider(10.0)] _NormalDelta ("NormalDelta", Range(0.00001, 0.1)) = 0.0001

        // @block Properties
        // _Color2 ("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
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

        float dEngine(float3 p)
        {
            float3 o = p;

            p.xz = foldRotate(o.xz, 12);
            p.y = opRepRange(p.y, 0.12, 0.7);
            p.z -= cos(abs(o.y * 1.0)) * 0.3 + 0.1;

            // 周り
            float d = sdBox(p, float3(0.1, 0.05, 0.02));

            // ディテール用
            p.y -= 0.01;
            d = min(d, sdBox(p, float3(0.03, 0.04, 0.05)));

            // 芯線みたいの
            d = min(d, sdCappedCylinder(o, cos(abs(o.y * 1.9)) * 0.2, 0.9));

            p = o;
            p.y -= 0.65;
            p.xz = foldRotate(p.xz, 12 * 2);
            p.z -= 0.18;
            p.xy = mul(rotate(0.4), p.xy);
            // d = min(d, sdBox(p, float3(0.03, 0.04, 0.05)));
            float dFan = sdBox(p, float3(0.02, 0.005, 0.1));
            d = min(d, dFan);
            // d = dFan;

            return d;
        }

        inline float DistanceFunction(float3 pos)
        {
            return dEngine(pos);
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            
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