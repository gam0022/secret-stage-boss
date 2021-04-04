Shader "Hidden/Custom/Glitch"
{
    HLSLINCLUDE
    // StdLib.hlsl holds pre-configured vertex shaders (VertDefault), varying structs (VaryingsDefault), and most of the data you need to write common effects.
    #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
    #include "Assets/SecretStageBoss/Shaders/Common.cginc"
    
    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    
    // シェーダーのプロパティ
    float _GlitchUvIntensity;
    float _DistortionIntensity;
    float _LensDistortionIntensity;
    float _RgbShiftIntensity;
    float _NoiseIntensity;
    float _Belt;
    
    float4 _FlashColor;
    float _FlashIntensity;
    float4 _BlendColor;
    
    float4 Frag(VaryingsDefault i): SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

        float2 uv = i.texcoord;
        float2 uvN = _ScreenParams.xy * (uv * 2 - 1) / min(_ScreenParams.x, _ScreenParams.y);

        // grid hash
        float2 hash = hash23(float3(floor(float2(uv.x * 32.0, uv.y * 32.0)), _Beat));

        // uv shift
        uv += _GlitchUvIntensity * _AudioSpectrumLevels[0] * (1.0 - 2.0 * hash);

        // x distortion
        uv.x += _DistortionIntensity * sin(uv.y * 4.0 + _Beat);

        // lens distortion
        float l = length(uvN);
        uv += -_LensDistortionIntensity * uvN * cos(l * 0.5);

        // lens blur
        // 他のエフェクトとの併用が面倒なので没に
        /*
        int sample = 10;
        for (int j = 0; j < sample; j++)
        {
            color.rgb += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + normalize(uvN) * 0.001 * l * j) / sample;
        }
        */

        // rgb shift
        float angle = hash.x * TAU;
        float2 offset = _RgbShiftIntensity * _AudioSpectrumLevels[0] * float2(cos(angle), sin(angle));
        float4 cr = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - offset);
        float4 cg = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        float4 cb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + offset);
        color.rgb = half3(cr.r, cg.g, cb.b);

        // noise
        color.rgb += _NoiseIntensity * _AudioSpectrumLevels[0] * hash12(float2(i.texcoord.y * 20.0, _Beat));
        
        // 点滅
        color.rgb = lerp(color.rgb, _FlashColor.rgb, _FlashColor.a * saturate(_FlashIntensity * _AudioSpectrumLevels[0]));
        
        // アルファブレンド
        color.rgb = lerp(color.rgb, _BlendColor.rgb, _BlendColor.a);

        // 上下の黒帯
        color.rgb = lerp(color.rgb, float3(0, 0, 0), 1 - abs(uvN.y) < _Belt);
        
        return color;
    }
    ENDHLSL

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag
            ENDHLSL

        }
    }
}