Shader "Raymarching/WorldBuilding"
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

        [PowerSlider(10.0)] _NormalDelta ("NormalDelta", Range(0.00001, 0.1)) = 0.0001

        // @block Properties
        [Header(World)]
        _HexagonRadians ("Hexagon Radians", Range(0, 5)) = 1
        _HexagonPadding ("Hexagon Padding", Range(0, 1)) = 0.1
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        // @endblock
    }

    SubShader
    {

        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" "DisableBatching" = "True" }

        Cull [_Cull]

        CGINCLUDE

        #define FULL_SCREEN

        #define WORLD_SPACE

        #define OBJECT_SHAPE_NONE

        #define CAMERA_INSIDE_OBJECT

        #define USE_RAYMARCHING_DEPTH

        #define SPHERICAL_HARMONICS_PER_PIXEL

        #define DISTANCE_FUNCTION DistanceFunction
        #define POST_EFFECT PostEffect
        #define PostEffectOutput SurfaceOutputStandard

        #include "Assets\uRaymarching\Shaders\Include\Legacy/Common.cginc"

        // @block DistanceFunction
        #include "Common.cginc"

        float _HexagonRadians;
        float _HexagonPadding;
        float4 _EmissionColor;

        float dHexagon(float3 p)
        {
            p.xz = foldRotate(p.xz, 6);
            return sdBox(p, float3(_HexagonRadians, 1, _HexagonRadians));
        }

        inline float DistanceFunction(float3 pos)
        {
            float3 p = pos;

            float pitch = _HexagonRadians * 2 + _HexagonPadding;
            float sqrt3_div_2 = 0.8660254037844386467637231707529361834714026269051903140279034897;
            float3 offset = float3(pitch * sqrt3_div_2, 0, pitch * 0.5);
            float3 loop = float3(offset.x * 2, 10, offset.z * 2);
            
            float3 p1 = p;
            float3 p2 = p + offset;

            // calculate indices
            float2 pi1 = floor(p1 / loop).xz;
            float2 pi2 = floor(p2 / loop).xz;
            pi1.y = pi1.y * 2;
            pi2.y = pi2.y * 2 + 1;

            p1.y += 0.5 * sin(10 * Rand(pi1) + 0.1 * TAU * _Beat);
            p2.y += 0.5 * sin(10 * Rand(pi2) + 0.1 * TAU * _Beat);
            p1 = Repeat(p1, loop);
            p2 = Repeat(p2, loop);

            float d = dHexagon(p1);
            d = min(d, dHexagon(p2));

            return d;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            // FIXME: Common定義
            float edge = calcEdge(ray.endPos, 0.01);// * saturate(cos(_Beat * TAU - Mod(0.1 * ray.endPos.z, TAU)));

            edge += 0.1 * (voronoi(ray.endPos.xz) + 0.5 * voronoi(ray.endPos.xz * 2.0));

            o.Emission = _EmissionColor * edge;
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
    }

    Fallback Off

    CustomEditor "uShaderTemplate.MaterialEditor"
}