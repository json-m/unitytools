// adapted from https://www.shadertoy.com/view/wtlyR8
// original design https://openprocessing.org/sketch/912094
Shader "_aa/circuitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Pattern Scale", Range(0.1, 10.0)) = 1.0
        _Speed ("Animation Speed", Float) = 1.0
        _Threshold ("Pattern Threshold", Range(1, 200)) = 97
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        float _Scale;
        float _Speed;
        float _Threshold;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            float2 fragCoord = IN.uv_MainTex * _ScreenParams.xy * _Scale;
            float iTime = _Time.y * _Speed;
            
            int x = int(fragCoord.x);
            int y = int(fragCoord.y + 30.0 * iTime);
            int r = (x+y)^(x-y);
            
            bool b = abs(r*r*r) % 997 < _Threshold;
            
            float output = b ? 1.0 : 0.0;
            
            o.Albedo = float3(output, output, output);
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
