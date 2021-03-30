#define TAU 6.28318530718

float _Beat;
float _AudioSpectrumLevelLength;
float _AudioSpectrumLevels[32];
float _TimelineTime;

float3 _ShipPosition;

float2 opU(float2 d1, float2 d2)
{
    return d1.x < d2.x ? d1: d2;
}

float2 opS(float2 d1, float2 d2)
{
    return - d1.x > d2.x ? float2(-d1.x, d1.y): d2;
}

float3 opU(float3 d1, float3 d2)
{
    return d1.x < d2.x ? d1: d2;
}

float3 opS(float3 d1, float3 d2)
{
    return - d1.x > d2.x ? float3(-d1.x, d1.yz): d2;
}

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCappedCylinder(float3 p, float h, float r)
{
    float2 d = abs(float2(length(p.xz), p.y)) - float2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdCylinder(float3 p, float3 c)
{
    return length(p.xz - c.xy) - c.z;
}

float2x2 rotate(in float a)
{
    float s = sin(a), c = cos(a);
    return float2x2(c, s, -s, c);
}

void rot(inout float2 p, float a)
{
    p = mul(rotate(a), p);
}

// https://www.shadertoy.com/view/Mlf3Wj
float2 foldRotate(in float2 p, in float s)
{
    float a = PI / s - atan2(p.x, p.y);
    float n = TAU / s;
    a = floor(a / n) * n;
    p = mul(rotate(a), p);
    return p;
}

float opRepLim(float p, float c, float l)
{
    return p - c * clamp(round(p / c), -l, l);
}

float opRepRange(float p, float c, float l)
{
    return p - c * clamp(round(p / c), -l / c, l / c);
}

float remap(float s, float a1, float a2, float b1, float b2)
{
    return b1 + (s - a1) * (b2 - b1) / (a2 - a1);
}

// remap saturate
float remapS(float s, float a1, float a2, float b1, float b2)
{
    return b1 + saturate((s - a1) / (a2 - a1)) * (b2 - b1);
}

float remap(float s, float a1, float a2)
{
    return(s - a1) / (a2 - a1);
}

float3 hsvToRgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
// https://www.shadertoy.com/view/4djSRW
// Trying to find a Hash function that is the same on ALL systens
// and doesn't rely on trigonometry functions that change accuracy
// depending on GPU.
// New one on the left, sine function on the right.
// It appears to be the same speed, but I suppose that depends.
// * Note. It still goes wrong eventually!
// * Try full-screen paused to see details.
// *** Change these to suit your range of random numbers..
// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 float3(.1031, .1030, .0973)
#define HASHSCALE4 float4(1031, .1030, .0973, .1099)
// For smaller input rangers like audio tick or 0-1 UVs use these...
//#define HASHSCALE3 443.8975
//#define HASHSCALE3 float3(443.897, 441.423, 437.195)
//#define HASHSCALE3 float3(443.897, 441.423, 437.195, 444.129)
//  1 out, 1 in...
float hash11(float p)
{
    float3 p3 = frac(p.xxx * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}
//  1 out, 2 in...
float hash12(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}
//  1 out, 3 in...
float hash13(float3 p3)
{
    p3 = frac(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}
//  2 out, 1 in...
float2 hash21(float p)
{
    float3 p3 = frac(p.xxx * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx + p3.yz) * p3.zy);
}
///  2 out, 2 in...
float2 hash22(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx + p3.yz) * p3.zy);
}
///  2 out, 3 in...
float2 hash23(float3 p3)
{
    p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx + p3.yz) * p3.zy);
}
//  3 out, 1 in...
float3 hash31(float p)
{
    float3 p3 = frac(p.xxx * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}
///  3 out, 2 in...
float3 hash32(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz + 19.19);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}
///  3 out, 3 in...
float3 hash33(float3 p3)
{
    p3 = frac(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz + 19.19);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
}
// 4 out, 1 in...
float4 hash41(float p)
{
    float4 p4 = frac(p.xxxx * HASHSCALE4);
    p4 += dot(p4, p4.wzxy + 19.19);
    return frac((p4.xxyz + p4.yzzw) * p4.zywx);
}
// 4 out, 2 in...
float4 hash42(float2 p)
{
    float4 p4 = frac(float4(p.xyxy) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy + 19.19);
    return frac((p4.xxyz + p4.yzzw) * p4.zywx);
}
// 4 out, 3 in...
float4 hash43(float3 p)
{
    float4 p4 = frac(float4(p.xyzx) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy + 19.19);
    return frac((p4.xxyz + p4.yzzw) * p4.zywx);
}
// 4 out, 4 in...
float4 hash44(float4 p4)
{
    p4 = frac(p4 * HASHSCALE4);
    p4 += dot(p4, p4.wzxy + 19.19);
    return frac((p4.xxyz + p4.yzzw) * p4.zywx);
    //return frac(float4((p4.x + p4.y)*p4.z, (p4.x + p4.z)*p4.y, (p4.y + p4.z)*p4.w, (p4.z + p4.w)*p4.x));
}

float lpnorm(float2 p, float n)
{
    float2 t = pow(abs(p), float2(n, n));
    return pow(t.x + t.y, 1. / n);
}

// マンハッタン距離によるボロノイ
// https://qiita.com/7CIT/items/4126d23ffb1b28b80f27
// https://neort.io/art/br0fmis3p9f48fkiuk50
float voronoi(float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);
    float2 res = float2(8, 8);

    for (int x = -1; x <= 1; x++)
    {
        for (int y = -1; y <= 1; y++)
        {
            float2 n = float2(x, y);
            float2 np = hash22(i + n);
            float2 p = n + np - f;

            // マンハッタン距離
            float d = abs(p.x) + abs(p.y);
            // float d = length(p);
            // float d = lpnorm(p, -3);

            if (d < res.x)
            {
                res.y = res.x;
                res.x = d;
            }
            else if (d < res.y)
            {
                res.y = d;
            }
        }
    }

    float c = res.y - res.x;
    c = sqrt(c);
    c = smoothstep(0.3, 0.0, c);
    return c;
}

inline float DistanceFunction(float3 pos);

#define map DistanceFunction

// https://www.shadertoy.com/view/lttGDn
float calcEdge(float3 p, float width)
{
    float edge = 0.0;
    float2 e = float2(width, 0);

    // Take some distance function measurements from either side of the hit point on all three axes.
    float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
    float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
    float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    float d = map(p) * 2.;	// The hit point itself - Doubled to cut down on calculations. See below.

    // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
    // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
    // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface
    // curves that register a discernible difference.
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.

    // Once you have an edge value, it needs to normalized, and smoothed if possible. How you
    // do that is up to you. This is what I came up with for now, but I might tweak it later.
    edge = smoothstep(0., 1., sqrt(edge / e.x * 2.));

    // Return the normal.
    // Standard, normalized gradient mearsurement.
    return edge;
}
