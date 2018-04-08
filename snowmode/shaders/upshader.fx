//---------------------------------------------------------------------
// Include some common stuff
//---------------------------------------------------------------------
#define GENERATE_NORMALS
#include "mta-helper.fx"

float DiffuseColor;

//-----------------------------------------------------------------------
//-- Sampler for the new texture
//-----------------------------------------------------------------------
texture TexMsk;
texture TexMsk2;


sampler MaskSampler = sampler_state
{
    Texture = (TexMsk);
};

sampler MaskSampler2 = sampler_state
{
    Texture = (TexMsk2);
};

sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
};

float3 topVector = float3(0,0,1);
float progress = 1;

//-----------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//-----------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float3 Normal : NORMAL0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//-----------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//-----------------------------------------------------------------------
struct PSInput
{
    float4 Position : POSITION0;
    float4 Diffuse : COLOR0;
    float2 TexCoord : TEXCOORD0;
	float dp : TEXCOORD1;
};

//--------------------------------------------------------------------------------------------
//-- VertexShaderFunction
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//--------------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
	// Make sure normal is valid
    MTAFixUpNormal( VS.Normal );
 
    //-- Calculate screen pos of vertex
    PS.Position = MTACalcScreenPosition ( VS.Position );
 
    //-- Pass through tex coord
    PS.TexCoord = VS.TexCoord;
 
	float3 WorldNormal = MTACalcWorldNormal(VS.Normal);
	
	float dp = dot(topVector,WorldNormal);   
	PS.dp = clamp(4*dp-2.5,0,1) * progress;
	
    //-- Calculate GTA lighting for buildings
    PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
 
    return PS;
}
 
//--------------------------------------------------------------------------------------------
//-- PixelShaderFunction
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//--------------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	float4 texel = tex2D(Sampler0, PS.TexCoord)*PS.Diffuse;
	
	float3 mask = tex2D(MaskSampler, PS.TexCoord)*DiffuseColor;
	//float3 mask2 = tex2D(MaskSampler2, PS.TexCoord)*DiffuseColor;
	
	return float4(lerp(texel,mask,PS.dp), texel.a);
}
 
 
//--------------------------------------------------------------------------------------------
//-- Techniques
//--------------------------------------------------------------------------------------------
technique tec
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
 
//-- Fallback
technique fallback
{
   
}