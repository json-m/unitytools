Shader "_aa/ProceduralMetal" {
    Properties {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Metallic ("Metallic", Range(0,1)) = 1.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        _BumpStrength ("Bump Strength", Range(0,1)) = 0.1
        _BumpScale ("Bump Scale", Range(1,100)) = 50
        _AnisotropyStrength ("Anisotropy Strength", Range(0,1)) = 0.2
        _AnisotropyAngle ("Anisotropy Angle", Range(0,360)) = 0
        _ReflectionSharpness ("Reflection Sharpness", Range(0,1)) = 0.95
        _FresnelStrength ("Fresnel Strength", Range(0,5)) = 1
    }
    SubShader {
        Tags {"RenderType"="Opaque"}
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow
        #pragma target 3.0
        #pragma multi_compile_instancing
        #pragma instancing_options assumeuniformscaling

        #include "UnityPBSLighting.cginc"

        struct Input {
            float3 worldPos;
            float3 worldNormal; INTERNAL_DATA
            float3 viewDir;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(fixed4, _BaseColor)
        UNITY_INSTANCING_BUFFER_END(Props)

        half _Metallic;
        half _Smoothness;
        half _BumpStrength;
        half _BumpScale;
        half _AnisotropyStrength;
        half _AnisotropyAngle;
        half _ReflectionSharpness;
        half _FresnelStrength;

        // Simplified hash function
        half hash(half2 st) {
            return frac(sin(dot(st.xy, half2(12.9898h, 78.233h))) * 43758.5453123h);
        }

        // Simplified noise function
        half noise(half2 st) {
            half2 i = floor(st);
            half2 f = frac(st);
            half a = hash(i);
            half b = hash(i + half2(1.0h, 0.0h));
            half c = hash(i + half2(0.0h, 1.0h));
            half d = hash(i + half2(1.0h, 1.0h));
            half2 u = f * f * (3.0h - 2.0h * f);
            return lerp(a, b, u.x) + (c - a) * u.y * (1.0h - u.x) + (d - b) * u.x * u.y;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            UNITY_SETUP_INSTANCE_ID(IN);
            fixed4 c = UNITY_ACCESS_INSTANCED_PROP(Props, _BaseColor);
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;

            // Simplified normal calculation
            half2 uv = IN.worldPos.xy * _BumpScale;
            half n = noise(uv);
            half2 offset = half2(0.1h, 0.1h);
            half3 normal = normalize(half3(
                noise(uv + offset.xy) - noise(uv - offset.xy),
                noise(uv + offset.yx) - noise(uv - offset.yx),
                0.5h
            ));
            o.Normal = lerp(half3(0,0,1), normal, _BumpStrength);

            // Simplified anisotropy
            half anisotropyAngle = radians(_AnisotropyAngle);
            half2 anisotropicDir = half2(cos(anisotropyAngle), sin(anisotropyAngle));
            o.Normal.xy = lerp(o.Normal.xy, anisotropicDir, _AnisotropyStrength);
            o.Normal = normalize(o.Normal);

            // Optimized reflection calculation
            half3 worldNormal = WorldNormalVector(IN, o.Normal);
            half3 worldViewDir = normalize(UnityWorldSpaceViewDir(IN.worldPos));
            half3 worldRefl = reflect(-worldViewDir, worldNormal);

            half mip = (1.0h - _ReflectionSharpness) * 6.0h;
            half3 envReflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, worldRefl, mip);

            // Simplified Fresnel
            half fresnel = pow(1.0h - saturate(dot(worldNormal, worldViewDir)), 4.0h) * _FresnelStrength;

            o.Emission = envReflection * o.Metallic * (fresnel + (1.0h - o.Smoothness));
        }
        ENDCG
    }
    SubShader {
        Tags {"RenderType"="Opaque"}
        LOD 150

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow
        #pragma target 3.0
        #pragma multi_compile_instancing
        #pragma instancing_options assumeuniformscaling

        struct Input {
            float3 worldNormal; INTERNAL_DATA
            float3 viewDir;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(fixed4, _BaseColor)
        UNITY_INSTANCING_BUFFER_END(Props)

        half _Metallic;
        half _Smoothness;
        half _FresnelStrength;

        void surf (Input IN, inout SurfaceOutputStandard o) {
            UNITY_SETUP_INSTANCE_ID(IN);
            fixed4 c = UNITY_ACCESS_INSTANCED_PROP(Props, _BaseColor);
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;

            half3 worldNormal = WorldNormalVector(IN, o.Normal);
            half3 worldViewDir = normalize(IN.viewDir);
            half3 worldRefl = reflect(-worldViewDir, worldNormal);

            half3 envReflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, worldRefl);

            half fresnel = pow(1.0h - saturate(dot(worldNormal, worldViewDir)), 4.0h) * _FresnelStrength;

            o.Emission = envReflection * o.Metallic * (fresnel + (1.0h - o.Smoothness));
        }
        ENDCG
    }
    FallBack "Standard"
}
