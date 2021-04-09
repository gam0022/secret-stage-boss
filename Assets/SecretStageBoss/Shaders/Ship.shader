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
        [HDR] _EmissionColorB ("Emission Color B", Color) = (1, 1, 1, 1)
        _Gantz ("Gantz", Range(0, 1)) = 0

        [Header(Damage)]
        _DamageAnimationSpeed ("Damage Animation Speed", Float) = 1
        _DamageBlinkSpeed ("Damage Blink Speed", Float) = 1
        [HDR] _EmissionColorDamageA ("Emission Color Damage A", Color) = (1, 1, 1, 1)
        [HDR] _EmissionColorDamageB ("Emission Color Damage B", Color) = (1, 1, 1, 1)

        [Header(BarrierPrepare)]
        _BarrierPrepare ("Barrier Prepare", Range(0, 4)) = 0
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
        float _Gantz;

        float _DamageAnimationSpeed;
        float _DamageBlinkSpeed;
        float4 _EmissionColorDamageA;
        float4 _EmissionColorDamageB;

        float _BarrierPrepare;

        #define MAT_ENGINE_BODY_A   1
        #define MAT_ENGINE_DETAIL_A 2
        #define MAT_ENGINE_DETAIL_B 3
        #define MAT_ENGINE_CORE     4
        #define MAT_ENGINE_FAN      5

        #define MAT_BODY_A          6
        #define MAT_JOINT_A         7

        float2 mEngine(float3 pos)
        {
            float3 p = pos;
            float r = cos((pos.y + 0.3) * 1.0) * 0.3;

            // 細かい枠
            p.xz = foldRotate(pos.xz, 12);
            p.y -= 0.3 * abs(p.x);
            p.y = opRepRange(p.y, 0.03, 0.7);
            p.z -= r + 0.1;
            float2 res = float2(sdBox(p, float3(0.1, 0.01, 0.02)), MAT_ENGINE_BODY_A);

            // 太い枠・縦
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.z -= r + 0.1;
            res = opU(res, float2(sdBox(p, float3(0.1 + 0.04 * (p.y - 1.0), 0.75, 0.05)), MAT_ENGINE_DETAIL_A));

            // 太い枠・横
            p = pos;
            p.xz = foldRotate(pos.xz, 6);
            p.y = opRepRange(p.y, 0.24, 0.7);
            p.z -= r + 0.15;
            res = opU(res, float2(sdBox(p, float3(0.3, 0.03, 0.02)), MAT_ENGINE_DETAIL_B));

            // 芯線
            res = opU(res, float2(sdCappedCylinder(pos, cos(abs(1.9 * pos.y)) * 0.2, 0.9), MAT_ENGINE_CORE));

            // コンプレッサー・タービン
            p = pos;
            p.y = opRepRange(p.y, 0.15, 0.7);
            p.xz = mul(rotate(_Beat), p.xz);
            p.xz = foldRotate(p.xz, 12 * 2);
            p.z -= 0.18;
            p.xy = mul(rotate(0.3 + 2 * p.z), p.xy);
            float dFan = sdBox(p, float3(0.02, 0.002, 0.1)) * 0.7;
            res = opU(res, float2(dFan, MAT_ENGINE_FAN));

            return res;
        }

        float2 mBody(float3 pos)
        {
            float4 p = float4(pos, 1);

            float bodyLength = 1.7;
            float bodyWidth = 0.3 * abs(cos((p.y + bodyLength) * TAU / bodyLength / 8));
            bodyWidth += saturate(sin(p.y * TAU / bodyLength / 4)) * _BarrierPrepare;

            p.y -= 0.5 * abs(p.x);
            p.z -= bodyWidth + 0.01;
            p.y = opRepRange(p.y, 0.3, bodyLength);

            for (int i = 0; i < 5; i++)
            {
                p.xy = abs(p.xy);
                p.xy = mul(rotate(0.3), p.xy);
                p.xz = mul(rotate(-0.1), p.xz);
                p *= 0.9;
            }

            float2 res = float2(sdBox(p, float3(bodyWidth * 0.3, bodyLength * 0.3, bodyWidth * 0.1)), MAT_BODY_A) / p.w;
            res = opU(res, float2(sdBox(p, float3(bodyWidth + 0.06, 0.006, 0.006)), MAT_ENGINE_DETAIL_A)) / p.w;

            return res;
        }

        float2 mShip(float3 pos)
        {
            float3 p = pos;

            p.xz = foldRotate(p.xz, 3);

            // エンジン
            float3 p1 = p;
            p1.z -= 0.9;
            p1.y -= -1.1;
            float2 res = mEngine(p1);

            // ジョイント
            float3 p2 = p;
            p2.y -= -1.4;
            p2.xz = abs(p2.xz) - 0.1;
            float dJoint = sdBox(p2, float3(0.03, 0.03, 0.6));
            res = opU(res, float2(dJoint, MAT_JOINT_A));

            // Body
            res = opU(res, mBody(p));

            // Gantz
            float3 size = GetScale() * 0.5;
            size.xz *= 1.1;
            res = opS(float2(sdBox(p - float3(0, 2 * size.y * _Gantz, 0), size), res.y), res);

            return res;
        }

        inline float DistanceFunction(float3 pos)
        {
            float2 res = mShip(pos);
            return res.x;
        }
        // @endblock

        // @block PostEffect
        inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
        {
            float3 scale = GetScale();
            float3 p = ToLocal(ray.endPos) * scale;
            float2 res = mShip(p);

            if (res.y >= MAT_ENGINE_BODY_A && res.y <= MAT_ENGINE_FAN)
            {
                // 中身だけ光らせる
                float3 p1 = p;
                p1.xz = foldRotate(p.xz, 3);
                p1.z -= 0.9;
                p1.y -= -1.1;
                float l = length(p1.xz);
                float r = cos((p1.y + 0.3) * 1.0) * 0.3;

                if (l < r + 0.1)
                {
                    o.Emission = _EmissionColor * (0.2 + 30 * _AudioSpectrumLevels[1]);
                }

                // 一部だけ光らせる
                if (res.y == MAT_ENGINE_DETAIL_A)
                {
                    o.Emission = _EmissionColorB * 20 * _AudioSpectrumLevels[0];
                }
            }
            else
            {
                o.Smoothness = 0.95;
                o.Metallic = 1;
                o.Occlusion = 0;
                o.Albedo = half3(1, 1, 1);
            }

            float gantzEmissiveY = (_Gantz - 0.5) * scale.y;
            float _GantzWidth = 0.01;
            if (p.y >= gantzEmissiveY - _GantzWidth && p.y <= gantzEmissiveY + _GantzWidth)
            {
                o.Emission = _EmissionColorB;
            }

            if (_ShipDamageBeat > 0)
            {
                o.Emission += exp(-_ShipDamageBeat * _DamageAnimationSpeed) * lerp(_EmissionColorDamageA, _EmissionColorDamageB, 0.5 + 0.5 * cos(_ShipDamageBeat * _DamageBlinkSpeed * TAU));
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