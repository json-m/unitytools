// StressUtils.cginc
#ifndef STRESS_UTILS_INCLUDED
#define STRESS_UTILS_INCLUDED

// Shared variables
sampler2D _MainTex, _NoiseTex1, _NoiseTex2, _NoiseTex3, _NoiseTex4;
float4 _MainTex_ST;
float4 _Color;
float _MinDistance, _MaxDistance;
float _TessellationFactor, _TessellationPower;
float _TessMinDist, _TessMaxDist, _TessRampOffset;
float _ForceFieldIntensity, _ChromaticAberration;
float _DistortionSpeed, _RippleScale, _RippleIntensity;
float _BoundaryGlow, _StressLevel, _ComputeIntensity;
float _TextureScale, _BranchComplexity, _BranchThreshold;
int _MathIterations, _FractalDepth;
float _DerivativeStress, _CacheStress, _ThreadStress, _TextureStress;

#define BUFFER_SIZE 256

// Shared structures
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;
};

struct TessellationControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 color : COLOR;
};

struct TessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 worldPos : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float4 tangent : TEXCOORD4;
    float3 binormal : TEXCOORD5;
    float4 color : COLOR;
    float4 localPos : TEXCOORD6;
    float3 viewDir : TEXCOORD7;
    float distanceFromCamera : TEXCOORD8;
    float3 boundaryEffect : TEXCOORD9;
};

// Utility functions
float RemapTo01(float val, float rangeMin, float rangeMax)
{
    return saturate((val - rangeMin) / (rangeMax - rangeMin));
}

float2 getUVDeriv(float2 uv)
{
    float2 absDDX = abs(ddx(uv));
    float2 absDDY = abs(ddy(uv));
    float2 minDeriv = min(absDDX, absDDY);
    float2 maxDeriv = max(absDDX, absDDY);
    return lerp(minDeriv, maxDeriv, 0.333);
}

float hash11(float p)
{
    p = frac(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float2 hash22(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}

float3 hash33(float3 p)
{
    p = float3(dot(p,float3(127.1,311.7, 74.7)),
               dot(p,float3(269.5,183.3,246.1)),
               dot(p,float3(113.5,271.9,124.6)));
    return -1.0 + 2.0 * frac(sin(p)*43758.5453123);
}

// Tessellation shared functions
float GetTessellationFactor(float3 worldPos)
{
    float distanceToCamera = distance(worldPos, _WorldSpaceCameraPos);
    
    if (distanceToCamera > _MaxDistance)
        return 1;

    float factor = _TessellationFactor;
    float effectWidth = _MaxDistance - _MinDistance;
    float tessMinDist = _MinDistance + effectWidth * _TessRampOffset;
    float tessMaxDist = _MaxDistance - effectWidth * _TessRampOffset;
    
    float distanceFactor = 1.0 - saturate((distanceToCamera - tessMinDist) / 
                                        (tessMaxDist - tessMinDist));
    distanceFactor = pow(distanceFactor, _TessellationPower);
    
    float stressFactor = _StressLevel * 0.1;
    float finalFactor = factor * (1.0 + stressFactor);
    finalFactor *= (1.0 + distanceFactor * 0.8);
    
    float boundaryDist = abs(distanceToCamera - _MaxDistance);
    finalFactor *= (1.0 + boundaryDist * 0.5);
    
    return max(1, finalFactor);
}

TessellationControlPoint tessvert(appdata v)
{
    TessellationControlPoint p;
    p.vertex = v.vertex;
    p.uv = v.uv;
    p.normal = v.normal;
    p.tangent = v.tangent;
    p.color = v.color;
    return p;
}

TessellationFactors HSConstant(InputPatch<TessellationControlPoint, 3> patch)
{
    TessellationFactors f;
    
    float3 worldPos0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
    float3 worldPos1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
    float3 worldPos2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
    
    float tess0 = GetTessellationFactor(worldPos0);
    float tess1 = GetTessellationFactor(worldPos1);
    float tess2 = GetTessellationFactor(worldPos2);
    
    f.edge[0] = (tess1 + tess2) * 0.5;
    f.edge[1] = (tess2 + tess0) * 0.5;
    f.edge[2] = (tess0 + tess1) * 0.5;
    
    f.inside = (tess0 + tess1 + tess2) * 0.333333;
    
    return f;
}

[UNITY_domain("tri")]
[UNITY_partitioning("fractional_odd")]
[UNITY_outputtopology("triangle_cw")]
[UNITY_outputcontrolpoints(3)]
[UNITY_patchconstantfunc("HSConstant")]
TessellationControlPoint hull(InputPatch<TessellationControlPoint, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

#endif // STRESS_UTILS_INCLUDED
