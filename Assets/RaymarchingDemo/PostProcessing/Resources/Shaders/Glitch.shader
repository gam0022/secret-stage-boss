Shader "Hidden/Custom/Glitch"
{
    HLSLINCLUDE
    // StdLib.hlsl holds pre-configured vertex shaders (VertDefault), varying structs (VaryingsDefault), and most of the data you need to write common effects.
    #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
    
    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    
    // 定数
    #define TAU 6.28318530718
    
    // グローバルなプロパティ
    float _Beat;
    float _AudioSpectrumLevelLength;
    float _AudioSpectrumLevels[32];
    
    // シェーダーのプロパティ
    float4 _FlashColor;
    float _FlashIntensity;
    float4 _BlendColor;
    
    float4 Frag(VaryingsDefault i): SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
        
        // 点滅
        color.rgb = lerp(color.rgb, _FlashColor.rgb, _FlashColor.a * saturate(_FlashIntensity * _AudioSpectrumLevels[0]));
        
        // アルファブレンド
        color.rgb = lerp(color.rgb, _BlendColor.rgb, _BlendColor.a);
        
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