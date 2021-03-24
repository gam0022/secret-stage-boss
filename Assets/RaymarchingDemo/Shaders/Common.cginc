#define TAU 6.28318530718

float _Beat;
float _AudioSpectrumLevelLength;
float _AudioSpectrumLevels[32];

float2 opU(float2 d1, float2 d2)
{
    return(d1.x < d2.x) ? d1: d2;
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

float opSubtraction(float d1, float d2)
{
    return max(-d1, d2);
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

float random(float2 st)
{
    return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
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
            float2 np = float2(random(i + n), random(i + n + float2(12.56, 64.66)));
            float2 p = n + np - f;

            // マンハッタン距離
            float d = abs(p.x) + abs(p.y);
            // float d = length(p);
            // float d = lpnorm(p, sin(_Beat) * 3);

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