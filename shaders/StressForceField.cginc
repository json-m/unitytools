#ifndef STRESS_FORCEFIELD_INCLUDED
#define STRESS_FORCEFIELD_INCLUDED

// Properties for force field
float4 _EnergyColor;
float _NoiseScale;
float _NoiseSpeed;
float _DistortionStrength;
float _PatternScale;
float _PulseSpeed;
float _EdgeSharpness;
float _Transparency;
sampler2D _BackgroundTexture;

// Hash function for improved noise
float2 hash33(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.xx + p3.yz) * p3.zy);
}

// 2D Noise
float noise2D(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    float a = dot(hash33(i + float2(0,0)), f - float2(0,0));
    float b = dot(hash33(i + float2(1,0)), f - float2(1,0));
    float c = dot(hash33(i + float2(0,1)), f - float2(0,1));
    float d = dot(hash33(i + float2(1,1)), f - float2(1,1));
    
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y) + 0.5;
}

// Hexagonal pattern
float hexagonalGrid(float2 pos)
{
    float2 r = float2(1.0, 1.73);
    float2 h = r * 0.5;
    
    float2 a = fmod(pos, r) - h;
    float2 b = fmod(pos - h, r) - h;
    
    return min(dot(a, a), dot(b, b));
}

[UNITY_domain("tri")]
v2f domain(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    v2f o;
    
    float4 vertexOS = 
        patch[0].vertex * barycentricCoordinates.x +
        patch[1].vertex * barycentricCoordinates.y +
        patch[2].vertex * barycentricCoordinates.z;
        
    float2 uv = 
        patch[0].uv * barycentricCoordinates.x +
        patch[1].uv * barycentricCoordinates.y +
        patch[2].uv * barycentricCoordinates.z;
        
    float3 normal = normalize(
        patch[0].normal * barycentricCoordinates.x +
        patch[1].normal * barycentricCoordinates.y +
        patch[2].normal * barycentricCoordinates.z);
        
    float4 tangent = 
        patch[0].tangent * barycentricCoordinates.x +
        patch[1].tangent * barycentricCoordinates.y +
        patch[2].tangent * barycentricCoordinates.z;

    float4 color = 
        patch[0].color * barycentricCoordinates.x +
        patch[1].color * barycentricCoordinates.y +
        patch[2].color * barycentricCoordinates.z;

    float3 worldPos = mul(unity_ObjectToWorld, vertexOS).xyz;
    float distanceFromCamera = distance(_WorldSpaceCameraPos, worldPos);

    o.vertex = UnityObjectToClipPos(vertexOS);
    o.uv = TRANSFORM_TEX(uv, _MainTex);
    o.worldPos = worldPos;
    o.normal = UnityObjectToWorldNormal(normal);
    o.tangent = tangent;
    o.screenPos = ComputeGrabScreenPos(o.vertex);
    o.localPos = vertexOS;
    o.color = color;
    o.distanceFromCamera = distanceFromCamera;
    o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

    return o;
}

fixed4 fragForceField(v2f i) : SV_Target
{
    float distanceFromBoundary = abs(i.distanceFromCamera - _MaxDistance);
        
    float time = _Time.y * _NoiseSpeed;
    
    // Create layered noise
    float2 noiseUV = i.uv * _NoiseScale;
    float noise1 = noise2D(noiseUV + time);
    float noise2 = noise2D(noiseUV * 2.0 - time * 1.3);
    float noise3 = noise2D(noiseUV * 4.0 + time * 0.7);
    float finalNoise = (noise1 * 0.5 + noise2 * 0.3 + noise3 * 0.2);

    // Create hexagonal pattern
    float2 pos = i.uv * _PatternScale;
    pos.x *= 1.15470; // Hexagonal adjustment
    float hexPattern = hexagonalGrid(pos);
    hexPattern = smoothstep(0.05, 0.1, hexPattern);

    // Pulse effect
    float pulse = sin(time * _PulseSpeed) * 0.5 + 0.5;
    
    // Fresnel effect
    float fresnel = pow(1.0 - saturate(dot(i.normal, i.viewDir)), _EdgeSharpness);
    
    // Calculate distortion - always apply it
    float2 offset = finalNoise * _DistortionStrength;
    float2 grabUV = i.screenPos.xy / i.screenPos.w;
    float4 backgroundColor = tex2D(_BackgroundTexture, grabUV + offset);

    // Combine effects
    float pattern = lerp(1.0, hexPattern, 0.3) * finalNoise;
    float energy = pattern * pulse * fresnel;
    
    // Final color
    float4 energyGlow = _EnergyColor * energy;
    float alpha = energy * _Transparency;
    
    return lerp(backgroundColor, energyGlow, alpha);
}

#endif // STRESS_FORCEFIELD_INCLUDED
