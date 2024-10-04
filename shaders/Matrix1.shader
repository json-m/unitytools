// matrix rain style effect with illumination and depth
// public domain idc
Shader "_aa/MatrixRainEffectWithDepth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RainColor ("Rain Color", Color) = (0,1,0,1)
        _BackgroundColor ("Background Color", Color) = (0,0,0,1)
        _Speed ("Rain Speed", Float) = 1
        _Density ("Rain Density", Float) = 0.8
        _CharSize ("Character Size", Float) = 0.1
        _Brightness ("Brightness", Range(0, 2)) = 1
        _Illumination ("Illumination", Range(0, 1)) = 0.5
        _DepthFactor ("Depth Factor", Range(0, 1)) = 0.5
        _LayerCount ("Layer Count", Range(1, 10)) = 3
    }
    SubShader
    {
        Tags {"Queue"="Geometry" "RenderType"="Opaque"}
        LOD 200

        CGPROGRAM
        #pragma surface surf Lambert fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        fixed4 _RainColor;
        fixed4 _BackgroundColor;
        float _Speed;
        float _Density;
        float _CharSize;
        float _Brightness;
        float _Illumination;
        float _DepthFactor;
        int _LayerCount;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
        };

        float random(float2 st)
        {
            return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
        }

        float3 layeredRain(float2 uv, float3 viewDir, int layer)
        {
            float layerDepth = (float)layer / _LayerCount;
            float2 offset = viewDir.xy * layerDepth * _DepthFactor;
            float2 uv_offset = uv + offset;

            float rainColumn = floor(uv_offset.x / _CharSize);
            float rainSpeed = _Speed * (random(float2(rainColumn, layer)) + 0.5);
            float rainY = frac(uv_offset.y + _Time.y * rainSpeed * (1 - layerDepth * 0.5));

            float charValue = random(float2(rainColumn, floor(rainY / _CharSize) + layer));
            float char = step(1.0 - _Density * (1 - layerDepth * 0.5), charValue);

            float fade = smoothstep(1.0, 0.0, rainY);
            float finalChar = char * fade;

            float3 layerColor = lerp(_BackgroundColor.rgb, _RainColor.rgb, finalChar);
            return layerColor * (1 - layerDepth * 0.5);
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            float3 finalColor = _BackgroundColor.rgb;
            
            for (int i = 0; i < _LayerCount; i++)
            {
                finalColor = max(finalColor, layeredRain(IN.uv_MainTex, IN.viewDir, i));
            }

            finalColor *= _Brightness;

            o.Albedo = finalColor;
            o.Emission = finalColor * _Illumination;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
