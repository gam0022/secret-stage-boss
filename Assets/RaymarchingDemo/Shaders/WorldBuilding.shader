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
        [HDR] _EmissionColorEdge ("Emission Color Edge", Color) = (1, 1, 1, 1)
        [HDR] _EmissionColorVoronoi ("Emission Color Voronoi", Color) = (1, 1, 1, 1)
        _ChangeThresholdZ ("Change Threshold Z", Float) = 0
        _BloomingThresholdZ ("Blooming Threshold Z", Float) = 0
        _ChangeRate ("Change Rate", Range(0, 1)) = 0
        _WingASize ("Wing A Size", Vector) = (0.1, 0.1, 0.1, 0.1)
        _WingARot ("Wing A Rot", Range(-4, 4)) = 0.3
        _WingBSize ("Wing B Size", Vector) = (0.1, 0.1, 0.1, 0.1)
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
        float4 _EmissionColorEdge;
        float4 _EmissionColorVoronoi;
        float _ChangeThresholdZ;
        float _BloomingThresholdZ;
        float _ChangeRate;
        float4 _WingASize;
        float _WingARot;
        float4 _WingBSize;

        #define MAT_BASE_A 0
        #define MAT_BASE_B 1
        #define MAT_BASE_C 2
        #define MAT_WING_A 3
        #define MAT_WING_B 4

        float2 dHexagon(float3 pos, float blooming)
        {
            float3 p1 = pos;

            // float rate = _ChangeRate;
            float rate = saturate(blooming);

            // 土台
            p1.xz = foldRotate(p1.xz, 6);
            float2 res = float2(sdBox(p1, float3(_HexagonRadians, 1, _HexagonRadians)), MAT_BASE_A);

            // 土台のギザギザ
            float3 p2 = p1;
            p2.z = opRepRange(p2.z, 0.1, _HexagonRadians);
            p2.z -= 0.2 * abs(p2.x);
            p2.y += p1.z * 0.1 * rate;
            res = opU(res, float2(sdBox(p2, float3(_HexagonRadians * 0.2, 1, 0.02)), MAT_BASE_B));

            // 支柱
            float3 p3 = p1;
            p3.y += rate;
            res = opU(res, float2(sdBox(p3, float3(0.02, remapS(rate, 0.0, 0.2, 0, 1), 0.1)), MAT_BASE_C));

            float3 p4 = p1;
            
            // 羽
            p4.y += _WingASize.w;
            rot(p4.yz, remapS(rate, 0.5, 1, TAU / 4, _WingARot));
            res = opU(res, float2(sdBox(p4, _WingASize.xyz * remapS(rate, 0.3, 0.6, 0, 1)), MAT_WING_A));

            // 羽のギザギザ
            p4.y += _WingBSize.w;
            p4.z -= 0.4 * abs(p4.x);
            p4.z = opRepRange(p4.z, _WingBSize.z * 3, _WingASize.z);
            res = opU(res, float2(sdBox(p4, _WingBSize.xyz), MAT_WING_B));

            return res;
        }

        float calcBlooming(float z)
        {
            float pitch = _HexagonRadians + _HexagonPadding * 0.5;
            float thresholdZ = _ShipPosition.z / pitch + _BloomingThresholdZ;
            return saturate((thresholdZ - z) / 40);
        }

        float3 dHexagons(float3 pos)
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

            float3 res = float3(dHexagon(p1, calcBlooming(pi1.y)), pi1.y);
            res = opU(res, float3(dHexagon(p2, calcBlooming(pi2.y)), pi2.y));

            return res;
        }

        inline float DistanceFunction(float3 pos)
        {
            float2 res = dHexagons(pos);
            return res.x;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 p = ray.endPos;
            float3 res = dHexagons(p);

            float waveAxis = p.z;
            float beat = fmod(_Beat, 4);
            
            if (_TimelineTime < 84 || _TimelineTime > 90 || beat < 1)
            {
                waveAxis = p.z;
            }
            else if (beat < 2)
            {
                waveAxis = p.x;
            }
            else if (beat < 3)
            {
                waveAxis = -p.z;
            }
            else
            {
                waveAxis = p.x + p.z;
            }

            float wave = saturate(cos(_Beat * TAU - Mod(0.1 * waveAxis, TAU)));
            wave += _AudioSpectrumLevels[0] * 0.1;

            float edge = calcEdge(ray.endPos, 0.03);
            o.Emission += _EmissionColorEdge * edge * wave;

            float voro = voronoi(ray.endPos.xz) + voronoi(ray.endPos.xz * 2.0);
            o.Emission += _EmissionColorVoronoi * voro * wave;

            if (res.z < floor(_ChangeThresholdZ + _ShipPosition.z))
            {
                // emissionColor = hsvToRgb(float3(res.y * 0.1, 1, 1));
                o.Albedo = fixed3(1, 1, 1) * 0.7;
            }

            if (res.y == MAT_WING_B)
            {
                o.Emission = float3(3, 0.2, 0.2);
                // o.Albedo = fixed3(1, 0.2, 0.2);
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
    }

    Fallback Off

    CustomEditor "uShaderTemplate.MaterialEditor"
}