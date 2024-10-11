Shader "_aa/ProceduralMetal" {
    Properties {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Metallic ("Metallic", Range(0,1)) = 1.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        _BumpStrength ("Bump Strength", Range(0,1)) = 0.1
        _BumpScale ("Bump Scale", Range(1,100)) = 50
        _MicroSurfaceScale ("Micro Surface Scale", Range(100,1000)) = 500
        _MicroSurfaceStrength ("Micro Surface Strength", Range(0,0.1)) = 0.01
        _AnisotropyStrength ("Anisotropy Strength", Range(0,1)) = 0.2
        _AnisotropyAngle ("Anisotropy Angle", Range(0,360)) = 0
        _ReflectionSharpness ("Reflection Sharpness", Range(0,1)) = 0.95
        _FresnelStrength ("Fresnel Strength", Range(0,5)) = 1
    }
    SubShader {
        Tags {"RenderType"="Opaque"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"

        struct Input {
            float3 worldPos;
            float3 worldNormal; INTERNAL_DATA
            float3 viewDir;
        };

        fixed4 _BaseColor;
        half _Metallic;
        half _Smoothness;
        half _BumpStrength;
        half _BumpScale;
        half _MicroSurfaceScale;
        half _MicroSurfaceStrength;
        half _AnisotropyStrength;
        half _AnisotropyAngle;
        half _ReflectionSharpness;
        half _FresnelStrength;

        // Improved hash function
        float2 hash2(float2 p) {
            p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
            return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
        }

        // Gradient Noise
        float gnoise(float2 p) {
            float2 i = floor(p);
            float2 f = frac(p);
    
            float2 u = f * f * (3.0 - 2.0 * f);

            return lerp(lerp(dot(hash2(i + float2(0.0,0.0)), f - float2(0.0,0.0)),
                             dot(hash2(i + float2(1.0,0.0)), f - float2(1.0,0.0)), u.x),
                        lerp(dot(hash2(i + float2(0.0,1.0)), f - float2(0.0,1.0)),
                             dot(hash2(i + float2(1.0,1.0)), f - float2(1.0,1.0)), u.x), u.y);
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            // Base color and metallic properties
            o.Albedo = _BaseColor.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;

            // Generate procedural normal map
            float2 uv = IN.worldPos.xy * _BumpScale;
            float n = gnoise(uv);
            float nx = gnoise(uv + float2(0.1, 0));
            float ny = gnoise(uv + float2(0, 0.1));
            float3 normal = normalize(float3(n - nx, n - ny, 1));

            // Add micro surface detail
            float2 microUV = IN.worldPos.xy * _MicroSurfaceScale;
            float microNoise = gnoise(microUV) * _MicroSurfaceStrength;
            normal = normalize(normal + float3(microNoise, microNoise, 0));

            o.Normal = lerp(float3(0,0,1), normal, _BumpStrength);

            // Apply anisotropy
            float anisotropyAngle = radians(_AnisotropyAngle);
            float3 anisotropicDir = normalize(float3(cos(anisotropyAngle), sin(anisotropyAngle), 0));
            o.Normal = normalize(lerp(o.Normal, anisotropicDir, _AnisotropyStrength));

            // Calculate reflection vector
            float3 worldNormal = WorldNormalVector(IN, o.Normal);
            float3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos));
            float3 worldRefl = reflect(-worldViewDir, worldNormal);

            // Sample environment reflection with adjusted mip level for sharpness
            float mip = (1 - _ReflectionSharpness) * 6;
            float3 envReflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, worldRefl, mip);

            // Apply Fresnel effect
            float fresnel = pow(1 - saturate(dot(worldNormal, worldViewDir)), 5) * _FresnelStrength;

            // Combine reflection with Fresnel
            o.Emission = envReflection * o.Metallic * (fresnel + (1 - o.Smoothness));
        }
        ENDCG
    }
    FallBack "Standard"
}
