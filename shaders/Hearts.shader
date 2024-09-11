// floating/flickering emissive hearts with glitter effect (can be disabled) and parallax
// public domain idc
// forked from https://www.shadertoy.com/view/cdlcDN
Shader "Custom/HeartsEyeShader"
{
    Properties
    {
        _MainTex ("Eye Texture", 2D) = "white" {}
        _IrisSize ("Iris Size", Range(0, 0.5)) = 0.25
        _IrisEdgeSmoothing ("Iris Edge Smoothing", Range(0, 0.1)) = 0.01
        _IrisBaseColor ("Iris Base Color", Color) = (0.5, 0.5, 0.5, 1)
        _IrisRedChannel ("Iris Red", Range(0, 1)) = 0.5
        _IrisGreenChannel ("Iris Green", Range(0, 1)) = 0.5
        _IrisBlueChannel ("Iris Blue", Range(0, 1)) = 0.5
        _GrayscaleAmount ("Grayscale Amount", Range(0, 1)) = 0
        _HeartColor ("Heart Color", Color) = (0.957, 0.384, 0.631, 1)
        _HeartEmissionColor ("Heart Emission Color", Color) = (1, 1, 1, 1)
        _HeartEmissionIntensity ("Heart Emission Intensity", Range(0, 10)) = 1
        _HeartIntensity ("Heart Intensity", Range(0, 1)) = 0.5
        _HeartSpeed ("Heart Animation Speed", Range(0, 10)) = 1
        _GlitterColor ("Glitter Color", Color) = (1, 1, 1, 1)
        _GlitterDensity ("Glitter Density", Range(10, 100)) = 50
        _GlitterIntensity ("Glitter Intensity", Range(0, 1)) = 0.5
        _GlitterSpeed ("Glitter Speed", Range(0, 10)) = 1
        _ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0.02
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert alpha vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;
        float _IrisSize;
        float _IrisEdgeSmoothing;
        fixed4 _IrisBaseColor;
        float _IrisRedChannel;
        float _IrisGreenChannel;
        float _IrisBlueChannel;
        float _GrayscaleAmount;
        fixed4 _HeartColor;
        fixed4 _HeartEmissionColor;
        float _HeartEmissionIntensity;
        float _HeartIntensity;
        float _HeartSpeed;
        fixed4 _GlitterColor;
        float _GlitterDensity;
        float _GlitterIntensity;
        float _GlitterSpeed;
        float _ParallaxStrength;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
        };

        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            TANGENT_SPACE_ROTATION;
            o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
        }

        float2 ParallaxOffset(float2 uv, float2 viewDir) {
            float2 centerOffset = uv - 0.5;
            float distFromCenter = length(centerOffset);
            float height = 1 - smoothstep(0, _IrisSize, distFromCenter);
            return viewDir * (height * _ParallaxStrength);
        }

        float N21(float2 p) {
            p = frac(p * float2(123.34, 345.45));
            p += dot(p, p + 34.345);
            return frac(p.x * p.y);
        }

        float2 GetPos(float2 id, float2 offs, float t) {
            float n = N21(id + offs);
            float a = t + n * 6.2831;
            return offs + float2(sin(a), cos(a)) * 0.3;
        }

        float sdHeart(float2 p) {
            p.x = abs(p.x);
            float b = sqrt(2.0) * 0.25;
            if (p.y + p.x > 1.0)
                return length(p - float2(0.25, 0.75)) - b;
            return length(p - 0.5 * max(p.x + p.y, 0.0)) * sign(p.x - p.y);
        }

        float Glitter(float2 uv, float t) {
            float2 id = floor(uv * _GlitterDensity);
            float n = N21(id);
            float size = frac(n * 345.32);
            
            float star = 0.0;
            float2 center = frac(uv * _GlitterDensity) - 0.5;
            float t2 = frac(t + n);
            float radius = (0.5 * size * (1.0 - t2) * 0.5 + 0.01) * (sin(t * 2.0 + n) * 0.5 + 1.5);
            star = smoothstep(0.03 * size, 0.02 * size, length(center) - radius);
            
            return star * step(0.2, n);
        }

        fixed3 rgb2gray(fixed3 color) {
            return dot(color, fixed3(0.299, 0.587, 0.114));
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            float2 parallaxOffset = ParallaxOffset(IN.uv_MainTex, normalize(IN.viewDir).xy);
            float2 uv = IN.uv_MainTex + parallaxOffset;
            
            fixed4 c = tex2D(_MainTex, uv);
            
            float2 centeredUV = uv - 0.5;
            float distFromCenter = length(centeredUV);
            
            float irisMask = smoothstep(_IrisSize + _IrisEdgeSmoothing, _IrisSize - _IrisEdgeSmoothing, distFromCenter);

            float2 irisUV = centeredUV * 10.0;
            float t = _Time.y * _HeartSpeed;

            float heartPattern = 0.0;
            for (int i = 0; i < 9; i++) {
                float2 offs = float2(i % 3 - 1, i / 3 - 1);
                float2 p = GetPos(floor(irisUV), offs, t);
                float d = -sdHeart((frac(irisUV) - p) * 3.0);
                float s = smoothstep(0.0, 0.2, d);
                float pulse = sin((frac(p.x) + frac(p.y) + t * 0.5) * 3.0) * 0.5 + 1.0;
                pulse = pow(pulse, 3.0);
                s *= pulse;
                heartPattern += s;
            }

            heartPattern *= _HeartIntensity * irisMask;

            // Add glitter effect
            float glitter = Glitter(irisUV, _Time.y * _GlitterSpeed) * _GlitterIntensity * irisMask;

            // Create iris base color from sliders
            fixed3 irisBaseColor = fixed3(_IrisRedChannel, _IrisGreenChannel, _IrisBlueChannel);

            // Combine iris base color, heart pattern, and glitter
            fixed3 coloredIris = lerp(irisBaseColor, _HeartColor.rgb, heartPattern) + _GlitterColor.rgb * glitter;
            
            // Create grayscale version
            fixed3 grayIris = rgb2gray(coloredIris);

            // Blend between colored and grayscale versions
            fixed3 finalIrisColor = lerp(coloredIris, grayIris, _GrayscaleAmount);

            o.Albedo = lerp(c.rgb, finalIrisColor, irisMask);
            
            // Add emission to the hearts and glitter
            o.Emission = _HeartEmissionColor.rgb * heartPattern * _HeartEmissionIntensity * irisMask + 
                         _GlitterColor.rgb * glitter * _GlitterIntensity * irisMask;
            
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}