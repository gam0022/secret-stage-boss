Shader "Unlit/Barrier"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)

        [Header(Culling)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 2// Back
    }
    SubShader
    {
        Tags { "IgnoreProjector" = "True" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha One
            ZWrite Off
            Cull [_CullMode]

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Common.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float4 color: COLOR;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float4 color: COLOR;
                float4 local: LOCAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _EmissionColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.color = v.color;
                o.local = v.vertex;
                return o;
            }

            float4 frag(v2f i): SV_Target
            {
                // sample the texture
                float4 col = float4(0, 0, 0, 0);//tex2D(_MainTex, i.uv);

                float scale = 4;
                float voro = voronoi(i.uv * scale) + voronoi(i.uv * scale * 2);
                col += _EmissionColor * voro;

                if (i.color.b > 0.8)
                {
                    col += _EmissionColor * 0.5 * (1 + cos(_Beat * TAU + TAU * 4 * (i.local.y + 0.5)));
                }

                // col.rgb *= _AudioSpectrumLevels[0] * 20;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG

        }
    }
}
