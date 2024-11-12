// UltimateStressTest_v2.shader
Shader "_aa/UltimateStressTest_v2"
{
Properties
    {
        // Base properties
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _MinDistance ("Minimum Distance", Float) = 0
        _MaxDistance ("Maximum Distance", Float) = 5

        // Tessellation properties
        [Header(Tessellation Controls)]
        _TessellationFactor ("Base Tessellation", Range(1, 64)) = 16
        _TessellationPower ("Tessellation Ramp Power", Range(0.1, 10)) = 1
        _TessMinDist ("Tessellation Start Distance", Float) = 5
        _TessMaxDist ("Tessellation End Distance", Float) = 25
        _TessRampOffset ("Tessellation Ramp Offset", Range(0, 1)) = 0.2
        
        // Force Field properties
        [Header(Force Field Effects)]
        [HDR] _EnergyColor ("Energy Color", Color) = (0.5, 1.0, 1.0, 1.0)
        _NoiseScale ("Noise Scale", Range(1, 100)) = 50
        _NoiseSpeed ("Noise Speed", Range(0, 2)) = 0.5
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.1
        _PatternScale ("Pattern Scale", Range(1, 50)) = 10
        _PulseSpeed ("Pulse Speed", Range(0, 5)) = 1
        _EdgeSharpness ("Edge Sharpness", Range(1, 10)) = 5
        _Transparency ("Transparency", Range(0, 1)) = 0.5

        // Core stress properties
        [Header(Core Stress Parameters)]
        _StressLevel ("Overall Stress Level", Range(1, 10)) = 5
        _ComputeIntensity ("Compute Intensity", Range(0, 1)) = 1
        _MemoryIntensity ("Memory Intensity", Range(0, 1)) = 1
        
        // Texture stress properties
        [Header(Texture Stress)]
        _NoiseTex1 ("Noise Texture 1", 2D) = "gray" {}
        _NoiseTex2 ("Noise Texture 2", 2D) = "gray" {}
        _NoiseTex3 ("Noise Texture 3", 2D) = "gray" {}
        _NoiseTex4 ("Noise Texture 4", 2D) = "gray" {}
        _TextureScale ("Texture Scale", Range(0.1, 10)) = 1
        
        [Header(Branch Computation)]
        _BranchComplexity ("Branch Complexity", Range(1, 100)) = 50
        _BranchThreshold ("Branch Threshold", Range(0, 1)) = 0.5
        _MathIterations ("Math Iterations", Range(1, 200)) = 100
        _FractalDepth ("Fractal Depth", Range(1, 20)) = 10
        
        [Header(Additional Stress Parameters)]
        _DerivativeStress ("Derivative Stress", Range(0, 1)) = 0.5
        _CacheStress ("Cache Stress", Range(0, 1)) = 0.5
        _ThreadStress ("Thread Divergence", Range(0, 1)) = 0.5
        _TextureStress ("Texture Unit Stress", Range(0, 1)) = 0.5
    }

SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "Queue" = "Transparent+100"
            "IgnoreProjector" = "True"
        }
        LOD 100

        // Pass 1: Main effect pass
        Pass
        {
            ZWrite On
            ZTest Always
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex tessvert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "StressUtils.cginc"
            #include "StressCore.cginc"

            ENDCG
        }

        // Add GrabPass before force field
        GrabPass { "_BackgroundTexture" }

        // Pass 2: Force field boundary visualization
        Pass
        {
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex tessvert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment fragForceField
            
            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "StressUtils.cginc"
            #include "StressForceField.cginc"
            
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}
