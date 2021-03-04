Shader "Unlit/AudioSpectrumVisualizer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            float _AudioSpectrumLevelLength;
            float _AudioSpectrumLevels[32];
            
            half4 frag(v2f i): SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                
                int idx = floor(i.uv.x * _AudioSpectrumLevelLength);
                float level = _AudioSpectrumLevels[idx];
                float maxVal = 1;
                col = i.uv.y * maxVal < level ? half4(1.0, 1.0, 1.0, 1.0): half4(0, 0, 0, 0);
                
                return col;
            }
            ENDCG
            
        }
    }
}
