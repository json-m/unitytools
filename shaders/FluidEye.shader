// use with noise texture, gives effect similar to flowing oil
// public domain idc
Shader "_aa/FluidEyeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FluidIntensity ("Fluid Intensity", Range(0, 1)) = 0.5
        _ColorShift ("Color Shift", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "Queue"="Geometry"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;
        float _FluidIntensity;
        float _ColorShift;

        struct Input
        {
            float2 uv_MainTex;
        };

        // Utility functions
        float2 hash2(float2 p)
        {
            return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
        }

        float3 getFluidOffset(float2 uv, float time)
        {
            float2 p = uv * 2.0 - 1.0;
            float2 v = float2(0, 0);
            for (int i = 0; i < 7; i++)
            {
                float t = time * (1.0 - (0.2 * float(i)));
                float2 d = float2(cos(t + i * 2.0), sin(t + i * 2.0));
                v += d * sin(dot(p, float2(cos(t), sin(t))) * 20.0);
            }
            return float3(v * _FluidIntensity, 0);
        }

        float3 rgb2hsv(float3 c)
        {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
        }

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.uv_MainTex = v.texcoord.xy;
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            float2 uv = IN.uv_MainTex;
            float time = _Time.y * 0.1;
            
            // Apply fluid distortion
            float3 fluidOffset = getFluidOffset(uv, time);
            uv += fluidOffset.xy;

            // Sample base color
            float3 color = tex2D(_MainTex, uv).rgb;

            // Apply color shifting
            float3 hsv = rgb2hsv(color);
            hsv.x = frac(hsv.x + _ColorShift * sin(time));
            color = hsv2rgb(hsv);

            // Add some noise
            float2 noise = hash2(uv * 1000.0 + time);
            color += (noise.x - 0.5) * 0.1;

            o.Albedo = color;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}