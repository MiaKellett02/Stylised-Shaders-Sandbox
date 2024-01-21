Shader "MiaShaders/URPTestShader"
{
    Properties
    {
        [MainTexture] _MainTexture ("Main Texture", 2D) = "white" {}
        [MainColor] _DiffuseColour ("Diffuse Colour", color) = (1, 1, 1, 1)

    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct VertexData
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS : POSITION;

                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;
            };

            struct Interpolator
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            //Variables.
            //Everything from here till the functions are needed to define
            //Properties in urp shaders.
            TEXTURE2D(_MainTexture);
            SAMPLER(sampler_MainTexture);
            
            CBUFFER_START(UnityPerMaterial)
                // The following line declares the _BaseMap_ST variable, so that you
                // can use the _BaseMap variable in the fragment shader. The _ST
                // suffix is necessary for the tiling and offset function to work.
                float4 _MainTexture_ST;
                float4 _DiffuseColour;  
            CBUFFER_END


            //Functions
            Interpolator vert(VertexData IN)
            {
                Interpolator OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTexture);

                return OUT;
            }

            float4 frag(Interpolator IN) : SV_Target
            {
                //float dotProd = dot()
                float4 outputColour = _DiffuseColour * SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, IN.uv);
                return outputColour;
            }
            ENDHLSL
        }
    }
}