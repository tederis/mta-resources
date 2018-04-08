#include "mta-helper.fx"

//Fog
float fogStart = 0;
float fogEnd = 80;
float4 fogColor = float4(0.5f, 0.5f, 0.5f, 1.0f);
 
//---------------------------------------------------------------------
//-- Sampler for the main texture (needed for pixel shaders)
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};
 
//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
	float3 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
	float4 Position : POSITION0;
	float4 Diffuse  : COLOR0;
	float2 TexCoord : TEXCOORD0;
	float fogFactor : TEXCOORD1;
};

//-----------------------------------------------------------------------------
//-- VertexShaderExample
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//-----------------------------------------------------------------------------
PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    //-- Transform vertex position (You nearly always have to do something like this)
    PS.Position = mul(float4(VS.Position, 1), gWorldViewProjection);
 
    //-- Copy the color and texture coords so the pixel shader can use them
    PS.Diffuse = PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
    PS.TexCoord = VS.TexCoord;
	
	float4 cameraPosition = mul(float4(VS.Position, 1), gWorld);
	cameraPosition = mul(cameraPosition, gView);
	
	PS.fogFactor = saturate((fogEnd - cameraPosition.y) / (fogEnd - fogStart));
 
    return PS;
}
 
 
//-----------------------------------------------------------------------------
//-- PixelShaderExample
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//-----------------------------------------------------------------------------
float4 PixelShaderExample(PSInput PS) : COLOR0
{	
	float4 texel = tex2D(Sampler0, PS.TexCoord);
 
    //-- Apply diffuse lighting
    float4 finalColor = texel * PS.Diffuse;
	finalColor = PS.fogFactor * finalColor + (1.0 - PS.fogFactor) * fogColor;
 
    return finalColor;
}
 
 
//-----------------------------------------------------------------------------
//-- Techniques
//-----------------------------------------------------------------------------
 
//--
//-- MTA will try this technique first:
//--
technique complercated
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}
 
//--
//-- And if the preceding technique will not validate on
//-- the players computer, MTA will try this one:
//--
technique simple
{
  
}