// floating/flickering emissive hearts with glitter effect (can be disabled) and parallax
// public domain idc
// forked from https://www.shadertoy.com/view/cdlcDN
Shader "_aa/HeartsEyeShader"
{
Properties
	{
		_MainTex ("Eye Texture", 2D) = "white" {}
		_EffectSize ("Effect Size", Range(0, 0.5)) = 0.274
		_EffectEdgeSmoothing ("Effect Edge Smoothing", Range(0, 0.1)) = 0.035
		[Toggle] _OverlayPupil ("Overlay Pupil", Float) = 0
		_PupilSize ("Pupil Size", Range(0, 0.5)) = 0.166
		_PupilEdgeSmoothing ("Pupil Edge Smoothing", Range(0, 0.1)) = 0.0094
		_PupilColor ("Pupil Color", Color) = (0, 0, 0, 1)
		_PupilOffsetX ("Pupil Offset X", Range(-0.5, 0.5)) = 0
		_PupilOffsetY ("Pupil Offset Y", Range(-0.5, 0.5)) = 0.015
		_HeartColor ("Heart Color", Color) = (1, 0.753, 0.796, 1)
		_HeartEmissionColor ("Heart Emission Color", Color) = (1, 0.753, 0.796, 1)
		_HeartEmissionIntensity ("Heart Emission Intensity", Range(0, 10)) = 3.35
		_HeartIntensity ("Heart Intensity", Range(0, 1)) = 0.35
		_HeartSpeed ("Heart Animation Speed", Range(0, 10)) = 1
		_GlitterColor ("Glitter Color", Color) = (1, 0.98, 0.855, 1)
		_GlitterDensity ("Glitter Density", Range(10, 500)) = 500
		_GlitterIntensity ("Glitter Intensity", Range(0, 5)) = 2.06
		_GlitterSpeed ("Glitter Speed", Range(0, 20)) = 10
		_GlitterSize ("Glitter Size", Range(0.001, 1.0)) = 0.2
		_GlitterSharpness ("Glitter Sharpness", Range(1, 50)) = 20
		_GlitterContrast ("Glitter Contrast", Range(1, 10)) = 3
		_ParallaxStrength ("Parallax Strength", Range(0, 0.1)) = 0.03
        _DoFStrength ("Depth of Field Strength", Range(0, 1)) = 0.5
        _DoFFocalDistance ("Depth of Field Focal Distance", Range(0, 1)) = 0.5
        _DoFFocalRange ("Depth of Field Focal Range", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert alpha vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;
        float _EffectSize;
        float _EffectEdgeSmoothing;
        float _PupilSize;
        float _PupilEdgeSmoothing;
        fixed4 _PupilColor;
        float _PupilOffsetX;
        float _PupilOffsetY;
        fixed4 _HeartColor;
        fixed4 _HeartEmissionColor;
        float _HeartEmissionIntensity;
        float _HeartIntensity;
        float _HeartSpeed;
        fixed4 _GlitterColor;
        float _GlitterDensity;
        float _GlitterIntensity;
        float _GlitterSpeed;
        float _GlitterSize;
        float _GlitterSharpness;
        float _GlitterContrast;
        float _ParallaxStrength;
        float _OverlayPupil;
        float _DoFStrength;
        float _DoFFocalDistance;
        float _DoFFocalRange;
		
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
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        }

        float2 ParallaxOffset(float2 uv, float2 viewDir) {
            float2 centerOffset = uv - 0.5;
            float distFromCenter = length(centerOffset);
            float height = 1 - smoothstep(0, _EffectSize, distFromCenter);
            return viewDir * (height * _ParallaxStrength);
        }
		
        float CalculateDoF(float3 worldPos)
        {
            float depth = length(worldPos - _WorldSpaceCameraPos);
            float focusRange = _DoFFocalRange * 10; // Adjust scale as needed
            float focusDistance = _DoFFocalDistance * 10; // Adjust scale as needed
            
            float dof = saturate(abs(depth - focusDistance) / focusRange);
            return dof * _DoFStrength;
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
            float size = (frac(n * 345.32) * 0.5 + 0.5) * _GlitterSize * 2.0;
            
            float2 center = frac(uv * _GlitterDensity) - 0.5;
            float t2 = frac(t * _GlitterSpeed + n);
            float radius = size * (0.8 + 0.2 * sin(t2 * 6.28318));
            
            float dist = length(center);
            float star = pow(saturate(1.0 - dist / radius), _GlitterSharpness);
            
            star *= 0.5 + 0.5 * sin(t * 15.0 + n * 6.28318);
            
            star = pow(star, _GlitterContrast);
            
            return star * step(0.15, n);
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            float dofFactor = CalculateDoF(IN.worldPos);

            float2 parallaxOffset = ParallaxOffset(IN.uv_MainTex, normalize(IN.viewDir).xy);
            float2 uv = IN.uv_MainTex + parallaxOffset;
            
            fixed4 c = tex2D(_MainTex, uv);
            
            float2 centeredUV = uv - 0.5;
            float distFromCenter = length(centeredUV);
            
            float effectMask = smoothstep(_EffectSize + _EffectEdgeSmoothing, _EffectSize - _EffectEdgeSmoothing, distFromCenter);
            
            // Apply pupil offset
            float2 pupilCenter = float2(_PupilOffsetX, _PupilOffsetY);
            float distFromPupilCenter = length(centeredUV - pupilCenter);
            float pupilMask = 1 - smoothstep(_PupilSize - _PupilEdgeSmoothing, _PupilSize + _PupilEdgeSmoothing, distFromPupilCenter);

            float2 heartUV = centeredUV * 10.0;
            float t = _Time.y * _HeartSpeed;

            float heartPattern = 0.0;
            for (int i = 0; i < 9; i++) {
                float2 offs = float2(i % 3 - 1, i / 3 - 1);
                float2 p = GetPos(floor(heartUV), offs, t);
                float d = -sdHeart((frac(heartUV) - p) * 3.0);
                float s = smoothstep(0.0, 0.2, d);
                float pulse = sin((frac(p.x) + frac(p.y) + t * 0.5) * 3.0) * 0.5 + 1.0;
                pulse = pow(pulse, 3.0);
                s *= pulse;
                heartPattern += s;
            }

            float overlayMask = lerp(1 - pupilMask, 1, _OverlayPupil);
            heartPattern *= _HeartIntensity * effectMask * overlayMask;

            float glitter = 0;
            for (int i = 0; i < 3; i++) {
                float t = _Time.y + float(i) * 1.61803;
                float scale = 1.0 + float(i) * 0.5;
                glitter += Glitter(uv * scale, t) / scale;
            }
            glitter = saturate(glitter) * _GlitterIntensity * effectMask * overlayMask;

            fixed3 heartColor = lerp(c.rgb, _HeartColor.rgb, heartPattern);
            
            // Apply DoF blur only to the heart pattern and glitter
            float2 dofOffset = float2(dofFactor * 0.01, dofFactor * 0.01);
            fixed4 blurredHeart = tex2D(_MainTex, uv + dofOffset);
            fixed3 dofHeartColor = lerp(heartColor, blurredHeart.rgb, dofFactor * effectMask * overlayMask);

            // Apply pupil color with respect to its alpha
            fixed3 pupilColor = lerp(dofHeartColor, _PupilColor.rgb, pupilMask * _PupilColor.a);
            
            fixed3 finalColor = lerp(pupilColor, c.rgb, 1 - effectMask);

            o.Albedo = finalColor;
            
            o.Emission = _HeartEmissionColor.rgb * heartPattern * _HeartEmissionIntensity * effectMask * overlayMask + 
                         _GlitterColor.rgb * glitter * _GlitterIntensity * effectMask * overlayMask;
            
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}