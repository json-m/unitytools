// inspired by / some stuff for droplet/trail ported from https://www.shadertoy.com/view/ltffzl
// probably a lot of leftover stuff here to be cleaned up or unified
// public domain idc
Shader "_aa/RaindropShader"
{
    Properties
    {
        [Header(Main Textures)]
        _MainTex ("Eye Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        
        [Space(10)]
        [Header(Subsurface Scattering)]
        _SubsurfaceColor ("Subsurface Color", Color) = (1,0,0,1)
        _SubsurfaceStrength ("Subsurface Strength", Range(0,1)) = 0.5
        
        [Space(10)]
        [Header(Environment Interaction)]
        _EnvironmentReactivity ("Environment Reactivity", Range(0,1)) = 0.5
        _AnisotropicStrength ("Anisotropic Strength", Range(0,1)) = 0.5
        _AnisotropicDirection ("Anisotropic Direction", Vector) = (1,0,0,0)
        
        [Space(10)]
        [Header(Surface Properties)]
        _BaseEyeSmoothness ("Base Eye Smoothness", Range(0,1)) = 0.5
        _RaindropMetallic ("Raindrop Metallic", Range(0,1)) = 0.015
        _RaindropSmoothness ("Raindrop Smoothness", Range(0,1)) = 0.666
        
        [Space(10)]
        [Header(Rain Effects)]
        _RainAmount ("Rain Amount", Range(0, 1)) = 0.5
        _DropSize ("Drop Size", Range(0.5, 2)) = 1
        _Speed ("Animation Speed", Range(0.1, 2)) = 1
        _WetnessAmount ("Wetness Amount", Range(0, 1)) = 0.65
        _MergeThreshold ("Merge Threshold", Range(0, 1)) = 1
        _Motion ("Droplet Impact Motion", Range(0, 1)) = 0.3
        
        [Space(10)]
        [Header(Fog Effects)]
        _FogAmount ("Fog Amount", Range(0, 1)) = 0.5
        _FogTrailStrength ("Fog Trail Strength", Range(0, 1)) = 0.637
        _TrailClearStrength ("Trail Clear Strength", Range(0, 1)) = 0.75
        
        [Space(10)]
        [Header(Visual Effects)]
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.5
        _ReflectionStrength ("Reflection Strength", Range(0,0.015)) = 0.005
        _EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _EmissionStrength ("Emission Strength", Range(0,1)) = 0
        
        [Space(10)]
        [Header(Lighting)]
        _AmbientOcclusionStrength ("Ambient Occlusion Strength", Range(0,1)) = 0.5
        _MinimumBrightness ("Minimum Brightness", Range(0,1)) = 0.1
        _RimLightColor ("Rim Light Color", Color) = (1,1,1,1)
        _RimLightPower ("Rim Light Power", Range(0,10)) = 3
        _RimLightStrength ("Rim Light Strength", Range(0,1)) = 0.5
        _FresnelStrength ("Fresnel Strength", Range(0,5)) = 5.0
        _LightSensitivity ("Light Sensitivity", Range(0,2)) = 1.0
        _BaseAmbientLight ("Base Ambient Light", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags {"RenderType"="Opaque"}
        LOD 200
        CGPROGRAM
        #pragma surface surf AnisotropicSSS fullforwardshadows
        #pragma target 3.0
        #include "UnityPBSLighting.cginc"

        // Main Textures
        sampler2D _MainTex;
        sampler2D _BumpMap;

        // Subsurface Scattering
        float4 _SubsurfaceColor;
        float _SubsurfaceStrength;

        // Environment Interaction
        float _EnvironmentReactivity;
        float _AnisotropicStrength;
        float4 _AnisotropicDirection;

        // Surface Properties
        float _BaseEyeSmoothness;
        float _RaindropMetallic;
        float _RaindropSmoothness;

        // Rain Effects
        float _RainAmount;
        float _DropSize;
        float _Speed;
        float _WetnessAmount;
        float _MergeThreshold;
        float _Motion;

        // Fog Effects
        float _FogAmount;
        float _FogTrailStrength;
        float _TrailClearStrength;

        // Visual Effects
        float _DistortionStrength;
        float _ReflectionStrength;
        float4 _EmissionColor;
        float _EmissionStrength;

        // Lighting
        float _AmbientOcclusionStrength;
        float _MinimumBrightness;
        float4 _RimLightColor;
        float _RimLightPower;
        float _RimLightStrength;
        float _FresnelStrength;
        float _LightSensitivity;
        float _BaseAmbientLight;

        // Additional variables (if any)
        float _FogTrailVisibility;
        float _FogRegrowthRate;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 viewDir;
            float3 worldNormal; INTERNAL_DATA
            float3 worldPos;
            float3 worldRefl;
        };
		
		// Optimization 1: Precompute constants
        static const float PI = 3.14159265359;
        static const float2 DROP_SIZE_VEC = float2(6.0, 1.0);

        // Optimization 2: Use macros for frequently used operations
        #define FRAC(x) frac((x))
        #define N(t) FRAC(sin((t) * 12345.564) * 7658.76)

        float3 N13(float p) {
            float3 p3 = FRAC(float3(p, p, p) * float3(.1031, .11369, .13787));
            p3 += dot(p3, p3.yzx + 19.19);
            return FRAC(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
        }

        float Saw(float b, float t) {
            return smoothstep(0.0, b, t) * smoothstep(1.0, b, t);
        }

		float2 DropLayer2(float2 uv, float t) {
			float2 UV = uv;
			
			uv.y += t * 0.75;
			float2 a = float2(6.0, 1.0) * _DropSize;
			float2 grid = a * 2.0;
			float2 id = floor(uv * grid);
			
			float colShift = N(id.x); 
			uv.y += colShift;
			
			id = floor(uv * grid);
			float3 n = N13(id.x * 35.2 + id.y * 2376.1);
			float2 st = frac(uv * grid) - float2(0.5, 0);
			
			float x = n.x - 0.5;
			
			float y = UV.y * 20.0;
			float wiggle = sin(y + sin(y));
			x += wiggle * (0.5 - abs(x)) * (n.z - 0.5);
			x *= 0.7;
			float ti = frac(t + n.z);
			
			// Blend between random position and downward motion
			float randomY = (Saw(0.85, ti) - 0.5) * 0.9 + 0.5;
			float downwardY = 1.0 - abs(1.0 - 2.0 * frac(ti + UV.y));
			
			// Adjust this value to balance randomness and downward motion
			y = lerp(randomY, downwardY, _Motion); 
			
			float2 p = float2(x, y);
			
			float d = length((st - p) * a.yx);
			
			float mainDrop = smoothstep(0.4, 0.0, d);
			
			float r = sqrt(smoothstep(1.0, y, st.y));
			float cd = abs(st.x - x);
			float trail = smoothstep(0.23 * r, 0.15 * r * r, cd);
			float trailFront = smoothstep(-0.02, 0.02, st.y - y);
			trail *= trailFront * r * r;
			
			y = UV.y;
			float trail2 = smoothstep(0.2 * r, 0.0, cd);
			float droplets = max(0.0, (sin(y * (1.0 - y) * 120.0) - st.y)) * trail2 * trailFront * n.z;
			y = frac(y * 10.0) + (st.y - 0.5);
			float dd = length(st - float2(x, y));
			droplets = smoothstep(0.3, 0.0, dd);
			float m = mainDrop + droplets * r * trailFront;
			
			return float2(m, trail);
		}

		
		float StaticDrops(float2 uv, float t) {
            uv *= 40.0 * _DropSize;
            
            float2 id = floor(uv);
            uv = frac(uv) - 0.5;
            float3 n = N13(id.x * 107.45 + id.y * 3543.654);
            float2 p = (n.xy - 0.5) * 0.7;
            float d = length(uv - p);
            
            float fade = Saw(0.025, frac(t + n.z));
            float c = smoothstep(0.3, 0.0, d) * frac(n.z * 10.0) * fade;
            return c;
        }

        float2 Drops(float2 uv, float t, float l0, float l1, float l2) {
            float s = StaticDrops(uv, t) * l0; 
            float2 m1 = DropLayer2(uv, t) * l1;
            float2 m2 = DropLayer2(uv * 1.85, t) * l2;
            
            float c = s + m1.x + m2.x;
            c = smoothstep(.3, 1., c);
            
            return float2(c, max(m1.y * l0, m2.y * l1));
        }

        float FogTrail(float2 uv, float t)
        {
            float2 dropData = Drops(uv, t, 1, 1, 1);
            float trail = dropData.y;
            
            return saturate(trail * _FogTrailStrength);
        }
		
        float3 AnisotropicBRDF(float3 normal, float3 tangent, float3 viewDir, float3 lightDir, float roughness, float anisotropy)
        {
            float3 halfDir = normalize(lightDir + viewDir);
            float NdotL = saturate(dot(normal, lightDir));
            float NdotH = saturate(dot(normal, halfDir));
            float NdotV = saturate(dot(normal, viewDir));
            float TdotH = dot(tangent, halfDir);

            float rx = roughness * (1.0 + anisotropy);
            float ry = roughness * (1.0 - anisotropy);

            float D = NdotH * NdotH * (rx * rx - 1.0) + 1.0;
            D = PI * rx * ry * D * D;

            float F = pow(1.0 - NdotV, 5.0);
            float G = 2.0 / (1.0 + sqrt(1.0 + (roughness * roughness) * (1.0 / (NdotH * NdotH) - 1.0)));

            return max(0.0, (F * D * G) / (4.0 * NdotL * NdotV));
        }

        half4 LightingAnisotropicSSS(SurfaceOutputStandardSpecular s, half3 viewDir, UnityGI gi)
        {
            half4 pbr = LightingStandardSpecular(s, viewDir, gi);

            half3 H = normalize(gi.light.dir + s.Normal * _SubsurfaceStrength);
            half VdotH = pow(saturate(dot(viewDir, -H)), 4.0);
            half3 sss = _SubsurfaceColor.rgb * VdotH * _SubsurfaceStrength;

            half3 aniso = AnisotropicBRDF(s.Normal, _AnisotropicDirection.xyz, viewDir, gi.light.dir, 1.0 - s.Smoothness, _AnisotropicStrength);

            half4 c = pbr;
            c.rgb += sss * gi.light.color;
            c.rgb += aniso * gi.light.color * s.Specular;

            c.rgb *= _LightSensitivity;

            return c;
        }
        
        void LightingAnisotropicSSS_GI(SurfaceOutputStandardSpecular s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandardSpecular_GI(s, data, gi);
        }

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            float2 uv = IN.uv_MainTex;
            float t = _Time.y * 0.2 * _Speed;

            // Calculate drop layers
            float staticDrops = smoothstep(-0.5, 1.0, _RainAmount) * 2.0;
            float layer1 = smoothstep(0.25, 0.75, _RainAmount);
            float layer2 = smoothstep(0.0, 0.5, _RainAmount);
            
            // Calculate raindrop effects
            float2 c = Drops(uv, t, staticDrops, layer1, layer2);

            // Optimization 4: Combine distortion calculations
            float2 e = float2(0.001, 0.0);
            float2 n = float2(
                Drops(uv + e, t, staticDrops, layer1, layer2).x - c.x,
                Drops(uv + e.yx, t, staticDrops, layer1, layer2).x - c.x
            ) * _DistortionStrength;

            // Apply distortion to UV
            float2 distortedUV = uv + n;

            // Sample textures
            fixed4 c_albedo = tex2D(_MainTex, distortedUV);
            o.Normal = UnpackNormal(tex2D(_BumpMap, distortedUV));

            // Set initial albedo from texture
            o.Albedo = c_albedo.rgb;

            // Environment-reactive color shifts
            float3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos));
            float3 worldNormal = WorldNormalVector(IN, o.Normal);
            float fresnel = pow(1.0 - saturate(dot(worldViewDir, worldNormal)), _FresnelStrength);
            float3 envReflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflect(-worldViewDir, worldNormal)).rgb;
            o.Albedo = lerp(o.Albedo, o.Albedo * envReflection, fresnel * _EnvironmentReactivity * 0.5);

            // Set surface properties
            float raindropMask = c.x;
            o.Specular = lerp(o.Specular, float3(_RaindropMetallic, _RaindropMetallic, _RaindropMetallic), raindropMask);
            o.Smoothness = lerp(_BaseEyeSmoothness, _RaindropSmoothness, raindropMask);

            // Setup for anisotropic specular
            o.Specular = lerp(o.Specular * _AnisotropicStrength * 0.5, o.Specular, raindropMask);

            // Add reflections
            float3 worldRefl = WorldReflectionVector(IN, o.Normal);
            float3 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);
            reflection = DecodeHDR(float4(reflection, 1), unity_SpecCube0_HDR);

            // Calculate rim lighting
            float rim = 1.0 - saturate(dot(worldViewDir, o.Normal));
            float3 rimLight = _RimLightColor.rgb * pow(rim, _RimLightPower) * _RimLightStrength * 0.5;

            // Combine reflection, emission, and rim lighting
            o.Emission = reflection * _ReflectionStrength * raindropMask * 0.5 + 
                         _EmissionColor.rgb * _EmissionStrength * 0.5 +
                         rimLight;

            // Apply ambient occlusion
            float ao = lerp(1, o.Albedo.r, _AmbientOcclusionStrength);
            o.Albedo *= ao;

            // Apply base ambient light
            float3 baseAmbient = float3(_BaseAmbientLight, _BaseAmbientLight, _BaseAmbientLight) * 0.5;
            o.Albedo += baseAmbient;
            o.Emission += baseAmbient;

            // Calculate fog effect
            float fogTrail = FogTrail(uv, t);
            float fogFactor = saturate(_FogAmount);

            // Apply fog as a subtle additive effect
            float3 fogColor = float3(1, 1, 1); // White fog
            float fogIntensity = fogFactor * 0.033;
            
            // Clear fog where droplets have passed
            float clearFactor = 1 - fogTrail * _TrailClearStrength;
            clearFactor = saturate(clearFactor);
            
            fogIntensity *= clearFactor;

            o.Albedo = lerp(o.Albedo, o.Albedo + fogColor * fogIntensity, fogFactor * 0.5);
            o.Emission = lerp(o.Emission, o.Emission + fogColor * fogIntensity * 0.25, fogFactor * 0.5);

            // Subtle smoothness adjustment
            o.Smoothness = lerp(o.Smoothness, lerp(o.Smoothness, o.Smoothness * 0.95, fogFactor), fogFactor);

            // Apply wetness
            o.Albedo = lerp(o.Albedo, o.Albedo * 0.85, _WetnessAmount * raindropMask);
            o.Smoothness = lerp(o.Smoothness, lerp(o.Smoothness, 1.0, 0.5), _WetnessAmount * raindropMask);

            // Ensure we don't exceed 1.0 for albedo and emission
            o.Albedo = saturate(o.Albedo);
            o.Emission = saturate(o.Emission);

            // Apply minimum brightness
            float finalBrightness = max(max(o.Albedo.r, o.Albedo.g), o.Albedo.b);
            finalBrightness = max(finalBrightness, max(max(o.Emission.r, o.Emission.g), o.Emission.b));
            if (finalBrightness < _MinimumBrightness) {
                float brightnessFactor = _MinimumBrightness / finalBrightness;
                o.Albedo = saturate(o.Albedo * brightnessFactor);
                o.Emission *= brightnessFactor;
            }
        }
        ENDCG
    }
    FallBack "Diffuse"
}
