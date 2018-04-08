#include "mta-helper.fx"

texture Tex0;
texture snowTex;

sampler2D InputTexture : register(s0);

float4x4 lightView;
float4x4 lightProj;

float4 DiffuseColor;
float3 topVector = float3(0,0,1);

//---------------------------------------------------------------------
//-- Sampler for the main texture (needed for pixel shaders)
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};

sampler SamplerSnow = sampler_state
{
    Texture = (snowTex);
};
 
 
//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
	float3 Position : POSITION;
	float3 Normal : NORMAL0;
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
	float4 TexCoord1	: TEXCOORD1;
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
 
	float4 vertex = float4(VS.Position, 1);
 
	PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
	
    PS.TexCoord = VS.TexCoord;
	
	PS.TexCoord1 = mul(vertex, gWorld);
    PS.TexCoord1 = mul(PS.TexCoord1, lightView);
    PS.TexCoord1 = mul(PS.TexCoord1, lightProj);
	
	
	PS.Position = mul(vertex, gWorldViewProjection);
 
    return PS;
}

float LightFalloff = 14.0f;
 
//-----------------------------------------------------------------------------
//-- PixelShaderExample
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//-----------------------------------------------------------------------------
float4 PixelShaderExample(PSInput PS) : COLOR0
{
	float2 TexCoords;
	TexCoords.x = PS.TexCoord1.x/PS.TexCoord1.w/2.0f + 0.5f;
    TexCoords.y = -PS.TexCoord1.y/PS.TexCoord1.w/2.0f + 0.5f;
	
	float4 finalColor = 0;
	
	if((saturate(TexCoords.x) == TexCoords.x) && (saturate(TexCoords.y) == TexCoords.y))
	{
		finalColor = tex2D(Sampler0, TexCoords);
	}
 
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
        VertexShader = compile vs_3_0 VertexShaderExample();
        PixelShader  = compile ps_3_0 PixelShaderExample();
    }
}
 
//--
//-- And if the preceding technique will not validate on
//-- the players computer, MTA will try this one:
//--
technique simple
{
    pass P0
    {
        
    }
}