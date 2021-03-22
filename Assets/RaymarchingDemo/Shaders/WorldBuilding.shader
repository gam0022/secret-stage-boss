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
        _BuildingRepeat ("Building Repeat", Vector) = (20, 20, 20, 1)
        _IfsLoop ("Ifs Loop", Range(1, 10)) = 5
        _BuildingOffset ("Building Offset", Vector) = (0, 0, 0, 1)
        _RotateXY1 ("_RotateXY1", Range(-4, 4)) = 0.3
        _RotateXZ1 ("_RotateXZ1", Range(-4, 4)) = -0.1
        _RotateYZ1 ("_RotateYZ1", Range(-4, 4)) = -0.1
        _FoldRotate ("Fold Rotate", Range(1, 20)) = 6
        _BuildingBoxSize ("Building Box Size", Vector) = (5, 0.5, 0.5, 1)
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

        float3 _BuildingRepeat;
        float _IfsLoop;
        float4 _BuildingOffset;
        float _RotateXY1;
        float _RotateXZ1;
        float _RotateYZ1;
        float3 _BuildingBoxSize;
        float _EvilScale;
        float4 _EmissionColor;

        inline float DistanceFunction(float3 pos)
        {
            float3 p = pos;

            p = Repeat(p, _BuildingRepeat);

            float3 size = _BuildingBoxSize;
            float d = sdBox(p, size);

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

        float random(float2 st)
        {
            return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
        }

        float noise(in float2 st)
        {
            float2 i = floor(st);
            float2 f = frac(st);
            
            // Four corners in 2D of a tile
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));
            
            // Smooth Interpolation
            // Cubic Hermine Curve.  Same as SmoothStep()
            float2 u = f * f * (3.0 - 2.0 * f);
            
            // u = smoothstep(0.,1.,f);
            // lerp 4 coorners percentages
            return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }

        // マンハッタン距離によるボロノイ
        float voronoi(float2 uv)
        {
            float2 i = floor(uv);
            float2 f = frac(uv);
            float2 res = float2(8, 8);

            for (int x = -1; x <= 1; x++)
            {
                for (int y = -1; y <= 1; y++)
                {
                    float2 n = float2(x, y);
                    float2 np = float2(random(i + n), random(i + n + float2(12.56, 64.66)));
                    float2 p = n + np - f;
                    float d = abs(p.x) + abs(p.y);

                    if (d < res.x)
                    {
                        res.y = res.x;
                        res.x = d;
                    }
                    else if (d < res.y)
                    {
                        res.y = d;
                    }
                }
            }

            float c = res.y - res.x;
            c = sqrt(c);
            c = smoothstep(0.3, 0.0, c);
            return c;
        }

        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            // float edge = calcEdge(ray.endPos) * saturate(cos(_Beat * TAU - Mod(0.1 * ray.endPos.z, TAU)));

            float edge = voronoi(ray.endPos.xz) + 0.5 * voronoi(ray.endPos.xz * 2.0);
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