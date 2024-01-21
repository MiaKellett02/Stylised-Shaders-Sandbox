#ifndef SHADOW_DATA_INCLUDED
#define SHADOW_DATA_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    float GetShadowAttenuation(float3 worldSpacePos){
        float4 positionCS = TransformWorldToHClip(worldSpacePos);
        float4 shadowCoord;        
        #if SHADOWS_SCREEN
            shadowCoord = ComputeScreenPos(positionCS);
        #else
            #ifndef SHADERGRAPH_PREVIEW
                shadowCoord = TransformWorldToShadowCoord(worldSpacePos);
            #else
                shadowCoord = 1.0;
            #endif
        #endif
        
        Light mainLight = GetMainLight(shadowCoord, worldSpacePos, 1);
        float shadowAttenuation = mainLight.shadowAttenuation;
        return shadowAttenuation;
    }



    void GetShadowAttenuation_float(float3 worldSpacePos, out float shadowAttenuation) {
    #ifndef SHADERGRAPH_PREVIEW
        shadowAttenuation = GetShadowAttenuation(worldSpacePos);
    #endif
    }
#endif