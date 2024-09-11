// use a lava texture (noise or something else) with wrapping
// kinda looks like flowing lava
// public domain idc
Shader "Custom/LavaEyeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LavaTex ("Lava Texture", 2D) = "white" {}
        _LavaSpeed ("Lava Flow Speed", Float) = 1.0
        _LavaIntensity ("Lava Intensity", Range(0,1)) = 0.5
        _EmissionColor ("Emission Color", Color) = (1,0.5,0,1)
    }
    SubShader
    {
        Tags {"RenderType"="Opaque"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        sampler2D _LavaTex;
        float _LavaSpeed;
        float _LavaIntensity;
        fixed4 _EmissionColor;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_LavaTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Sample the main texture
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            
            // Create flowing lava effect
            float2 lavaUV = IN.uv_LavaTex + _Time.y * _LavaSpeed;
            fixed4 lava = tex2D(_LavaTex, lavaUV);
            
            // Combine main texture with lava
            o.Albedo = lerp(c.rgb, lava.rgb, _LavaIntensity);
            
            // Add emission for glow effect
            o.Emission = _EmissionColor.rgb * lava.r;
            
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
