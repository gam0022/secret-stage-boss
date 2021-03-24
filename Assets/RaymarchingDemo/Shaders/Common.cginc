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