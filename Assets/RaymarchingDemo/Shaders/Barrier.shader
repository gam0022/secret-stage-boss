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
                float4 color: COLOR;
                float4 normal: NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float4 color: COLOR;
                float4 local: LOCAL;
                float3 worldPos: WORLD_POS;
                float3 worldNormal: WORLD_NORMAL;
                float2 uv: UV;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _EmissionColor;

            v2f vert(appdata v)
            {
                v2f o;

                rot(v.vertex.xz, _Beat * TAU / 16);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.local = v.vertex;

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float4 frag(v2f i): SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv) * 0;

                half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 reflDir = reflect(-worldViewDir, i.worldNormal);
                half4 refColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, 0);
                refColor.rgb = DecodeHDR(refColor, unity_SpecCube0_HDR);
                col.rgb += refColor.rgb * 0.2;

                float scale = 4;
                float voro = voronoi(i.uv * scale) + voronoi(i.uv * scale * 2);
                col.rgb += _EmissionColor.rgb * voro;

                if (i.color.b > 0.8)
                {
                    col.rgb += _EmissionColor.rgb * 0.5 * (1 + cos(_Beat * TAU + TAU * 4 * (i.local.y + 0.5)));
                }

                // col.rgb *= _AudioSpectrumLevels[0] * 20;
                col.a = _EmissionColor.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG

        }
    }
}
