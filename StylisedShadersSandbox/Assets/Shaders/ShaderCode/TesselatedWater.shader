Shader "MiaShaders/TesselatedWater"
{
    // The properties block of the Unity shader. In this example this block is empty
	// because the output color is predefined in the fragment shader code.
	Properties
	{
		_Tess("Tessellation", Range(1, 32)) = 20
		_MaxTessDistance("Max Tess Distance", Range(1, 64)) = 20
		_ambientLight ("Ambient Light Level", Range(0, 1)) = 0.2
		_NumShades ("Number of Shades", Int) = 3
		_MaxWaveHeight("Max Wave Height", float) = 1
		_MinWaveHeight("Min Wave Height", float) = 0
		_WaterBaseColour ("Water Base Colour", Color) = (0.2, 0.3, 0.8, 1)
		_WavePeakColour ("Wave Peak Colour", Color) = (1, 1, 1, 1)
		_WaveStepEdge ("Wave Step Value", float) = 0.63
		_NormalAnimationSpeed ("Normal Animation Speed", float) = 0.5
		_WaterNormalTex1 ("Water Normal Texture 1", 2D) = "black" {}
		_WaterNormalTex2 ("Water Normal Texture 2", 2D) = "black" {}
	}

	// The SubShader block containing the Shader code. 
	SubShader 
	{
		// SubShader Tags define when and under which conditions a SubShader block or
		// a pass is executed.
		Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

	Pass {
		Tags{ "LightMode" = "UniversalForward" }
        ColorMask RGB

		// The HLSL code block. Unity SRP uses the HLSL language.
		HLSLPROGRAM
		// The Core.hlsl file contains definitions of frequently used HLSL
		// macros and functions, and also contains #include references to other
		// HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		#include "CustomTessellation.hlsl"

        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _ADDITIONAL_LIGHTS
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS

		#pragma require tessellation
		// This line defines the name of the vertex shader. 
		#pragma vertex TessellationVertexProgram
		// This line defines the name of the fragment shader. 
		#pragma fragment frag
		// This line defines the name of the hull shader. 
		#pragma hull hull
		// This line defines the name of the domain shader. 
		#pragma domain domain




		sampler2D _WaterNormalTex1;
		sampler2D _WaterNormalTex2;
		float _ambientLight;
		int _NumShades;
		float _MaxWaveHeight;
		float _MinWaveHeight;
		float _WaveStepEdge;
		float _NormalAnimationSpeed;
		float4 _WavePeakColour;
		float4 _WaterBaseColour;

        
		float3 GetNormalTexBlended(float2 uv){
			float timeMultSpeed = _Time * _NormalAnimationSpeed * 0.01;
			//Get the normal data for the first texture.
			float2 normal1UVModifier = float2(timeMultSpeed, 0);
			float2 normal1UVAccessor = (normal1UVModifier + uv) * 2;
			float4 normal1 = tex2Dlod(_WaterNormalTex1, float4(normal1UVAccessor, 0, 0));
			//Get the normal data for the second texture.
			float2 normal2UVModifier = float2(0, timeMultSpeed);
			float2 normal2UVAccessor = (normal2UVModifier + uv) * 2;
			float4 normal2 = tex2Dlod(_WaterNormalTex2, float4(normal2UVAccessor, 0, 0));
			float3 normalTextureBlended = lerp(normal1, normal2, 0.5);
			return normalTextureBlended;
		}

		// pre tesselation vertex program
		ControlPoint TessellationVertexProgram(Attributes v)
		{
			ControlPoint p;

			p.vertex = v.vertex;
			p.uv = v.uv;
			p.normal = v.normal;
			p.color = v.color;

			return p;
		}

		//returns 1 when wave normal is facing completely up
		float GetWavePeakValue(float3 normalTex){
			return saturate(dot(normalTex, float3(0, 1, 0)));
		}

		float3 GetWorldScale(){
			float3 worldScale = float3(
				length(float3(unity_ObjectToWorld[0].x, unity_ObjectToWorld[1].x, unity_ObjectToWorld[2].x)), // scale x axis
				length(float3(unity_ObjectToWorld[0].y, unity_ObjectToWorld[1].y, unity_ObjectToWorld[2].y)), // scale y axis
				length(float3(unity_ObjectToWorld[0].z, unity_ObjectToWorld[1].z, unity_ObjectToWorld[2].z))  // scale z axis
			);
			return worldScale;
		}

		// after tesselation
		Varyings vert(Attributes input)
		{
			Varyings output;
			//Calculate displacement
			float3 normalTextureBlended = GetNormalTexBlended(input.uv);
			float baseVertDisplacement = GetWavePeakValue(normalTextureBlended);
			float3 waveHighPoint = input.vertex.xyz + ((input.normal) * _MaxWaveHeight);
			waveHighPoint.y = waveHighPoint.y / GetWorldScale().x;
			float3 newVertexPos = lerp(input.vertex.xyz, waveHighPoint, baseVertDisplacement);
			input.vertex.xyz = newVertexPos;

			//Output vertex data.
			output.vertex = TransformObjectToHClip(input.vertex.xyz);
			output.color = input.vertex;
			output.normal = normalTextureBlended;
			output.uv = input.uv;
			return output;
		}

		[UNITY_domain("tri")]
		Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
		{
		Attributes v;

#define DomainPos(fieldName) v.fieldName = \
				patch[0].fieldName * barycentricCoordinates.x + \
				patch[1].fieldName * barycentricCoordinates.y + \
				patch[2].fieldName * barycentricCoordinates.z;

			DomainPos(vertex)
			DomainPos(uv)
			DomainPos(color)
			DomainPos(normal)

			return vert(v);
		}
		

		half4 frag(Varyings IN) : SV_Target
		{
			//Calculate what the colour of the wave should be based on the normal.
			float3 normalTextureBlended = GetNormalTexBlended(IN.uv);
			float wavePeakStrength = step(GetWavePeakValue(normalTextureBlended), _WaveStepEdge);
			float3 waveColour = lerp(_WavePeakColour, _WaterBaseColour, wavePeakStrength); 

            //Calculate Shadow Coords.
            float3 posWS = mul(unity_ObjectToWorld, IN.color);
            float4 posCS = IN.vertex;
            float4 shadowCoord;
            #if SHADOWS_SCREEN
                shadowCoord = ComputeScreenPos(posCS);
            #else
                shadowCoord = TransformWorldToShadowCoord(posWS);
            #endif

			//Apply basic cell shaded phong lighting to the wave.
            Light mainLight = GetMainLight(shadowCoord, posWS, 1);
;			float3 lightDirection = mainLight.direction;
			float dotProd = (dot(lightDirection, normalTextureBlended) + 1) / 2;
            float3 radiance = mainLight.color * mainLight.shadowAttenuation;

			//Apply the cell shading.
            float thresholdInterval = 1 / (float)(_NumShades);
            float cellShadedLight = 0;
            for(int i = _NumShades; i > 0; i--){
				float currentThreshold = thresholdInterval * i;
                if(dotProd > currentThreshold){
					if(currentThreshold > cellShadedLight){
						cellShadedLight = currentThreshold;
                    }
				}
			}


			float diffuseLighting = cellShadedLight;
			float3 ambientLighting = waveColour * _ambientLight;
			//float3 colourWithLighting = diffuseLighting + ambientLighting;
            float3 outputColour = waveColour * (diffuseLighting) + ambientLighting * mainLight.shadowAttenuation;

			//Return the output.
			float4 output = float4(outputColour, 1);
			return output;

			//DEBUG LINES BELOW TO SHOW WHAT THE DOTPRODUCT OF THE NORMAL VS UP IS.
			//float wavePeakVal = GetWavePeakValue(normalTextureBlended);
			//return float4(dotProd, dotProd, dotProd, 1);
		}
			ENDHLSL
		}
		
		//This following pass was taken from the generated code of a shadergraph shader.
        //It is not doing anything for the visuals of the cell shaded material.
        //All this pass does is generate the depth normal information and pass it to the depth normal texture of the camera.
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // -------------------
        // Structs and Packing
        // -------------------
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;

        };

        struct SurfaceDescriptionInputs
        {
        };

        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =  input.normalOS;
            output.ObjectSpaceTangent =  input.tangentOS.xyz;
            output.ObjectSpacePosition = input.positionOS;
        
            return output;
        }

        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
        
            return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        
        ENDHLSL
        }
	}
}
