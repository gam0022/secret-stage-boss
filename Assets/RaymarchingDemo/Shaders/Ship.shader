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
        _MinDistance ("Minimum Distance", Range(0.001, 0.1)) = 0.001
        _DistanceMultiplier ("Distance Multiplier", Range(0.001, 2.0)) = 1.0
        _ShadowLoop ("Shadow Loop", Range(1, 100)) = 10
        _ShadowMinDistance ("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.005
        _ShadowExtraBias ("Shadow Extra Bias", Range(0.0, 0.1)) = 0.01
        [PowerSlider(10.0)] _NormalDelta ("NormalDelta", Range(0.00001, 0.1)) = 0.0001

        // @block Properties
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
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

        float dEngine(float3 pos)
        {
            float3 p = pos;
            float r = cos((pos.y + 0.3) * 1.0) * 0.3;

            // 細かい枠
            p.xz = foldRotate(pos.xz, 12);
            p.y -= 0.3 * abs(p.x);
            p.y = opRepRange(p.y, 0.03, 0.7);
            p.z -= r + 0.1;
            float d = sdBox(p, float3(0.1, 0.01, 0.02));

            // 太い枠・縦
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.z -= r + 0.1;
            d = min(d, sdBox(p, float3(0.1 + 0.04 * (p.y - 1.0), 0.75, 0.05)));

            // 太い枠・横
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.y = opRepRange(p.y, 0.24, 0.7);
            p.z -= r + 0.15;
            d = min(d, sdBox(p, float3(0.3, 0.03, 0.02)));

            // 芯線
            d = min(d, sdCappedCylinder(pos, cos(abs(1.9 * pos.y)) * 0.2, 0.9));

            // コンプレッサー・タービン
            p = pos;
            p.y = opRepRange(p.y, 0.15, 0.7);
            p.xz = mul(rotate(_Beat), p.xz);
            p.xz = foldRotate(p.xz, 12 * 2);
            p.z -= 0.18;
            p.xy = mul(rotate(0.3 + 2 * p.z), p.xy);
            float dFan = sdBox(p, float3(0.02, 0.002, 0.1)) * 0.7;
            d = min(d, dFan);

            return d;
        }

        float dEngines(float3 pos)
        {
            float3 p1 = pos;
            p1.z -= 0.9;
            p1.y -= -1.1;
            return dEngine(p1);
        }

        inline float DistanceFunction(float3 pos)
        {
            float3 p = pos;

            p.xz = foldRotate(p.xz, 3);

            // エンジン
            float d = dEngines(p);

            // ジョイント
            float3 p2 = p;
            p2.y -= -1.4;
            float dJoint = sdBox(p2, float3(0.1, 0.1, 0.6));
            d = min(d, dJoint);

            // コクピット
            float3 p3 = p;
            float bodyLength = 1.7;
            float bodyWidth = 0.3 * abs(cos((p.y + bodyLength) * TAU / bodyLength / 8));
            float dBody = sdBox(p3, float3(bodyWidth, bodyLength, bodyWidth));
            d = min(d, dBody);

            return d;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 p = ToLocal(ray.endPos) * GetScale();

            p.xz = foldRotate(p.xz, 3);
            
            if (dEngines(p) < 0.1)
            {
                o.Emission = _EmissionColor;
            }
            else
            {
                //o.Smoothness = 0.95;
                //o.Metallic = 1;
                //o.Occlusion = 0;
                //o.Albedo = half3(1, 1, 1);
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