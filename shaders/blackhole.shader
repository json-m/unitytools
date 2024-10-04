// converted poorly from https://www.shadertoy.com/view/lcfyDj
Shader "_aa/blackholeShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frequency ("Noise Frequency", Float) = 1.4
        _Distortion ("Distortion", Float) = 0.01
        _EmissionColor ("Emission Color", Color) = (0.961, 0.592, 0.078, 1)
        _EmissionStrength ("Emission Strength", Float) = 0.4
        _Scale ("Scale", Float) = 1.0
    }
    SubShader
    {
        Tags {"RenderType"="Opaque"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert vertex:vert

        sampler2D _MainTex;
        float _Frequency;
        float _Distortion;
        float4 _EmissionColor;
        float _EmissionStrength;
        float _Scale;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
        };

        // Noise functions
        float4 permute_3d(float4 x) { return fmod(((x * 34.0) + 1.0) * x, 289.0); }
        float4 taylorInvSqrt3d(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

        float simplexNoise3d(float3 v)
        {
            const float2 C = float2(1.0/6.0, 1.0/3.0) ;
            const float4 D = float4(0.0, 0.5, 1.0, 2.0);

            // First corner
            float3 i  = floor(v + dot(v, C.yyy) );
            float3 x0 =   v - i + dot(i, C.xxx) ;

            // Other corners
            float3 g = step(x0.yzx, x0.xyz);
            float3 l = 1.0 - g;
            float3 i1 = min( g.xyz, l.zxy );
            float3 i2 = max( g.xyz, l.zxy );

            float3 x1 = x0 - i1 + C.xxx;
            float3 x2 = x0 - i2 + C.yyy;
            float3 x3 = x0 - D.yyy;

            // Permutations
            i = fmod(i, 289.0 );
            float4 p = permute_3d( permute_3d( permute_3d(
                        i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                      + i.y + float4(0.0, i1.y, i2.y, 1.0 ))
                      + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

            // Gradients
            float n_ = 0.142857142857; // 1.0/7.0
            float3  ns = n_ * D.wyz - D.xzx;

            float4 j = p - 49.0 * floor(p * ns.z * ns.z);

            float4 x_ = floor(j * ns.z);
            float4 y_ = floor(j - 7.0 * x_ );

            float4 x = x_ *ns.x + ns.yyyy;
            float4 y = y_ *ns.x + ns.yyyy;
            float4 h = 1.0 - abs(x) - abs(y);

            float4 b0 = float4( x.xy, y.xy );
            float4 b1 = float4( x.zw, y.zw );

            float4 s0 = floor(b0)*2.0 + 1.0;
            float4 s1 = floor(b1)*2.0 + 1.0;
            float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));

            float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
            float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

            float3 p0 = float3(a0.xy,h.x);
            float3 p1 = float3(a0.zw,h.y);
            float3 p2 = float3(a1.xy,h.z);
            float3 p3 = float3(a1.zw,h.w);

            // Normalise gradients
            float4 norm = taylorInvSqrt3d(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
            p0 *= norm.x;
            p1 *= norm.y;
            p2 *= norm.z;
            p3 *= norm.w;

            // Mix final noise value
            float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
            m = m * m;
            return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1),
                                            dot(p2,x2), dot(p3,x3) ) );
        }

        float fbm3d(float3 x, int it)
        {
            float v = 0.0;
            float a = 0.5;
            float3 shift = float3(100, 100, 100);
            for (int i = 0; i < 32; ++i)
            {
                if (i < it)
                {
                    v += a * simplexNoise3d(x);
                    x = x * 2.0 + shift;
                    a *= 0.5;
                }
            }
            return v;
        }

        float3 rotateZ(float3 v, float angle)
        {
            float sinAngle = sin(angle);
            float cosAngle = cos(angle);
            return float3(
                v.x * cosAngle - v.y * sinAngle,
                v.x * sinAngle + v.y * cosAngle,
                v.z
            );
        }

        float facture(float3 v)
        {
            float3 normalizedVector = normalize(v);
            return max(max(normalizedVector.x, normalizedVector.y), normalizedVector.z);
        }

        void vert(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            float3 viewDir = normalize(IN.viewDir);
            float2 uv = (IN.uv_MainTex * 2.0 - 1.0) / _Scale;

            float3 color = float3(uv.xy, 0.5);
            color = normalize(color);
            color -= 0.2 * float3(0.0, 0.0, _Time.y);

            float angle = -log2(length(uv));
            color = rotateZ(color, angle);

            color.x = fbm3d(color * _Frequency + 0.0, 5) + _Distortion;
            color.y = fbm3d(color * _Frequency + 1.0, 5) + _Distortion;
            color.z = fbm3d(color * _Frequency + 2.0, 5) + _Distortion;
            float3 noiseColor = color;

            noiseColor *= 2.0;
            noiseColor -= 0.1;
            noiseColor *= 0.188;
            noiseColor += float3(uv.xy, 0.0);

            float noiseColorLength = length(noiseColor);
            noiseColorLength = 0.770 - noiseColorLength;
            noiseColorLength *= 4.2;
            noiseColorLength = pow(noiseColorLength, 1.0);

            float3 emissionColor = _EmissionColor.rgb * noiseColorLength * _EmissionStrength;

            float fac = length(uv) - facture(color + 0.32);
            fac += 0.1;
            fac *= 3.0;

            color = lerp(emissionColor, float3(fac, fac, fac), fac + 1.2);

            o.Albedo = color;
            o.Emission = emissionColor;
        }
        ENDCG
    }
    FallBack "Diffuse"
}