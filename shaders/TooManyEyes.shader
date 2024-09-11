// poorly adapted from https://www.shadertoy.com/view/Nt2GDd
// thanks to mrange for an open license and the awesome artwork
Shader "Custom/TooManyEyesShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("Scale", Float) = 1.0
        _OffsetX ("Offset X", Float) = 0.0
        _OffsetY ("Offset Y", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert
        #pragma target 5.0

        #include "UnityCG.cginc"

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        float _Scale;
        float _OffsetX;
        float _OffsetY;

        // Constants and definitions
        #define PI 3.141592654
        #define TAU (2.0*PI)
        #define TIME _Time.y
        #define RESOLUTION _ScreenParams
        #define ROT(a) float2x2(cos(a), sin(a), -sin(a), cos(a))
        #define PCOS(x) (0.5+0.5*cos(x))

        #define TOLERANCE 0.00001
        #define MAX_RAY_LENGTH 10.0
        #define MAX_RAY_MARCHES 50
        #define NORM_OFF 0.0001
        #define N(a) normalize(float3(sin(a), -cos(a), 0.0))
        #define SCA(x) float2(sin(x), cos(x))

        static const float3 std_gamma = float3(2.2, 2.2, 2.2);
        static const float smoothing = 0.125*0.25;

        static float g_v = 0.0;

        // Helper functions
        float hash(float2 co)
        {
            return frac(sin(dot(co, float2(12.9898,58.233))) * 13758.5453);
        }

        float tanh_approx(float x)
        {
            float x2 = x*x;
            return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
        }

        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

		float3 postProcess(float3 col, float2 q)
		{
			col = clamp(col, 0.0, 1.0);
			col = pow(col, 1.0/std_gamma);
			col = col*0.6+0.4*col*col*(3.0-2.0*col);
			float gray = dot(col, float3(0.33, 0.33, 0.33));
			col = lerp(col, gray.xxx, -0.4);
			col *= 0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.7);
			return col;
		}

        float pmin(float a, float b, float k)
        {
            float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
            return lerp(b, a, h) - k*h*(1.0-h);
        }

        float pmax(float a, float b, float k)
        {
            return -pmin(-a, -b, k);
        }

        float3 pmin(float3 a, float3 b, float k)
        {
            float3 h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
            return lerp(b, a, h) - k*h*(1.0-h);
        }

        float3 pabs(float3 a, float k)
        {
            return -pmin(a, -a, k);
        }

        float3 refl(float3 p, float3 n)
        {
            p -= n*pmin(0.0, dot(p, n), smoothing)*2.0;
            return p;
        }

        float sphered(float3 ro, float3 rd, float4 sph, float dbuffer)
        {
            float ndbuffer = dbuffer/sph.w;
            float3 rc = (ro - sph.xyz)/sph.w;
            
            float b = dot(rd,rc);
            float c = dot(rc,rc) - 1.0;
            float h = b*b - c;
            if (h < 0.0) return 0.0;
            h = sqrt(h);
            float t1 = -b - h;
            float t2 = -b + h;

            if (t2 < 0.0 || t1 > ndbuffer) return 0.0;
            t1 = max(t1, 0.0);
            t2 = min(t2, ndbuffer);

            float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
            float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
            return (i2-i1)*(3.0/4.0);
        }

        float solidAngle(float3 p, float2 c, float ra)
        {
            float2 q = float2(length(p.xz), p.y);
            
            float l = length(q) - ra;
            float m = length(q - c*clamp(dot(q,c),0.0,ra));
            return max(l,m*sign(c.y*q.x-c.x*q.y));
        }

        float2 mod2(inout float2 p, float2 size)
        {
            float2 c = floor((p + size*0.5)/size);
            p = fmod(p + size*0.5, size) - size*0.5;
            return c;
        }

        // Main distance field function
        float df(float3 p)
        {
            float3 op = p;
            const float zf = 2.0-0.3;
            const float3 n0 = N((PI-acos(1.0/3.0))/2.0);
            const float3 n1 = float3(n0.x, n0.y*cos(2.0*PI/3.0) - n0.z*sin(2.0*PI/3.0), n0.y*sin(2.0*PI/3.0) + n0.z*cos(2.0*PI/3.0));
            const float3 n2 = float3(n0.x, n0.y*cos(-2.0*PI/3.0) - n0.z*sin(-2.0*PI/3.0), n0.y*sin(-2.0*PI/3.0) + n0.z*cos(-2.0*PI/3.0));

            float a = TIME*0.1;
            float2x2 rxy = ROT(a);
            float2x2 ryz = ROT(a*sqrt(0.5));
            float z = 1.0;
            
            float d = 1E6;

            const int mid = 0;
            const int end = 4;
            
            float v = 0.0;

            for (int i = 0; i < mid; ++i)
            {
                p.xy = mul(rxy, p.xy);
                p.yz = mul(ryz, p.yz);
                p = refl(p, n2);
                p = refl(p, n0);
                p = refl(p, n1);
                p.x -= 0.3;
                p *= zf;
                z *= zf;
            }

            float2 sca = SCA(1.3*PI/2.0);

            for (int i = mid; i < end; ++i)
            {
                p.xy = mul(rxy, p.xy);
                p.yz = mul(ryz, p.yz);
                p = -pabs(p, smoothing); 
                p = refl(p, n2);
                p = refl(p, n1);
                p.x -= 0.3;
                p *= zf;
                z *= zf;
                float3 pp = p;
                const float sz = 0.125;
                float2 nn = mod2(pp.yz, float2(sz*3.0, sz*3.0));
                float rr = TAU*hash(nn+float(i));
                float3 eyedir = normalize(float3(1.0, 0.0, 0.0));
                eyedir.xz = mul(ROT(0.5*smoothstep(-0.75, 0.75, sin(rr+TIME))), eyedir.xz);
                eyedir.xy = mul(ROT(0.5*smoothstep(-0.75, 0.75, sin(rr+TIME*sqrt(2.0)))), eyedir.xy);
                float d2 = dot(normalize(pp), eyedir);
                float vv = lerp(PCOS(10.0*TAU*d2-TAU*TIME), 1.0, smoothstep(1.0, 0.66, d2))*smoothstep(0.9, 0.80, d2);
                float dd1 = length(pp) - sz*0.9;
                float dd3 = solidAngle(-pp.zxy, sca, sz*0.9)-sz*0.1;
                float dd = dd1;
                dd = min(dd1, dd3);
                vv = dd == dd3 ? 1.0 : vv;
                dd /= z;
                
                float ddd = pmin(d, dd, 2.0*smoothing/z);
                v = lerp(vv, v, abs(ddd - dd)/abs(d - dd));
                d = ddd;
            }

            g_v = v;

            return d;
        }

        // Ray marching function
        float rayMarch(float3 ro, float3 rd, out int iter)
        {
            float t = 0.0;
            int i = 0;
            for (i = 0; i < MAX_RAY_MARCHES; i++)
            {
                float d = df(ro + rd*t);
                if (d < TOLERANCE || t > MAX_RAY_LENGTH) break;
                t += d;
            }
            iter = i;
            return t;
        }

        // Normal calculation
        float3 normal(float3 pos)
        {
            float2 e = float2(NORM_OFF, 0.0);
            float3 nor;
            nor.x = df(pos+e.xyy) - df(pos-e.xyy);
            nor.y = df(pos+e.yxy) - df(pos-e.yxy);
            nor.z = df(pos+e.yyx) - df(pos-e.yyx);
            return normalize(nor);
        }

        float softShadow(float3 pos, float3 ld, float ll, float mint, float k)
        {
            const float minShadow = 0.25;
            float res = 1.0;
            float t = mint;
            for (int i=0; i<24; i++)
            {
                float d = df(pos + ld*t);
                res = min(res, k*d/t);
                if (ll <= t) break;
                if(res <= minShadow) break;
                t += max(mint*0.2, d);
            }
            return clamp(res, minShadow, 1.0);
        }

        // Rendering function
        float3 render(float3 ro, float3 rd)
        {
            float3 lightPos = float3(1.0, 1.0, 1.0);
            float alpha = 0.05*TIME;
            
            const float3 skyCol = float3(0.0, 0.0, 0.0);

            int iter = 0;
            float t = rayMarch(ro, rd, iter);

            float beat = smoothstep(0.25, 1.0, sin(TAU*TIME*10.0/60.0));
            float sr = lerp(0.45, 0.5, beat);
            float sd = sphered(ro, rd, float4(0.0, 0.0, 0.0, sr), t);

            float3 gcol = sd*lerp(1.5*float3(2.25, 0.75, 0.5), 3.5*float3(2.0, 1.0, 0.75), beat);

            if (t >= MAX_RAY_LENGTH)
            {
                return gcol;
            }

            float3 pos = ro + t*rd;
            float3 nor = normal(pos);
            float3 refl = reflect(rd, nor);
            float ii = float(iter)/float(MAX_RAY_MARCHES);
            float ifade = 1.0-tanh_approx(1.25*ii);
            float h = frac(-1.0*length(pos)+0.1);
            float s = 0.25;
            float v = tanh_approx(0.4/(1.0+40.0*sd));
            float3 color = hsv2rgb(float3(h, s, v));
            color *= g_v;

            float3 lv = lightPos - pos;
            float ll2 = dot(lv, lv);
            float ll = sqrt(ll2);
            float3 ld = lv / ll;
            float sha = softShadow(pos, ld, ll*0.95, 0.01, 10.0);

            float dm = 4.0/ll2;
            float dif = pow(max(dot(nor,ld),0.0),2.0)*dm;  
            float spe = pow(max(dot(refl, ld), 0.0), 20.0);
            float ao = smoothstep(0.5, 0.1, ii);
            float l = lerp(0.2, 1.0, dif*sha*ao);

            float3 col = l*color + 2.0*spe*sha;
            return gcol+col*ifade;
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            float2 uv = IN.uv_MainTex;
            
            // Apply scale and offset
            uv = (uv - 0.5) / _Scale + float2(_OffsetX, _OffsetY) + 0.5;
            
            // Check if the scaled UV is within the [0,1] range
            if (any(uv < 0.0) || any(uv > 1.0))
            {
                // Outside the scaled area, set to a background color or transparent
                o.Albedo = float3(0,0,0); // Or any background color
                o.Alpha = 0; // Set to 0 for transparency, 1 for opaque
                return;
            }

            float2 p = (uv * 2 - 1) * float2(RESOLUTION.x / RESOLUTION.y, 1);

            float3 ro = 1.75*float3(1.0, 0.5, 0.0);
            float rt = TAU*TIME/30.0;
            ro.xy = mul(ROT(sin(rt*sqrt(0.5))*0.5+0.0), ro.xy);
            ro.xz = mul(ROT(sin(rt)*1.0-0.75), ro.xz);
            float3 ta = float3(0.0, 0.0, 0.0);
            float3 ww = normalize(ta - ro);
            float3 uu = normalize(cross(float3(0.0,1.0,0.0), ww));
            float3 vv = normalize(cross(ww,uu));
            float3 rd = normalize(p.x*uu + p.y*vv + 2.5*ww);

            float3 col = render(ro, rd);

            col = postProcess(col, uv);

            o.Albedo = col;
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
