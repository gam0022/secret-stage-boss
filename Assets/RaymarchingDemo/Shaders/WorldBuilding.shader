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
        _Height ("Height", Float) = 10
        _EmissionIntensity ("Emission Intensity", Range(0, 1)) = 1

        [Header(BeatWave)]
        _WaveSpeed ("Wave Speed", Float) = 1
        _WaveFrequency ("Wave Frequency", Float) = 0.1

        [Header(Wava1)]
        _Wave1ThresholdZ ("Wave 1 Threshold Z", Float) = 0
        [HDR] _EmissionColorA ("Emission Color A", Color) = (1, 1, 1, 1)
        [HDR] _EmissionColorB ("Emission Color B", Color) = (1, 1, 1, 1)

        [Header(Wave2)]
        _Wave2ThresholdZ ("Change Threshold Z", Float) = 0
        _ChangeAlbedo ("Change Albedo", Color) = (0.6, 0.6, 0.6, 1)

        [Header(Wave3)]
        _Wave3ThresholdZ ("Wave 3 Threshold Z", Float) = 0
        _Wave3Slope ("Wave 3 Slope", Float) = 5
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
        float _Height;
        float _EmissionIntensity;

        float _WaveSpeed;
        float _WaveFrequency;

        float4 _EmissionColorA;
        float4 _EmissionColorB;
        float _Wave1ThresholdZ;

        float _Wave2ThresholdZ;
        float4 _ChangeAlbedo;

        float _Wave3ThresholdZ;
        float _Wave3Slope;

        #define MAT_BASE_A 0

        float2 dHexagon(float3 pos, float h)
        {
            float3 p1 = pos;

            // 土台
            p1.xz = foldRotate(p1.xz, 6);
            float2 res = float2(sdBox(p1, float3(_HexagonRadians, h, _HexagonRadians)), MAT_BASE_A);

            return res;
        }

        float3 dHexagons(float3 pos)
        {
            float3 p = pos;

            float pitch = _HexagonRadians * 2 + _HexagonPadding;
            float sqrt3_div_2 = 0.8660254037844386467637231707529361834714026269051903140279034897;
            float3 offset = float3(pitch * sqrt3_div_2, 0, pitch * 0.5);
            float3 loop = float3(offset.x * 2, _Height, offset.z * 2);
            
            float3 p1 = p;
            float3 p2 = p + offset;

            // calculate indices
            float2 pi1 = floor(p1 / loop).xz;
            float2 pi2 = floor(p2 / loop).xz;
            pi1.y = pi1.y * 2;
            pi2.y = pi2.y * 2 + 1;

            pitch *= 0.5;

            float2 h12 = float2(1, 1);
            float hmax = 8;
            float z = floor(_Wave3Slope + _Wave3ThresholdZ + _ShipPosition.z / pitch);
            h12 += hmax * saturate((float2(z, z) - float2(pi1.y, pi2.y)) / _Wave3Slope);

            p1.y += 0.5 * sin(10 * Rand(pi1) + 0.1 * TAU * _Beat);
            p2.y += 0.5 * sin(10 * Rand(pi2) + 0.1 * TAU * _Beat);
            p1.xz = Repeat(p1.xz, loop.xz);
            p2.xz = Repeat(p2.xz, loop.xz);
            p1.y = abs(p1.y) - 0.5 * loop.y;
            p2.y = abs(p2.y) - 0.5 * loop.y;

            float3 res = float3(dHexagon(p1, h12.x), pi1.y);
            res = opU(res, float3(dHexagon(p2, h12.y), pi2.y));

            return res;
        }

        inline float DistanceFunction(float3 pos)
        {
            float2 res = dHexagons(pos);
            return res.x;
        }
        // @endblock

        float calcWave(float z, float s)
        {
            return saturate(cos(_WaveSpeed * _Beat * TAU - Mod(_WaveFrequency * z * s + 0.04 * s, TAU)));
        }

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 p = ray.endPos;
            float3 res = dHexagons(p);

            float4 emissionColor = _EmissionColorA;
            float pitch = _HexagonRadians + _HexagonPadding * 0.5;

            // Wave1: エミッションが赤から青に変化
            if (res.z < floor(_Wave1ThresholdZ + _ShipPosition.z / pitch))
            {
                emissionColor = _EmissionColorB;
            }

            // 全体のエミッション調整用（シーンのコントラスト調整用やnagative spaceを考慮）
            emissionColor.rgb *= _EmissionIntensity;

            // Wave2: 色が黒から白に変化
            if (res.z < floor(_Wave2ThresholdZ + _ShipPosition.z / pitch))
            {
                o.Albedo = _ChangeAlbedo;
            }

            // Wave3: 天井と床が落ちて潰される攻撃
            if (res.z < floor(_Wave3ThresholdZ + _Wave3Slope + _ShipPosition.z / pitch))
            {
                o.Albedo = hsvToRgb(float3(p.y * frac(_Beat) + _Beat, 1, 1));
                o.Smoothness = 0.95;
                o.Metallic = 0.8;
            }

            float edge = calcEdge(ray.endPos, 0.03);
            o.Emission += emissionColor * edge;

            float voro = voronoi(ray.endPos.xz) * calcWave(p.z, 1) + voronoi(ray.endPos.xz * 0.5) * calcWave(p.z, 0.5);

            o.Emission += emissionColor * voro;
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