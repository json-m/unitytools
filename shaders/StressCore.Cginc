#ifndef STRESS_CORE_INCLUDED
#define STRESS_CORE_INCLUDED

// Complex noise functions
float gradientNoise(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    float3 u = f * f * (3.0 - 2.0 * f);

    return lerp(
        lerp(lerp(dot(hash33(i + float3(0,0,0)), f - float3(0,0,0)),
                 dot(hash33(i + float3(1,0,0)), f - float3(1,0,0)), u.x),
             lerp(dot(hash33(i + float3(0,1,0)), f - float3(0,1,0)),
                 dot(hash33(i + float3(1,1,0)), f - float3(1,1,0)), u.x), u.y),
        lerp(lerp(dot(hash33(i + float3(0,0,1)), f - float3(0,0,1)),
                 dot(hash33(i + float3(1,0,1)), f - float3(1,0,1)), u.x),
             lerp(dot(hash33(i + float3(0,1,1)), f - float3(0,1,1)),
                 dot(hash33(i + float3(1,1,1)), f - float3(1,1,1)), u.x), u.y), u.z);
}

float3 fractalnoise(float3 p)
{
    float3 value = 0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < _FractalDepth; i++)
    {
        value += sin(p * frequency) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
        
        float3x3 rotMatrix = float3x3(
            cos(value.x), -sin(value.y), 0,
            sin(value.z), cos(value.x), -sin(value.y),
            0, sin(value.z), cos(value.x)
        );
        p = mul(rotMatrix, p);
    }
    return value;
}

// Displacement and stress functions
float3 voronoiDisplacement(float3 p)
{
    float3 result = 0;
    for(int i = 0; i < 3; i++)
    {
        float3 cell = floor(p);
        float3 local = frac(p);
        float minDist = 8.0;
        
        for(int z = -1; z <= 1; z++)
        for(int y = -1; y <= 1; y++)
        for(int x = -1; x <= 1; x++)
        {
            float3 offset = float3(x, y, z);
            float3 pos = offset + hash33(cell + offset) * 0.5;
            float dist = length(pos - local);
            minDist = min(minDist, dist);
        }
        
        result += sin(p * minDist);
        p *= 2.0;
    }
    return result * 0.3;
}

float3 displaceVertex(float3 pos, float3 normal, float time)
{
    float3 displacement = 0;
    
    for(int i = 0; i < 4; i++)
    {
        float scale = pow(2.0, float(i));
        float amplitude = pow(0.5, float(i));
        
        displacement += normal * fractalnoise(pos * scale + time) * amplitude;
        displacement += normal * voronoiDisplacement(pos * scale - time) * amplitude;
        
        float3 angle = sin(pos * scale + time);
        displacement += cross(normal, angle) * amplitude * 0.5;
    }
    
    return displacement;
}

// Domain shader implementation
[UNITY_domain("tri")]
v2f domain(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    v2f o;
    
    // Interpolate patch data
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

    // Calculate world position and apply displacement
    float3 worldPos = mul(unity_ObjectToWorld, vertexOS).xyz;
    float distanceFromCamera = distance(_WorldSpaceCameraPos, worldPos);
    float time = _Time.y;

    float3 displacement = 0;
    if(distanceFromCamera <= _MaxDistance)
    {
        float displaceIntensity = 1.0 - saturate((distanceFromCamera - _MinDistance) / 
                                                (_MaxDistance - _MinDistance));
        displaceIntensity = pow(displaceIntensity, 2.0);

        displacement += displaceVertex(worldPos, normal, time) * displaceIntensity;
        
        float boundaryDist = abs(distanceFromCamera - _MaxDistance);
        float boundaryDisplacement = sin(worldPos * _RippleScale + time * _DistortionSpeed);
        displacement += boundaryDisplacement * _RippleIntensity;

        float3 stressDisplacement = 0;
        for(int i = 0; i < min(10, _StressLevel); i++)
        {
            float3 noisePos = worldPos * pow(2.0, i) + time * (i + 1);
            stressDisplacement += sin(noisePos) * pow(0.5, i + 1);
        }
        displacement += stressDisplacement * _StressLevel * 0.1 * displaceIntensity;
    }

    vertexOS.xyz += mul(unity_WorldToObject, displacement);

    // Fill output structure
    o.vertex = UnityObjectToClipPos(vertexOS);
    o.uv = TRANSFORM_TEX(uv, _MainTex);
    o.worldPos = worldPos;
    o.normal = UnityObjectToWorldNormal(normal);
    o.tangent = tangent;
    o.binormal = cross(o.normal, tangent.xyz) * tangent.w;
    o.screenPos = ComputeScreenPos(o.vertex);
    o.localPos = vertexOS;
    o.color = color;
    o.distanceFromCamera = distanceFromCamera;
    o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);

    float boundaryDist = abs(distanceFromCamera - _MaxDistance);
    o.boundaryEffect = float3(
        1.0,
        1.0,
        sin(boundaryDist * 10 - time * 3)
    );

    return o;
}

// Fragment shader implementation
fixed4 frag(v2f i) : SV_Target
{
    float time = _Time.y;
    float distanceFromBoundary = abs(i.distanceFromCamera - _MaxDistance);
    
    // Get base color
    float4 finalColor = tex2D(_MainTex, i.uv) * _Color;

    // Calculate stress effect intensity based on distance
    float stressIntensity = 1.0;
    if (i.distanceFromCamera > _MaxDistance)
    {
        return finalColor;
    }
    else if (i.distanceFromCamera > _MinDistance)
    {
        stressIntensity = 1.0 - ((i.distanceFromCamera - _MinDistance) / (_MaxDistance - _MinDistance));
        stressIntensity = pow(stressIntensity, 2.0); // Smooth falloff
    }

    // Apply stress effects with proper intensity
    float3 stressColor = 0;
    
    // Derivative stress
    float2 dx = ddx(i.uv);
    float2 dy = ddy(i.uv);
    float3 derivColor = 0;
    
    for(int j = 0; j < 10; j++)
    {
        float2 offset = float2(dx.x * j + sin(time), dy.y * j + cos(time));
        derivColor += sin(i.worldPos * offset.xyx);
        derivColor += tex2D(_NoiseTex1, i.uv + offset).rgb;
    }
    stressColor += derivColor * _DerivativeStress;

    // Apply texture stress
    float2 stressUV = i.uv + float2(sin(time), cos(time)) * _TextureStress;
    float4 stressTex = tex2D(_NoiseTex1, stressUV) + 
                      tex2D(_NoiseTex2, stressUV * 1.5) +
                      tex2D(_NoiseTex3, stressUV * 2.0) +
                      tex2D(_NoiseTex4, stressUV * 2.5);
    stressColor += stressTex.rgb * _TextureStress;

    // Apply stress color with proper intensity
    finalColor.rgb = lerp(finalColor.rgb, stressColor, _StressLevel * 0.5 * stressIntensity);

    // Apply force field boundary effect
    if(distanceFromBoundary <= _MaxDistance * 0.2)
    {
        float3 forceField = sin(i.worldPos * _RippleScale + time * _DistortionSpeed);
        forceField *= _ForceFieldIntensity;
        finalColor.rgb += forceField;
        finalColor.a = max(finalColor.a, length(forceField));
    }

    return saturate(finalColor);
}

#endif // STRESS_CORE_INCLUDED
