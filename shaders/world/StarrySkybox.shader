Shader "_aa/world/skybox_StarryNight" {
    Properties {
        _StarDensity ("Star Detail", Range(100,500)) = 200
        _StarThreshold ("Star Threshold", Range(4,12)) = 8
        _StarExposure ("Star Brightness", Range(50,400)) = 200
        _StarSpeed ("Star Movement Speed", Range(0,1)) = 0.1
        _NebulaBrightness ("Nebula Brightness", Range(0,2)) = 0.6
        _NebulaScale ("Nebula Scale", Range(0.1,10)) = 0.5
        _NebulaColor1 ("Nebula Color 1", Color) = (0.5,0.7,1.0,1)
        _NebulaColor2 ("Nebula Color 2", Color) = (1.0,0.5,0.7,1)
        _SkyColor ("Sky Color", Color) = (0.02,0.02,0.08,1)
        _GalaxyBrightness ("Galaxy Brightness", Range(0,2)) = 1.0
        _GalaxyCount ("Galaxy Count", Range(3,12)) = 6
        _GalaxyScale ("Galaxy Scale", Range(0.1,2)) = 0.5
    }

    SubShader {
        Tags { "RenderType"="Background" "Queue"="Background" "PreviewType"="Skybox" }
        LOD 100
        Cull Off ZWrite Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
            };

            float _StarDensity;
            float _StarThreshold;
            float _StarExposure;
            float _StarSpeed;
            float _NebulaBrightness;
            float _NebulaScale;
            float4 _NebulaColor1;
            float4 _NebulaColor2;
            float4 _SkyColor;
            float _GalaxyBrightness;
            float _GalaxyCount;
            float _GalaxyScale;

            // Galaxy data - positions now generated from hash
            float3 getGalaxyPosition(float seed) {
                float3 pos;
                pos.x = (frac(sin(seed * 78.233) * 43758.5453) * 2.0 - 1.0) * 3.14159;
                pos.y = (frac(sin(seed * 12.9898) * 43758.5453) * 2.0 - 1.0) * 0.3;
                pos.z = (frac(sin(seed * 37.123) * 43758.5453) * 2.0 - 1.0) * 3.14159;
                return pos;
            }

            float getGalaxyScale(float seed) {
                return lerp(0.005, 0.015, frac(sin(seed * 92.123) * 43758.5453)) * _GalaxyScale;
            }

            float getGalaxyBrightness(float seed) {
                return lerp(0.6, 1.2, frac(sin(seed * 43.123) * 43758.5453));
            }

            // Galaxy generation using elliptical orbits
            float galaxyHash(float3 p3) {
                p3 = frac(p3 * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float hash21(float2 p) {
                p = frac(p * float2(123.456, 789.01));
                p += dot(p, p + 45.67);
                return frac(p.x * p.y);
            }

            float star(float2 uv, float brightness) {
                float color = 0.0;
                float star = length(uv);
                float diffraction = abs(uv.x * uv.y);
                
                star = brightness/star;
                diffraction = pow(brightness, 2.0)/diffraction;
                diffraction = min(star, diffraction);
                diffraction *= sqrt(star);
                
                color += star * sqrt(brightness) * 8.0;
                color += diffraction * 8.0;
                return color;
            }

            float3 renderGalaxyCore(float2 uv, float seed, float brightness) {
                float3 col = float3(0, 0, 0);
                float dist = 1.0;
                float2 p = uv;
                
                // Get cell-based positions for stars
                float2 gv = frac(p) - 0.5;
                float2 id = floor(p);

                // Apply different scales for star layers
                for(float y = -dist; y <= dist; y++) {
                    for(float x = -dist; x <= dist; x++) {
                        float2 offset = float2(x, y);
                        float displacement = hash21(id + offset);
                        
                        float starBright = hash21(id + offset) / 128.0;
                        float2 pos = gv - offset - float2(displacement, frac(displacement * 16.0)) + 0.5;
                        col += star(pos, starBright).xxx;
                    }
                }
                
                // Scale down and add base colors
                col *= float3(0.5, 0.7, 1.0);
                col *= brightness;
                
                // Add bright core
                float coreSize = 0.05;
                float core = exp(-length(uv) / coreSize);
                col += float3(1.0, 0.9, 0.7) * core * brightness;
                
                return col;
            }

            // Generic 3D noise functions
            float3 hash3(float3 p) {
                p = float3(
                    dot(p, float3(127.1, 311.7,  74.7)),
                    dot(p, float3(269.5, 183.3, 246.1)),
                    dot(p, float3(113.5, 271.9, 124.6))
                );
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }

            float noise(float3 p) {
                float3 i = floor(p);
                float3 f = frac(p);
                float3 u = f * f * (3.0 - 2.0 * f);

                return lerp(
                    lerp(lerp(dot(hash3(i + float3(0,0,0)), f - float3(0,0,0)),
                             dot(hash3(i + float3(1,0,0)), f - float3(1,0,0)), u.x),
                         lerp(dot(hash3(i + float3(0,1,0)), f - float3(0,1,0)),
                             dot(hash3(i + float3(1,1,0)), f - float3(1,1,0)), u.x), u.y),
                    lerp(lerp(dot(hash3(i + float3(0,0,1)), f - float3(0,0,1)),
                             dot(hash3(i + float3(1,0,1)), f - float3(1,0,1)), u.x),
                         lerp(dot(hash3(i + float3(0,1,1)), f - float3(0,1,1)),
                             dot(hash3(i + float3(1,1,1)), f - float3(1,1,1)), u.x), u.y), u.z);
            }

            // Nebula functions
            float nebulaNoise(float3 p) {
                p = abs(frac(p) - 0.5);
                return pow(1.0 - min(min(p.x, p.y), p.z), 2.0);
            }

            float fbm(float3 p) {
                const int NUM_OCTAVES = 6;
                float amp = 0.5;
                float freq = 1.0;
                float val = 0.0;
                float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
                
                for(int i = 0; i < NUM_OCTAVES; i++) {
                    val += amp * noise(p * freq);
                    p.xy = mul(rot, p.xy);
                    p.yz = mul(rot, p.yz);
                    freq *= 2.0;
                    amp *= 0.5;
                }
                return val;
            }

            float nebulaPattern(float3 p, float time) {
                float3 q = p;
                float f = fbm(q * 0.5);
                
                q.xy = mul(float2x2(cos(time*0.1), sin(time*0.1), -sin(time*0.1), cos(time*0.1)), q.xy);
                float f1 = fbm(q * 1.0 + float3(1.0, 2.0, 3.0) + f * 5.0);
                
                return f1;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(o.worldPos - _WorldSpaceCameraPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float4 col = _SkyColor;
                float time = _Time.y * _StarSpeed;

                // Background stars
                float2x2 rot = float2x2(cos(time), sin(time), -sin(time), cos(time));
                float3 dir = normalize(i.viewDir);
                dir.xz = mul(rot, dir.xz);
                
                float stars = pow(
                    clamp(noise(dir * _StarDensity), 0.0, 1.0),
                    _StarThreshold
                ) * _StarExposure;
                stars *= lerp(0.4, 1.4, noise(dir * 100.0 + float3(time, 0, 0)));

                // Nebula
                float3 nebPos = dir * _NebulaScale;
                float n1 = nebulaPattern(nebPos, time * 0.1);
                float n2 = nebulaPattern(nebPos + float3(8.123, 4.56, 2.34), time * 0.2);
                
                float nebulaMask = pow(max(n1, n2), 2.0);
                nebulaMask = smoothstep(0.1, 0.6, nebulaMask);
                float3 nebulaColor = lerp(_NebulaColor1.rgb, _NebulaColor2.rgb, n2);
                float3 nebulaEffect = nebulaColor * nebulaMask * _NebulaBrightness;

                float3 finalColor = col.rgb;
                finalColor += stars;
                finalColor += nebulaEffect * smoothstep(-0.2, 0.2, dir.y);

                // Calculate view direction in spherical coordinates once
                float2 viewSpherical = float2(atan2(dir.z, dir.x), asin(dir.y));
                
                // Render multiple galaxies based on _GalaxyCount
                for(int j = 0; j < _GalaxyCount; j++) {
                    float seed = float(j) * 567.123;
                    float3 galaxyPos = getGalaxyPosition(seed);
                    float galaxyScale = getGalaxyScale(seed);
                    float galaxyBright = getGalaxyBrightness(seed);
                    
                    // Convert 3D position to spherical for UV mapping
                    float2 galaxySpherical = float2(
                        atan2(galaxyPos.z, galaxyPos.x),
                        asin(galaxyPos.y)
                    );
                    
                    // Apply different scales to create multi-layer effect
                    float2 baseUV = (viewSpherical - galaxySpherical) * galaxyScale;
                    
                    // Main galaxy view
                    float2 galaxyUV = baseUV * 256.0;
                    float3 mainGalaxy = renderGalaxyCore(galaxyUV, seed, galaxyBright * _GalaxyBrightness);
                    
                    // Secondary view with different scale
                    galaxyUV = baseUV * 128.0;
                    float3 secondaryGalaxy = renderGalaxyCore(galaxyUV, seed + 1.234, galaxyBright * _GalaxyBrightness * 0.7);
                    
                    // Combine layers
                    float3 galaxyCol = mainGalaxy + secondaryGalaxy;
                    
                    // Distance-based masking
                    float distFromCenter = length(dir - normalize(galaxyPos));
                    float galaxyMask = smoothstep(1.0, 0.0, distFromCenter);
                    
                    finalColor += galaxyCol * galaxyMask;
                }
                
                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Unlit/Color"
}