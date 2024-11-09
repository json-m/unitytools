// i won't explain what this one is useful for.
// i'm not responsible for any outcomes from using this. good luck
// public domain idc
Shader "_aa/UltimateStressTest"
{
    Properties
    {
	
		[Header(Timing Control)]
        _StartDelay ("Start Delay (seconds)", Range(0, 60)) = 0
        // Base properties
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _MinDistance ("Minimum Distance", Float) = 0
        _MaxDistance ("Maximum Distance", Float) = 5
        _FadeRange ("Fade Range", Range(0.0, 1.0)) = 0.2
        
        // Core stress test controls
        [Header(Core Stress Parameters)]
        _StressLevel ("Overall Stress Level", Range(1, 10)) = 5
        _ComputeIntensity ("Compute Intensity", Range(0, 1)) = 1
        _MemoryIntensity ("Memory Intensity", Range(0, 1)) = 1
        
        // Texture stress parameters
        [Header(Texture Stress)]
        _NoiseTex1 ("Noise Texture 1", 2D) = "gray" {}
        _NoiseTex2 ("Noise Texture 2", 2D) = "gray" {}
        _NoiseTex3 ("Noise Texture 3", 2D) = "gray" {}
        _NoiseTex4 ("Noise Texture 4", 2D) = "gray" {}
        _TextureScale ("Texture Scale", Range(0.1, 10)) = 1
        
        // Branch and computation stress
        [Header(Branch Computation)]
        _BranchComplexity ("Branch Complexity", Range(1, 100)) = 50
        _BranchThreshold ("Branch Threshold", Range(0, 1)) = 0.5
        _MathIterations ("Math Iterations", Range(1, 200)) = 100
        _FractalDepth ("Fractal Depth", Range(1, 20)) = 10
        
        // Additional stress parameters
        [Header(Additional Stress Parameters)]
        _DerivativeStress ("Derivative Stress", Range(0, 1)) = 0.5
        _CacheStress ("Cache Stress", Range(0, 1)) = 0.5
        _ThreadStress ("Thread Divergence", Range(0, 1)) = 0.5
        _TextureStress ("Texture Unit Stress", Range(0, 1)) = 0.5
        
        // Advanced computation parameters
        [Header(Advanced Computation)]
        _DisplacementIntensity ("Displacement Intensity", Range(0, 2)) = 1
        _VertexStress ("Vertex Stress", Range(0, 1)) = 0.5
        _GeometryComplexity ("Geometry Complexity", Range(1, 10)) = 5
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"

            // Structures
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 color : COLOR;
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
			};

            // Texture declarations
            sampler2D _MainTex, _NoiseTex1, _NoiseTex2, _NoiseTex3, _NoiseTex4;
            float4 _MainTex_ST;
            float4 _Color;
            
            // Property variables
            float _MinDistance, _MaxDistance, _FadeRange;
            float _StressLevel, _ComputeIntensity, _MemoryIntensity;
            float _TextureScale, _BranchComplexity, _BranchThreshold;
            int _MathIterations, _FractalDepth;
            float _DerivativeStress, _CacheStress, _ThreadStress, _TextureStress;
            float _DisplacementIntensity, _VertexStress, _GeometryComplexity;

            // Memory stress buffer
            #define BUFFER_SIZE 256
			// Replace the static buffer with a function that generates values
			float4 getStressBufferValue(uint index)
			{
				// Create deterministic but varying values based on index
				float f = (float)index / BUFFER_SIZE;
				return float4(
					sin(f * 6.283185),
					cos(f * 6.283185),
					sin(f * 12.566370),
					1.0
				);
			}

			// Complex number operations
            float2 cmul(float2 a, float2 b) 
            {
                return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
            }
            
            float2 csqr(float2 a) 
            {
                return float2(a.x * a.x - a.y * a.y, 2.0 * a.x * a.y);
            }

            // Pseudo-random number generators
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

            float voronoiNoise(float3 p)
            {
                float3 b = floor(p);
                float3 f = frac(p);
                float res = 100.0;
                
                for(int i = -1; i <= 1; i++)
                for(int j = -1; j <= 1; j++)
                for(int k = -1; k <= 1; k++)
                {
                    float3 g = float3(i, j, k);
                    float3 r = g + hash33(b + g) - f;
                    float d = dot(r, r);
                    res = min(res, d);
                }
                
                return sqrt(res);
            }

            // Fractal Brownian Motion
            float fbm(float3 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;
                
                for(int i = 0; i < _FractalDepth; i++)
                {
                    value += amplitude * gradientNoise(p * frequency);
                    amplitude *= 0.5;
                    frequency *= 2.0;
                    
                    // Add rotation for more complexity
                    p.xy = float2(
                        p.x * cos(value) - p.y * sin(value),
                        p.x * sin(value) + p.y * cos(value)
                    );
                }
                
                return value;
            }

            // Julia set computation
            float3 juliaSet(float2 pos, float time)
            {
                float2 c = float2(sin(time * 0.1), cos(time * 0.1)) * 0.7;
                float2 z = pos;
                float iter = 0;
                
                for(int i = 0; i < _MathIterations; i++)
                {
                    z = csqr(z) + c;
                    if(dot(z,z) > 4.0) break;
                    iter++;
                }
                
                float smooth_iter = iter - log2(log2(dot(z,z))) + 4.0;
                return float3(
                    0.5 + 0.5 * sin(smooth_iter * 0.1),
                    0.5 + 0.5 * sin(smooth_iter * 0.2),
                    0.5 + 0.5 * sin(smooth_iter * 0.3)
                );
            }

            // Mandelbulb distance estimation
            float mandelbulbDE(float3 pos, float time)
            {
                float3 z = pos;
                float dr = 1.0;
                float r = 0.0;
                float power = 8.0 + sin(time * 0.1) * 2.0; // Animated power
                
                for(int i = 0; i < _MathIterations; i++)
                {
                    r = length(z);
                    if(r > 2.0) break;
                    
                    float theta = acos(z.z/r) * power;
                    float phi = atan2(z.y, z.x) * power;
                    float zr = pow(r, power);
                    
                    dr = pow(r, power-1.0) * power * dr + 1.0;
                    
                    z = zr * float3(
                        sin(theta) * cos(phi),
                        sin(theta) * sin(phi),
                        cos(theta)
                    );
                    
                    z += pos;
                }
                
                return 0.5 * log(r) * r / dr;
            }
			// Derivative stress testing
            float3 derivativeStress(float2 uv, float3 worldPos, float time)
            {
                float2 dx = ddx(uv);
                float2 dy = ddy(uv);
                float3 result = 0;
                
                for(int i = 0; i < 10; i++)
                {
                    // Force complex derivative calculations
                    float2 offset = float2(dx.x * i + sin(time), dy.y * i + cos(time));
                    result += sin(worldPos * offset.xyx);
                    
                    // Create dependent texture fetches
                    float2 uvOffset = uv + offset;
                    result += tex2D(_NoiseTex1, uvOffset).rgb;
                    result += tex2D(_NoiseTex2, uvOffset * 1.5).rgb;
                    
                    // Add derivative computations
                    result += ddx(sin(worldPos * (i + 1)));
                    result += ddy(cos(worldPos * (i + 1)));
                    
                    // Add partial derivatives
                    float2 partial = frac(result.xy + offset);
                    result.xy += ddx(partial) + ddy(partial);
                }
                return result;
            }

            // Cache coherency stress
			float3 cacheStress(float3 pos, float time)
			{
				float3 result = 0;
				float stride = _CacheStress * 17.0;
				
				for(int i = 0; i < 16; i++)
				{
					// Create scattered memory access patterns
					uint index = (uint)(frac(pos.x * stride + i * 7.919 + sin(time)) * (BUFFER_SIZE - 1));
					result += getStressBufferValue(index).rgb;
					
					// Nonlinear memory access
					float2 uv = pos.xy * stride + float2(
						sin(index + time),
						cos(index - time)
					);
					
					// Multiple dependent texture fetches
					float4 sample1 = tex2D(_NoiseTex1, uv);
					float4 sample2 = tex2D(_NoiseTex2, uv * sample1.rg);
					float4 sample3 = tex2D(_NoiseTex3, uv * sample2.ba);
					float4 sample4 = tex2D(_NoiseTex4, uv * sample3.rg);
					
					result += sample1.rgb + sample2.rgb + sample3.rgb + sample4.rgb;
				}
				return result * 0.1; // Normalize result
			}

            // Thread divergence stress
            float3 threadStress(float3 pos, float time)
            {
                float3 result = 0;
                float threshold = _ThreadStress;
                
                for(int i = 0; i < 32; i++)
                {
                    float r = hash11(dot(pos, float3(12.9898 + i, 78.233 + time, 45.5432)));
                    
                    // Create highly divergent paths with varying computational intensity
                    if(r < threshold * 0.2)
                    {
                        result += sin(pos * time * 0.1) * tan(pos * 0.2);
                        for(int j = 0; j < i % 8; j++)
                        {
                            result *= normalize(result + 0.01);
                        }
                    }
                    else if(r < threshold * 0.4)
                    {
                        result += cos(pos * time * 0.2) * exp2(sin(pos * 0.1));
                        float3 temp = 0;
                        for(int j = 0; j < i % 6; j++)
                        {
                            temp += sin(result * j);
                        }
                        result += temp * 0.1;
                    }
                    else if(r < threshold * 0.6)
                    {
                        result += tan(pos * time * 0.3) * log2(abs(cos(pos * 0.3)) + 2.0);
                        result = pow(abs(result), 0.9);
                    }
                    else if(r < threshold * 0.8)
                    {
                        float3 temp = pos;
                        for(int j = 0; j < i % 4; j++)
                        {
                            temp = sin(temp + j);
                        }
                        result += temp;
                    }
                    else
                    {
                        result += exp(sin(pos * time * 0.4) * 0.2) * 0.1;
                        result = frac(result * result);
                    }
                }
                return result * 0.1;
            }

            // Texture unit stress
            float4 textureStress(float2 uv, float3 worldPos, float time)
            {
                float4 result = 0;
                float2 offset = 0;
                
                for(int i = 0; i < 8; i++)
                {
                    // Dynamic UV offsets
                    offset = float2(
                        sin(time + i * 0.1) * _TextureStress,
                        cos(time + i * 0.1) * _TextureStress
                    );
                    
                    // Complex UV transformations
                    float2 uv1 = uv + offset;
                    float2 uv2 = uv * (1.0 + offset);
                    float2 uv3 = uv / (1.0 - offset * 0.5);
                    float2 uv4 = uv * float2(sin(time + uv.x), cos(time + uv.y));
                    
                    // Multiple dependent texture fetches
                    float4 sample1 = tex2D(_NoiseTex1, uv1);
                    float4 sample2 = tex2D(_NoiseTex2, uv2 + sample1.rg * 0.1);
                    float4 sample3 = tex2D(_NoiseTex3, uv3 + sample2.ba * 0.1);
                    float4 sample4 = tex2D(_NoiseTex4, uv4 + sample3.rg * 0.1);
                    
                    // Accumulate with varying weights
                    float weight = (sin(time + i) * 0.5 + 0.5);
                    result += lerp(sample1, sample2, weight);
                    result += lerp(sample3, sample4, 1 - weight);
                    
                    // Add some computational complexity
                    result += sin(float4(worldPos, time) * (i + 1)) * 0.01;
                }
                
                return result * 0.125; // Normalize result
            }

            float3x3 rot3d(float angle)
            {
                float s = sin(angle);
                float c = cos(angle);
                return float3x3(
                    c, -s, 0,
                    s, c, 0,
                    0, 0, 1
                );
            }

            // Compute shader stress (ALU intensive)
            float3 computeStress(float3 pos, float time)
            {
                float3 result = 0;
                float3 p = pos * _ComputeIntensity;
                
                for(int i = 0; i < _MathIterations; i++)
                {
                    // Complex mathematical operations
                    float3 temp = p + time * 0.1;
                    temp = sin(temp) * cos(temp.zxy);
                    temp = mul(rot3d(time + i * 0.1), temp);
                    
                    // Fractal calculations
                    float julia = length(juliaSet(temp.xy, time));
                    float mandel = mandelbulbDE(temp, time);
                    float noise = fbm(temp + i * 0.1);
                    
                    // Combine results with transcendental functions
                    result += sin(temp * julia) + cos(temp * mandel) + tan(temp * noise);
                    
                    // Matrix transformations
                    p = mul(rot3d(time * 0.1 + i * 0.05), p);
                }
                
                return result * (1.0 / _MathIterations);
            }
			// Vertex displacement function
            float3 displaceVertex(float3 pos, float3 normal, float time)
            {
                float3 displacement = 0;
                
                // Layer multiple displacement effects
                for(int i = 0; i < 4; i++)
                {
                    float scale = pow(2.0, float(i));
                    float amplitude = pow(0.5, float(i));
                    
                    // Add various noise types
                    displacement += normal * fbm(pos * scale + time) * amplitude;
                    displacement += normal * voronoiNoise(pos * scale - time) * amplitude;
                    
                    // Add some angular displacement
                    float3 angle = sin(pos * scale + time);
                    displacement += cross(normal, angle) * amplitude * 0.5;
                }
                
                return displacement * _DisplacementIntensity;
            }

			v2f vert (appdata v)
			{
				v2f o;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				float distanceFromCamera = distance(_WorldSpaceCameraPos, worldPos);
				float time = _Time.y;
				
				// Calculate view direction
				o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
				o.distanceFromCamera = distanceFromCamera;
				
				// If outside max distance, move vertex far away to ensure culling
				if (distanceFromCamera > _MaxDistance)
				{
					o.vertex = float4(2.0, 2.0, 2.0, 1.0);
					return o;
				}
				
				// Rest of vertex calculations...
				float3 vertexNoise = 0;
				for(int i = 0; i < 3; i++)
				{
					float scale = pow(2.0, float(i)) * _VertexStress;
					vertexNoise += gradientNoise(worldPos * scale + time * (i + 1));
				}
				
				// Apply displacement
				float3 displacement = displaceVertex(worldPos, v.normal, time);
				v.vertex.xyz += mul(unity_WorldToObject, displacement) * _VertexStress;
				
				// Generate additional vertex motion
				float3 vertexMotion = sin(worldPos * _GeometryComplexity + time);
				vertexMotion += cos(worldPos * _GeometryComplexity * 0.5 - time);
				v.vertex.xyz += mul(unity_WorldToObject, vertexMotion * vertexNoise * _VertexStress);

				// Transform vertex
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				// Calculate and store additional vertex data
				o.worldPos = worldPos;
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = v.tangent;
				o.binormal = cross(o.normal, o.tangent.xyz) * v.tangent.w;
				o.screenPos = ComputeScreenPos(o.vertex);
				o.localPos = v.vertex;
				o.color = v.color;

				return o;
			}

            fixed4 frag (v2f i) : SV_Target
			{
				// Early distance-based discard
				if (i.distanceFromCamera > _MaxDistance)
				{
					clip(-1); // Discards the fragment immediately
					return fixed4(0,0,0,0);
				}

				// Calculate fade once
				float fade = 1.0;
				if (i.distanceFromCamera < _MinDistance)
				{
					fade = 1.0;
				}
				else
				{
					float fadeStart = _MaxDistance - _FadeRange * (_MaxDistance - _MinDistance);
					fade = 1.0 - smoothstep(fadeStart, _MaxDistance, i.distanceFromCamera);
					
					// Early exit if nearly transparent
					if (fade < 0.01)
					{
						clip(-1);
						return fixed4(0,0,0,0);
					}
				}

				float time = _Time.y;
				
				// Begin collecting stress test results
				float3 stressColor = 0;
				float4 finalColor = tex2D(_MainTex, i.uv) * _Color;
                
                // Apply derivative stress
                float3 derivColor = derivativeStress(i.uv, i.worldPos, time);
                stressColor += derivColor * _DerivativeStress;
                
                // Apply cache stress
                float3 cacheColor = cacheStress(i.worldPos, time);
                stressColor += cacheColor * _CacheStress;
                
                // Apply thread divergence stress
                float3 threadColor = threadStress(i.worldPos, time);
                stressColor += threadColor * _ThreadStress;
                
                // Apply texture stress
                float4 texColor = textureStress(i.uv, i.worldPos, time);
                stressColor += texColor.rgb * _TextureStress;
				// Continue fragment shader calculations...
                
                // Apply compute stress
                float3 computeColor = computeStress(i.worldPos, time);
                stressColor += computeColor * _ComputeIntensity;
                
                // Calculate complex normal mapping
                float3 normalMap = normalize(
                    tex2D(_NoiseTex1, i.uv * _TextureScale + time * 0.1).rgb * 2.0 - 1.0 +
                    tex2D(_NoiseTex2, i.uv * _TextureScale - time * 0.15).rgb * 2.0 - 1.0 +
                    tex2D(_NoiseTex3, i.uv * _TextureScale + float2(sin(time), cos(time))).rgb * 2.0 - 1.0
                );
                
                float3 worldNormal = normalize(
                    normalMap.x * i.tangent +
                    normalMap.y * i.binormal +
                    normalMap.z * i.normal
                );

                // Calculate advanced lighting
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);
                
                // Physically based lighting calculations
                float NdotL = max(0, dot(worldNormal, lightDir));
                float NdotH = max(0, dot(worldNormal, halfDir));
                float NdotV = max(0, dot(worldNormal, viewDir));
                float VdotH = max(0, dot(viewDir, halfDir));
                
                // Calculate specular power using GPU stress
                float specPower = exp2(fbm(i.worldPos * _TextureScale + time) * 10.0 + 2.0);
                float specular = pow(NdotH, specPower) * VdotH;
                
                // Calculate fresnel with computational stress
                float fresnel = 0;
                float fresnelPower = _ComputeIntensity * 5.0;
                for(int j = 0; j < 5; j++)
                {
                    fresnel += pow(1.0 - NdotV, fresnelPower + j) * (1.0 / (j + 1.0));
                }
                
                // Apply branch stress calculations
                float3 branchColor = 0;
                for(int k = 0; k < _BranchComplexity; k++)
                {
                    float r = hash11(dot(i.worldPos + k, float3(12.9898, 78.233, 45.5432)));
                    
                    if(r < _BranchThreshold)
                    {
                        branchColor += sin(i.worldPos * float3(
                            sin(time + k),
                            cos(time + k),
                            sin(time * 0.5 + k)
                        ));
                    }
                    else if(r < _BranchThreshold * 2.0)
                    {
                        branchColor += cos(i.worldPos * float3(
                            cos(time + k),
                            sin(time + k),
                            cos(time * 0.5 + k)
                        ));
                    }
                    else
                    {
                        branchColor += tan(i.worldPos * 0.1 * float3(
                            sin(time * 0.2 + k),
                            cos(time * 0.3 + k),
                            sin(time * 0.4 + k)
                        ));
                    }
                }
                branchColor *= _StressLevel * 0.01;

                // Calculate Julia set contribution
                float2 juliaUV = i.screenPos.xy / i.screenPos.w * 2.0 - 1.0;
                float3 juliaColor = juliaSet(juliaUV, time) * _ComputeIntensity;
                
                // Calculate Mandelbulb contribution
                float mandel = mandelbulbDE(i.worldPos * 0.1, time);
                float3 mandelColor = float3(mandel, mandel * 0.5, mandel * 0.25) * _ComputeIntensity;

                // Combine all stress colors
                stressColor = (stressColor + branchColor + juliaColor + mandelColor) * _StressLevel;
                
                // Apply lighting contribution
                float3 lightingColor = NdotL + specular + fresnel;
                stressColor *= lightingColor;
                
                // Final color composition
                finalColor.rgb = lerp(finalColor.rgb, stressColor, _StressLevel * 0.5);
                
                // Additional per-pixel operations for GPU stress
                for(int m = 0; m < _StressLevel; m++)
                {
                    finalColor.rgb = normalize(finalColor.rgb + 
                        sin(finalColor.rgb * 6.28318 + time + m));
                }

                // Apply distance fade
				finalColor.rgb *= fade;
				finalColor.a *= fade;
				
				return saturate(finalColor);
            }
            
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}