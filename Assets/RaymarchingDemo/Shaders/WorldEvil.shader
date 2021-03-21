Shader "Raymarching/WorldEvil"
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
        _EvilRepeat ("Evil Repeat", Vector) = (20, 20, 20, 1)
        _IfsLoop ("Ifs Loop", Range(1, 10)) = 5
        _EvilOffset ("Evil Offset", Vector) = (0, 0, 0, 1)
        _RotateXY1 ("_RotateXY1", Range(-4, 4)) = 0.3
        _RotateXZ1 ("_RotateXZ1", Range(-4, 4)) = -0.1
        _RotateYZ1 ("_RotateYZ1", Range(-4, 4)) = -0.1
        _FoldRotate ("Fold Rotate", Range(1, 20)) = 6
        _EvilBoxSize ("Evil Box Size", Vector) = (5, 0.5, 0.5, 1)
        _EvilScale ("Evil Scale", Range(0, 2)) = 1.1
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

        float3 _EvilRepeat;
        float _IfsLoop;
        float4 _EvilOffset;
        float _RotateXY1;
        float _RotateXZ1;
        float _RotateYZ1;
        float3 _EvilBoxSize;
        float _EvilScale;
        float4 _EmissionColor;

        inline float DistanceFunction(float3 pos)
        {
            float4 p = float4(pos, 1);
            p.xyz = Repeat(p.xyz, _EvilRepeat);

            for (int i = 0; i < _IfsLoop; i++)
            {
                // p -= _EvilOffset;
                p.xyz = abs(p.xyz);
                p.xyz -= _EvilOffset;
                p.xy = mul(rotate(_RotateXY1), p.xy);
                p.xz = mul(rotate(_RotateXZ1), p.xz);
                p.yz = mul(rotate(_RotateYZ1), p.yz);
                p *= _EvilScale;
            }

            float3 size = _EvilBoxSize;
            // size.x += _AudioSpectrumLevels[0] * 50;
            float d = sdBox(p.xyz, size) / abs(p.w);

            return d;
        }
        // @endblock

        // @block PostEffect

        #define map DistanceFunction

        // https://www.shadertoy.com/view/lttGDn
        float calcEdge(float3 p)
        {
            float edge = 0.0;
            float2 e = float2(.1, 0);

            // Take some distance function measurements from either side of the hit point on all three axes.
            float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
            float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
            float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
            float d = map(p) * 2.;	// The hit point itself - Doubled to cut down on calculations. See below.

            // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
            // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
            // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface
            // curves that register a discernible difference.
            edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
            //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.

            // Once you have an edge value, it needs to normalized, and smoothed if possible. How you
            // do that is up to you. This is what I came up with for now, but I might tweak it later.
            edge = smoothstep(0., 1., sqrt(edge / e.x * 2.));

            // Return the normal.
            // Standard, normalized gradient mearsurement.
            return edge;
        }

        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float edge = calcEdge(ray.endPos) * saturate(cos(_Beat * TAU + Mod(0.05 * ray.endPos.z, TAU)));

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