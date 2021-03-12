#define TAU 6.28318530718

float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
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