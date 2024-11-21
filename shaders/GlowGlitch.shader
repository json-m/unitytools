// glitchy display style shader with cyberpunk-ish glitch/distortion + crt/vhs effects
// underlying texture should be uv mapped and black background with white text for best result
// public domain idc
Shader "_aa/GlowGlitch"
{
    Properties
    {
        [Header(Base Properties)]
        _MainTex ("Text Texture", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (1, 0.2, 0, 1)
        
        [Header(Volumetric Glow)]
        _GlowPower ("Glow Power", Range(0.1, 5.0)) = 1.0
        _CoreIntensity ("Core Light Intensity", Range(1, 5)) = 1.5
        _GlowIntensity ("Glow Intensity", Range(0, 5)) = 1.0
        _GlowFalloff ("Glow Falloff", Range(1, 5)) = 2.0
        _InnerRadius ("Inner Glow Radius", Range(0, 0.5)) = 0.1
        _OuterRadius ("Outer Glow Radius", Range(0, 2)) = 0.5
        _SampleCount ("Glow Sample Count", Range(4, 32)) = 16
        [HDR] _GlowTint ("Glow Color Tint", Color) = (1, 0.6, 0.2, 1)
        _ColorTemp ("Color Temperature Shift", Range(0, 1)) = 0.2
        _GlowTurbulence ("Glow Turbulence", Range(0, 1)) = 0.1
        _AtmosphericDensity ("Atmospheric Density", Range(0, 1)) = 0.2
        _ScatteringIntensity ("Light Scattering", Range(0, 1)) = 0.3
        
        [Header(VHS CRT Effects)]
        _ScanLineCount ("Scan Line Count", Range(0, 1000)) = 100
        _ScanLineSpeed ("Scan Line Speed", Range(0, 10)) = 2
        _ScanLineIntensity ("Scan Line Intensity", Range(0, 1)) = 0.5
        _VerticalJitter ("Vertical Jitter", Range(0, 0.1)) = 0.01
        _HorizontalShake ("Horizontal Shake", Range(0, 0.1)) = 0.005
        
        [Header(Color Bleeding)]
        _BleedingRadius ("Color Bleeding Radius", Range(0, 2)) = 0.5
        _BleedingIntensity ("Color Bleeding Intensity", Range(0, 0.5)) = 0.1
        
        [Header(Glitch Properties)]
        _GlitchInterval ("Glitch Interval", Range(1, 10)) = 3
        _GlitchDuration ("Glitch Duration", Range(0.1, 2.0)) = 0.5
        [Range(0, 100)] _GlitchChance ("Glitch Chance (%)", Float) = 30
        _GlitchStrength ("Glitch Strength", Range(0, 0.1)) = 0.01
        _ChromaticStrength ("Chromatic Strength During Glitch", Range(0, 0.1)) = 0.003
        
        [Header(Advanced Inversion Effects)]
        [Toggle] _UseInversion ("Enable Color Inversion", Float) = 1
        _InversionProbability ("Inversion Chance", Range(0, 1)) = 0.3
        [IntRange] _InversionSegmentsX ("Horizontal Segments", Range(1, 32)) = 3
        [IntRange] _InversionSegmentsY ("Vertical Segments", Range(1, 32)) = 3
        [Enum(Vertical,0,Horizontal,1,Grid,2)] _InversionMode ("Inversion Mode", Float) = 0
        _InversionRotation ("Inversion Rotation", Range(0, 360)) = 0
        _InversionScale ("Inversion Scale", Range(0.1, 5)) = 1
        [Toggle] _RandomizeSegments ("Randomize Segment Sizes", Float) = 0
        _SegmentVariation ("Segment Size Variation", Range(0, 1)) = 0.2

        [Header(Wave Properties)]
        _WaveStrength ("Wave Strength", Range(0, 0.01)) = 0.001
        _WaveFreqX ("Wave Frequency X", Range(0, 50)) = 15
        _WaveFreqY ("Wave Frequency Y", Range(0, 50)) = 20
        _WaveSpeedX ("Wave Speed X", Range(0, 10)) = 2
        _WaveSpeedY ("Wave Speed Y", Range(0, 10)) = 3

        [Header(Tape Wear)]
        _TapeWearAmount ("Tape Wear Amount", Range(0, 1)) = 0.2
        _TapeWearSpeed ("Wear Animation Speed", Range(0, 2)) = 0.5
        [IntRange] _WearPatternScale ("Wear Pattern Scale", Range(1, 50)) = 10
        _WearPatternIntensity ("Wear Pattern Intensity", Range(0, 1)) = 0.3

        [Header(Color Degradation)]
        _ColorNoiseTint ("Color Noise Tint", Color) = (0.9, 0.7, 0.5, 1)
        _ColorNoiseScale ("Color Noise Scale", Range(0, 50)) = 15
        _ColorNoiseIntensity ("Color Noise Intensity", Range(0, 1)) = 0.2
        _ColorFading ("Color Fading", Range(0, 1)) = 0.1

        [Header(Scroll Effect)]
        [Toggle] _EnableScroll ("Enable Scrolling", Float) = 0
        _ScrollSpeedX ("Scroll Speed X", Range(-2, 2)) = 0.5
        _ScrollSpeedY ("Scroll Speed Y", Range(-2, 2)) = 0
        _ScrollOffset ("Scroll Offset", Vector) = (0, 0, 0, 0)
    }
	
	SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert
        #pragma target 3.0
        
        // Constants
        #define PI 3.14159265359
        #define E 2.71828182846
        
        struct Input 
        { 
            float2 uv_MainTex;
            float3 worldPos;
            float4 screenPos;
        };

        // Base properties
        sampler2D _MainTex;
        float4 _EmissionColor;
        float4 _GlowTint;
        
        // Volumetric glow properties
        float _GlowPower;
        float _CoreIntensity;
        float _GlowIntensity;
        float _GlowFalloff;
        float _InnerRadius;
        float _OuterRadius;
        float _SampleCount;
        float _ColorTemp;
        float _GlowTurbulence;
        float _AtmosphericDensity;
        float _ScatteringIntensity;
        
        // VHS/CRT effect properties
        float _ScanLineCount, _ScanLineSpeed, _ScanLineIntensity;
        float _VerticalJitter, _HorizontalShake;
        float _BleedingRadius, _BleedingIntensity;
        float _GlitchInterval, _GlitchDuration, _GlitchChance, _GlitchStrength;
        float _ChromaticStrength;
        
        // Inversion properties
        float _UseInversion, _InversionProbability;
        float _InversionSegmentsX, _InversionSegmentsY;
        float _InversionMode, _InversionRotation;
        float _InversionScale, _RandomizeSegments, _SegmentVariation;
        
        // Wave and noise properties
        float _WaveStrength, _WaveFreqX, _WaveFreqY, _WaveSpeedX, _WaveSpeedY;
        float _NoiseScale, _NoiseStrength, _StaticNoise, _PulseSpeed;
        
        // Scroll properties
        float _EnableScroll;
        float _ScrollSpeedX, _ScrollSpeedY;
        float4 _ScrollOffset;

        // Tape wear properties
        float _TapeWearAmount;
        float _TapeWearSpeed;
        float _WearPatternScale;
        float _WearPatternIntensity;

        // Color degradation properties
        float4 _ColorNoiseTint;
        float _ColorNoiseScale;
        float _ColorNoiseIntensity;
        float _ColorFading;

        // Hash function for pseudo-random number generation
        float hash(float2 p, float seed)
        {
            float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973) + seed);
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
        }
        
        // Voronoi noise implementation for organic patterns
        float2 voronoi(float2 x, float seed)
        {
            float2 n = floor(x);
            float2 f = frac(x);
            float2 mg = 0;
            float md = 8.0;
            
            for(int j = -1; j <= 1; j++) {
                for(int i = -1; i <= 1; i++) {
                    float2 g = float2(i, j);
                    float2 o = hash(n + g, seed).xx;
                    o = 0.5 + 0.5 * sin(_Time.y * 0.5 + 6.2831 * o);
                    float2 r = g + o - f;
                    float d = dot(r, r);
                    if(d < md) {
                        md = d;
                        mg = g;
                    }
                }
            }
            return float2(md, hash(n + mg, seed + 0.5));
        }
        
        // 2D rotation matrix helper
        float2 rotate2D(float2 uv, float angle)
        {
            angle = angle * PI / 180.0;
            float2x2 rotationMatrix = float2x2(cos(angle), -sin(angle),
                                             sin(angle), cos(angle));
            return mul(rotationMatrix, uv - 0.5) + 0.5;
        }
		
		// Color temperature adjustment
        float3 adjustColorTemp(float3 col, float temp)
        {
            float3 warm = float3(1.0, 0.8, 0.6);
            float3 cool = float3(0.6, 0.8, 1.0);
            return col * lerp(warm, cool, temp);
        }
        
        // Atmospheric scattering approximation
        float3 atmosphericScatter(float3 color, float dist, float density)
        {
            float scatter = 1.0 - exp(-dist * density);
            float3 atmosphereColor = _GlowTint.rgb * _GlowIntensity;
            return lerp(color, atmosphereColor, scatter * _ScatteringIntensity);
        }
        
        // Volumetric sampling function
        float3 sampleVolumetric(float2 uv, float2 offset, float radius, float2 baseUV)
        {
            float2 samplePos = uv + offset * radius;
            // Use the non-scrolled UV for the glow effect
            float3 col = tex2D(_MainTex, baseUV + offset * radius).rgb;
            
            // Calculate distance-based attenuation
            float dist = length(offset);
            float atten = exp(-dist * _GlowFalloff);
            
            // Add turbulence
            float2 turb = voronoi(samplePos * _NoiseScale + _Time.y * 0.1, _Time.y);
            atten *= 1.0 + turb.x * _GlowTurbulence;
            
            // Apply atmospheric effects
            col = atmosphericScatter(col, dist, _AtmosphericDensity);
            
            return col * atten;
        }

        // Tape wear effect implementation
        float3 applyTapeWear(float3 col, float2 uv, float time)
        {
            // Create base wear pattern
            float2 wearUV = uv * _WearPatternScale;
            float baseWear = hash(floor(wearUV) + time * _TapeWearSpeed, time);
            
            // Generate vertical wear lines (tracking problems)
            float vWear = smoothstep(0.4, 0.6, hash(float2(floor(uv.x * _WearPatternScale), time), time));
            
            // Create horizontal wear bands
            float hWear = hash(float2(floor(uv.y * _WearPatternScale * 0.5), time * 0.25), time);
            
            // Combine wear patterns
            float wear = max(max(baseWear, vWear), hWear) * _WearPatternIntensity;
            
            // Add time-based wear fluctuation
            float wearFluctuation = sin(time * _TapeWearSpeed + uv.y * 10.0) * 0.5 + 0.5;
            wear *= lerp(0.8, 1.2, wearFluctuation);
            
            // Create wear color (darkening and desaturation)
            float3 wearColor = lerp(col, dot(col, float3(0.299, 0.587, 0.114)).xxx * 0.7, wear);
            
            return lerp(col, wearColor, wear * _TapeWearAmount);
        }

        // Color degradation effect implementation
        float3 applyColorDegradation(float3 col, float2 uv, float time)
        {
            // Generate color noise
            float3 colorNoise = float3(
                hash(uv * _ColorNoiseScale + time, time),
                hash(uv * _ColorNoiseScale + time + 1.0, time),
                hash(uv * _ColorNoiseScale + time + 2.0, time)
            );
            
            // Apply color tint to noise
            colorNoise = lerp(float3(1,1,1), _ColorNoiseTint.rgb, colorNoise * _ColorNoiseIntensity);
            
            // Create color fading effect
            float luminance = dot(col, float3(0.299, 0.587, 0.114));
            float3 fadedColor = lerp(col, luminance.xxx, _ColorFading);
            
            // Apply color shifting
            float shift = sin(time * 0.5 + uv.y * 2.0) * 0.01 * _ColorFading;
            fadedColor.r = lerp(fadedColor.r, tex2D(_MainTex, uv + float2(shift, 0)).r, _ColorFading * 0.5);
            fadedColor.b = lerp(fadedColor.b, tex2D(_MainTex, uv - float2(shift, 0)).b, _ColorFading * 0.5);
            
            return fadedColor * colorNoise;
        }
        
        // Volumetric glow calculation
        float3 calculateVolumetricGlow(float2 uv, float3 baseColor, float2 baseUV)
        {
            float3 totalGlow = baseColor * _CoreIntensity;
            float stepSize = (_OuterRadius - _InnerRadius) / _SampleCount;
            
            for(float i = 0; i < _SampleCount; i++)
            {
                float angle = i * PI * 2.0 * (1.0 / _SampleCount) * 8.0;
                float radius = lerp(_InnerRadius, _OuterRadius, i / _SampleCount);
                
                float2 offset = float2(cos(angle), sin(angle));
                float3 sampleColor = sampleVolumetric(uv, offset, radius, baseUV);
                
                // Progressive weighting
                float weight = exp(-i / (_SampleCount * 0.5));
                totalGlow += sampleColor * weight * _GlowIntensity;
            }
            
            // Apply color temperature and final adjustments
            totalGlow = adjustColorTemp(totalGlow, _ColorTemp);
            totalGlow = pow(totalGlow, _GlowPower);
            
            return totalGlow;
        }
		
		// Calculate glitch effect intensity
        float calculateGlitchAmount(float time, float2 uv)
        {
            float cyclePeriod = _GlitchInterval;
            float cycleTime = fmod(time, cyclePeriod);
            float probabilityThreshold = _GlitchChance * 0.01;
            float cycleHash = hash(floor(time / cyclePeriod).xx, time);
            
            if (cycleHash > probabilityThreshold) {
                return 0;
            }
            
            float fadeIn = smoothstep(0.0, 0.1, cycleTime);
            float fadeOut = smoothstep(_GlitchDuration - 0.1, _GlitchDuration, cycleTime);
            
            return fadeIn * (1.0 - fadeOut);
        }

        // Calculate glitch displacement
        float2 calculateGlitchOffset(float2 uv, float time, float glitchAmount)
        {
            float2 glitchOffset = 0;
            if (glitchAmount > 0)
            {
                // Create violent horizontal tearing
                float rapidTime = time * 60.0;
                float lineShift = floor(uv.y * 50.0); // Create horizontal bands
                float lineNoise = hash(float2(lineShift, floor(rapidTime * 2.0)), rapidTime);
                
                // Extreme horizontal displacement
                float tearAmount = ((lineNoise * 2.0 - 1.0) * _GlitchStrength * glitchAmount * 50.0) * step(0.5, lineNoise);
                glitchOffset.x = tearAmount;
                
                // Add sudden large horizontal jumps
                float jumpInterval = floor(rapidTime * 4.0);
                float jumpNoise = hash(float2(jumpInterval, 0), rapidTime);
                if (jumpNoise > 0.7) {
                    glitchOffset.x += (jumpNoise - 0.5) * _GlitchStrength * 100.0;
                }
            }
            return glitchOffset;
        }

        // Sample texture with combined effects
        float3 sampleWithEffects(sampler2D tex, float2 uv, float time, float glitchAmount)
        {
            float2 wave = float2(
                sin(uv.y * _WaveFreqY + time * _WaveSpeedY),
                cos(uv.x * _WaveFreqX + time * _WaveSpeedX)
            ) * _WaveStrength;

            float3 col = tex2D(tex, uv + wave).rgb;
            
            // Apply extreme chromatic aberration during glitch
            if (glitchAmount > 0) {
                float rapidTime = time * 60.0;
                float horizontalShift = _ChromaticStrength * 5.0 * glitchAmount;
                
                // Add random jitter to the color channels
                float jitterAmount = hash(float2(floor(rapidTime * 4.0), 0), rapidTime) * glitchAmount * 0.1;
                
                // Sample red and blue channels with extreme separation
                col.r = tex2D(tex, uv + float2(horizontalShift + jitterAmount, 0) + wave).r;
                col.b = tex2D(tex, uv + float2(-horizontalShift - jitterAmount, 0) + wave).b;
                
                // Add color distortion during peak glitch
                if (glitchAmount > 0.7) {
                    col.r = lerp(col.r, col.r * 1.5, glitchAmount);
                    col.b = lerp(col.b, col.b * 1.5, glitchAmount);
                }
            }
            
            return col;
        }
        
        // Calculate inversion segments
        float2 getSegmentCoords(float2 uv, float time)
        {
            float2 rotatedUV = rotate2D(uv, _InversionRotation);
            float2 scaledUV = (rotatedUV - 0.5) * _InversionScale + 0.5;
            float2 segments = float2(_InversionSegmentsX, _InversionSegmentsY);
            
            if (_RandomizeSegments > 0)
            {
                float2 variation = float2(
                    hash(floor(scaledUV * segments.x).xx, time),
                    hash(floor(scaledUV * segments.y).xx, time + 1.0)
                ) * _SegmentVariation;
                
                segments *= (1.0 + variation - _SegmentVariation * 0.5);
            }
            
            return floor(scaledUV * segments);
        }

        // Determine if a segment should be inverted
        float shouldInvertSegment(float2 uv, float time, float glitchAmount)
        {
            float2 segCoords = getSegmentCoords(uv, time);
            float shouldInvert = 0;
            
            if (_InversionMode == 0) // Vertical
            {
                shouldInvert = hash(float2(segCoords.y, floor(time * 100)), time) < _InversionProbability;
            }
            else if (_InversionMode == 1) // Horizontal
            {
                shouldInvert = hash(float2(segCoords.x, floor(time * 100)), time) < _InversionProbability;
            }
            else // Grid
            {
                shouldInvert = hash(segCoords + floor(time * 100), time) < _InversionProbability;
            }
            
            float2 segPos = frac(uv * float2(_InversionSegmentsX, _InversionSegmentsY));
            float edgeFalloff = 1.0;
            
            if (_InversionMode == 0)
            {
                edgeFalloff = smoothstep(0, 0.1, segPos.y) * smoothstep(1, 0.9, segPos.y);
            }
            else if (_InversionMode == 1)
            {
                edgeFalloff = smoothstep(0, 0.1, segPos.x) * smoothstep(1, 0.9, segPos.x);
            }
            else
            {
                float edgeX = smoothstep(0, 0.1, segPos.x) * smoothstep(1, 0.9, segPos.x);
                float edgeY = smoothstep(0, 0.1, segPos.y) * smoothstep(1, 0.9, segPos.y);
                edgeFalloff = edgeX * edgeY;
            }
            
            return shouldInvert * edgeFalloff * glitchAmount;
        }
		
		// Surface shader implementation
		void surf(Input IN, inout SurfaceOutput o)
		{
			float time = _Time.y;
			float2 baseUV = IN.uv_MainTex;
			float2 uv = baseUV;
			
			// Apply scrolling effect if enabled
			if (_EnableScroll > 0)
			{
				float2 scrollOffset = float2(_ScrollSpeedX, _ScrollSpeedY) * time + _ScrollOffset.xy;
				uv = frac(uv + scrollOffset);
			}
			
			// Calculate base color and effects
			float3 baseColor = tex2D(_MainTex, uv).rgb;
			float glitchAmount = calculateGlitchAmount(time, uv);
			float2 glitchOffset = calculateGlitchOffset(uv, time, glitchAmount);
			
			// Apply combined effects and calculate volumetric glow
			float3 col = sampleWithEffects(_MainTex, uv + glitchOffset, time, glitchAmount);
			float3 volumetricGlow = calculateVolumetricGlow(baseUV + glitchOffset, col, baseUV);
			
			// Apply scan lines
			float scanLine = frac(uv.y * _ScanLineCount - time * _ScanLineSpeed);
			float scanIntensity = lerp(1.0, abs(sin(scanLine * PI)), _ScanLineIntensity * 0.5);

			// Apply tape wear effect
			volumetricGlow = applyTapeWear(volumetricGlow, uv, time);
			
			// Apply color degradation effect
			volumetricGlow = applyColorDegradation(volumetricGlow, uv, time);
			
			// Apply color inversion with probability check
			if (_UseInversion > 0 && glitchAmount > 0)
			{
				// Create multiple entropy sources for randomization
				float timeHash = hash(floor(time * 100).xx, time);
				float uvHash = hash(uv, time * 0.1);
				float extraHash = hash(float2(timeHash, uvHash), time * 0.5);
				
				// Combine hashes and apply stricter probability
				float inversionRoll = timeHash * uvHash * extraHash;
				float adjustedProbability = _InversionProbability * _InversionProbability * _InversionProbability;
				
				if (inversionRoll < adjustedProbability)
				{
					float invertAmount = shouldInvertSegment(uv, time, glitchAmount);
					if (invertAmount > 0)
					{
						volumetricGlow = lerp(volumetricGlow, 1 - volumetricGlow, invertAmount);
					}
				}
			}
			
			// Final color composition
			float3 finalColor = volumetricGlow * _EmissionColor.rgb * scanIntensity;
			
			// Add subtle pulsing to the glow
			float pulse = 1.0 + sin(time * _PulseSpeed) * 0.1;
			finalColor *= pulse;
			
			o.Emission = finalColor;
			o.Alpha = 1;
		}
        
        ENDCG
    }
    FallBack "Diffuse"
}
