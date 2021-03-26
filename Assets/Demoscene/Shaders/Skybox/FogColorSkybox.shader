Shader "Skybox/FogColorSkybox"
{
    Properties { }

    CGINCLUDE

    #include "UnityCG.cginc"

    struct appdata
    {
        float4 position: POSITION;
        float3 texcoord: TEXCOORD0;
    };

    struct v2f
    {
        float4 position: SV_POSITION;
        float3 texcoord: TEXCOORD0;
    };

    v2f vert(appdata v)
    {
        v2f o;
        o.position = UnityObjectToClipPos(v.position);
        o.texcoord = v.texcoord;
        return o;
    }

    half4 frag(v2f i): COLOR
    {
        return unity_FogColor;
    }
    
    ENDCG
    
    SubShader
    {
        Tags { "RenderType" = "Background" "Queue" = "Background" }
        Pass
        {
            ZWrite Off
            Cull Off
            Fog
            {
                Mode Off
            }
            CGPROGRAM
            
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
            
        }
    }
}
